package com.jacatsoft.amconnect

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioFocusRequest
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

// Contraparte Android de ios/Runner/AudioManager.swift — mismo contrato:
//  MethodChannel  com.amconnect/audio       → startAudio / playPcm / stopPlayback / stopAudio
//                                            y de vuelta invoca "playbackFinished" al drenar.
//  EventChannel   com.amconnect/audio_input → chunks Uint8List de PCM16 LE mono @16 kHz,
//                                            1600 bytes (50 ms) por evento, igual que iOS.
// Captura con AudioSource.VOICE_COMMUNICATION (AEC/NS del sistema) + AcousticEchoCanceler
// explícito si el dispositivo lo expone. Reproducción PCM16 mono @24 kHz por bocina
// (USAGE_MEDIA — equivalente al .defaultToSpeaker de iOS).
class MainActivity : FlutterActivity() {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var controlChannel: MethodChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var pendingStartResult: MethodChannel.Result? = null

    // Captura
    private var audioRecord: AudioRecord? = null
    private var captureThread: Thread? = null
    @Volatile private var capturing = false
    private var echoCanceler: AcousticEchoCanceler? = null

    // Reproducción
    private var audioTrack: AudioTrack? = null
    private var playbackThread: Thread? = null
    private val playbackQueue = LinkedBlockingQueue<ByteArray>()
    @Volatile private var playing = false
    // Se incrementa en stopPlayback (barge-in) para descartar el aviso de drenado
    // de audio que ya fue cancelado.
    @Volatile private var playbackGeneration = 0

    // Ruteo de comunicación (audífonos BT, cableados, bocina) — espejo de la
    // Fase HFP de iOS: sin MODE_IN_COMMUNICATION + setCommunicationDevice el
    // mic de un headset Bluetooth jamás se activa (SCO no levanta).
    private val audioManager by lazy { getSystemService(AUDIO_SERVICE) as AudioManager }
    private var focusRequest: AudioFocusRequest? = null
    private var deviceCallback: AudioDeviceCallback? = null
    // Selección manual del usuario desde el selector de salida (API 31+: id
    // de AudioDeviceInfo). null = ruteo automático por prioridad.
    @Volatile private var userSelectedDeviceId: Int? = null
    @Volatile private var communicationAudioActive = false

    companion object {
        private const val MIC_PERMISSION_REQUEST = 7212
        private const val CAPTURE_SAMPLE_RATE = 16_000
        private const val PLAYBACK_SAMPLE_RATE = 24_000
        private const val CHUNK_BYTES = 1_600 // 50 ms de PCM16 mono @16 kHz — mismo tamaño que iOS
        private const val TAG = "VoiceAudio"
        // Pseudo-id para "bocina forzada" en el camino legacy (<API 31)
        private const val SPEAKER_PSEUDO_ID = -1
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        EventChannel(messenger, "com.amconnect/audio_input").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink) {
                    eventSink = sink
                }

                override fun onCancel(args: Any?) {
                    eventSink = null
                }
            },
        )

        controlChannel = MethodChannel(messenger, "com.amconnect/audio").also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "startAudio" -> startAudioRequestingPermission(result)
                    "playPcm" -> {
                        val b64 = call.argument<String>("data")
                        if (b64 == null) {
                            result.error("BAD_ARGS", "Expected {data: base64}", null)
                        } else {
                            playbackQueue.offer(Base64.decode(b64, Base64.DEFAULT))
                            result.success(null)
                        }
                    }
                    "stopPlayback" -> {
                        stopPlayback()
                        result.success(null)
                    }
                    "stopAudio" -> {
                        stopAudio()
                        result.success(null)
                    }
                    "getAudioDevices" -> result.success(listAudioDevices())
                    "selectAudioDevice" -> {
                        selectAudioDevice(call.argument<String>("id"))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    // ── Permiso + arranque ───────────────────────────────────────────────────

    private fun startAudioRequestingPermission(result: MethodChannel.Result) {
        val needed = mutableListOf<String>()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            needed.add(Manifest.permission.RECORD_AUDIO)
        }
        // Runtime desde API 31; sin él, setCommunicationDevice sobre un headset
        // BT falla en silencio en varios OEMs. Si el usuario lo niega seguimos
        // sin BT (solo bocina/mic del teléfono) — no es bloqueante.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            needed.add(Manifest.permission.BLUETOOTH_CONNECT)
        }
        if (needed.isEmpty()) {
            startEngine(result)
            return
        }
        if (pendingStartResult != null) {
            result.error("AUDIO_START_ERROR", "Microphone permission request already in progress", null)
            return
        }
        pendingStartResult = result
        ActivityCompat.requestPermissions(this, needed.toTypedArray(), MIC_PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != MIC_PERMISSION_REQUEST) return
        val result = pendingStartResult ?: return
        pendingStartResult = null
        val micGranted = permissions.indices.any {
            permissions[it] == Manifest.permission.RECORD_AUDIO &&
                grantResults[it] == PackageManager.PERMISSION_GRANTED
        } || ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
        if (micGranted) {
            startEngine(result)
        } else {
            result.error("MIC_PERMISSION_DENIED", "Microphone permission denied", null)
        }
    }

    private fun startEngine(result: MethodChannel.Result) {
        try {
            stopAudio() // idempotente: teardown previo si quedó algo (igual que iOS)
            setupCommunicationAudio() // ANTES de crear record/track: fija modo y ruta
            startPlayback()
            startCapture()
            result.success(null)
        } catch (e: Exception) {
            stopAudio()
            result.error("AUDIO_START_ERROR", e.message ?: "Could not start audio engine", null)
        }
    }

    // ── Ruteo de comunicación (BT/cableado/bocina) ───────────────────────────

    private fun setupCommunicationAudio() {
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build(),
                )
                .build()
            audioManager.requestAudioFocus(req)
            focusRequest = req
        }
        communicationAudioActive = true
        applyPreferredRoute()
        val cb = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(added: Array<out AudioDeviceInfo>) = applyPreferredRoute()
            override fun onAudioDevicesRemoved(removed: Array<out AudioDeviceInfo>) {
                // Si se fue el dispositivo elegido a mano, volver a automático
                userSelectedDeviceId?.let { sel ->
                    if (removed.any { it.id == sel }) userSelectedDeviceId = null
                }
                applyPreferredRoute()
            }
        }
        audioManager.registerAudioDeviceCallback(cb, mainHandler)
        deviceCallback = cb
    }

    // Prioridad: selección manual del usuario → headset BT (LE > SCO) →
    // cableado/USB → bocina. En MODE_IN_COMMUNICATION el default del sistema
    // es el auricular de llamadas, inservible para un asistente de voz — por
    // eso la bocina se selecciona explícitamente como último recurso.
    private fun applyPreferredRoute() {
        if (!communicationAudioActive) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val devices = audioManager.availableCommunicationDevices
            val chosen = userSelectedDeviceId?.let { sel -> devices.find { it.id == sel } }
                ?: devices.find { it.type == AudioDeviceInfo.TYPE_BLE_HEADSET }
                ?: devices.find { it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO }
                ?: devices.find {
                    it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                        it.type == AudioDeviceInfo.TYPE_USB_HEADSET
                }
                ?: devices.find { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
            if (chosen != null) {
                val ok = audioManager.setCommunicationDevice(chosen)
                Log.i(TAG, "setCommunicationDevice(type=${chosen.type}, ${chosen.productName}) → $ok")
            }
        } else {
            @Suppress("DEPRECATION")
            val hasBt = audioManager.isBluetoothScoAvailableOffCall &&
                audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                    .any { it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO }
            @Suppress("DEPRECATION")
            if (hasBt && userSelectedDeviceId != SPEAKER_PSEUDO_ID) {
                audioManager.startBluetoothSco()
                audioManager.isBluetoothScoOn = true
                audioManager.isSpeakerphoneOn = false
            } else {
                audioManager.stopBluetoothSco()
                audioManager.isBluetoothScoOn = false
                audioManager.isSpeakerphoneOn = true
            }
        }
    }

    private fun teardownCommunicationAudio() {
        if (!communicationAudioActive) return
        communicationAudioActive = false
        userSelectedDeviceId = null
        deviceCallback?.let { audioManager.unregisterAudioDeviceCallback(it) }
        deviceCallback = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            audioManager.clearCommunicationDevice()
        } else {
            @Suppress("DEPRECATION")
            audioManager.stopBluetoothSco()
            @Suppress("DEPRECATION")
            audioManager.isBluetoothScoOn = false
            @Suppress("DEPRECATION")
            audioManager.isSpeakerphoneOn = false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        }
        focusRequest = null
        audioManager.mode = AudioManager.MODE_NORMAL
    }

    // ── Selector de salida (contrato compartido con iOS) ─────────────────────
    //  getAudioDevices → [{id, name, type: speaker|bluetooth|wired|other, selected}]
    //  selectAudioDevice(id) — "speaker"/"bluetooth" como pseudo-ids en <31.

    private fun listAudioDevices(): List<Map<String, Any>> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val current = audioManager.communicationDevice
            return audioManager.availableCommunicationDevices
                // El auricular de llamadas no aplica para el asistente de voz
                .filter { it.type != AudioDeviceInfo.TYPE_BUILTIN_EARPIECE }
                .map {
                    mapOf(
                        "id" to it.id.toString(),
                        "name" to it.productName.toString(),
                        "type" to deviceTypeLabel(it.type),
                        "selected" to (current?.id == it.id),
                    )
                }
        }
        @Suppress("DEPRECATION")
        val btOn = audioManager.isBluetoothScoOn
        val list = mutableListOf<Map<String, Any>>(
            mapOf("id" to "speaker", "name" to "", "type" to "speaker", "selected" to !btOn),
        )
        if (audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                .any { it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO }
        ) {
            list.add(mapOf("id" to "bluetooth", "name" to "", "type" to "bluetooth", "selected" to btOn))
        }
        return list
    }

    private fun deviceTypeLabel(type: Int): String = when (type) {
        AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "speaker"
        AudioDeviceInfo.TYPE_BLUETOOTH_SCO, AudioDeviceInfo.TYPE_BLE_HEADSET -> "bluetooth"
        AudioDeviceInfo.TYPE_WIRED_HEADSET, AudioDeviceInfo.TYPE_USB_HEADSET -> "wired"
        else -> "other"
    }

    private fun selectAudioDevice(id: String?) {
        if (id == null) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            userSelectedDeviceId = id.toIntOrNull()
        } else {
            userSelectedDeviceId = if (id == "speaker") SPEAKER_PSEUDO_ID else null
        }
        applyPreferredRoute()
    }

    // ── Captura (mic → EventChannel) ─────────────────────────────────────────

    private fun startCapture() {
        val minBuf = AudioRecord.getMinBufferSize(
            CAPTURE_SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT,
        )
        if (minBuf <= 0) throw IllegalStateException("AudioRecord: 16 kHz mono PCM16 not supported (minBuf=$minBuf)")

        val record = AudioRecord(
            MediaRecorder.AudioSource.VOICE_COMMUNICATION,
            CAPTURE_SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            maxOf(minBuf * 2, CHUNK_BYTES * 4),
        )
        if (record.state != AudioRecord.STATE_INITIALIZED) {
            record.release()
            throw IllegalStateException("AudioRecord failed to initialize")
        }
        if (AcousticEchoCanceler.isAvailable()) {
            echoCanceler = AcousticEchoCanceler.create(record.audioSessionId)?.apply { enabled = true }
        }
        record.startRecording()
        audioRecord = record
        capturing = true

        captureThread = Thread({
            val buf = ByteArray(CHUNK_BYTES)
            var filled = 0
            while (capturing) {
                val n = record.read(buf, filled, CHUNK_BYTES - filled)
                if (n <= 0) continue
                filled += n
                if (filled == CHUNK_BYTES) {
                    val chunk = buf.copyOf()
                    mainHandler.post { eventSink?.success(chunk) }
                    filled = 0
                }
            }
        }, "amconnect-mic").also { it.start() }
    }

    // ── Reproducción (playPcm → AudioTrack) ──────────────────────────────────

    private fun startPlayback() {
        val minBuf = AudioTrack.getMinBufferSize(
            PLAYBACK_SAMPLE_RATE, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT,
        )
        val track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    // VOICE_COMMUNICATION (no MEDIA): mantiene la reproducción
                    // en la ruta de comunicación (SCO del headset BT) y alinea
                    // el AEC del sistema con la captura.
                    .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build(),
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(PLAYBACK_SAMPLE_RATE)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .build(),
            )
            .setBufferSizeInBytes(maxOf(minBuf * 2, 9_600)) // ≥200 ms
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()
        track.play()
        audioTrack = track
        playing = true
        playbackQueue.clear()

        playbackThread = Thread({
            var wroteSinceDrain = false
            while (playing) {
                val chunk = playbackQueue.poll(100, TimeUnit.MILLISECONDS)
                if (chunk == null) {
                    // Cola vacía tras haber escrito audio → dar margen a que el buffer
                    // interno (~200 ms) suene y avisar a Dart, como el completionHandler
                    // del scheduleBuffer en iOS.
                    if (wroteSinceDrain && playbackQueue.isEmpty()) {
                        wroteSinceDrain = false
                        val gen = playbackGeneration
                        Thread.sleep(200)
                        if (playing && gen == playbackGeneration && playbackQueue.isEmpty()) {
                            mainHandler.post {
                                if (gen == playbackGeneration) {
                                    controlChannel?.invokeMethod("playbackFinished", null)
                                }
                            }
                        }
                    }
                    continue
                }
                val gen = playbackGeneration
                val t = audioTrack ?: continue
                var off = 0
                while (playing && gen == playbackGeneration && off < chunk.size) {
                    val n = t.write(chunk, off, chunk.size - off)
                    if (n < 0) break
                    off += n
                }
                if (gen == playbackGeneration) wroteSinceDrain = true
            }
        }, "amconnect-playback").also { it.start() }
    }

    /// Corta la reproducción al instante (barge-in) y deja el track armado.
    private fun stopPlayback() {
        playbackGeneration++
        playbackQueue.clear()
        audioTrack?.let {
            try {
                it.pause()
                it.flush()
                it.play()
            } catch (_: Exception) {
            }
        }
    }

    // ── Teardown ─────────────────────────────────────────────────────────────

    private fun stopAudio() {
        capturing = false
        playing = false
        playbackGeneration++
        playbackQueue.clear()

        captureThread?.join(500)
        captureThread = null
        playbackThread?.join(500)
        playbackThread = null

        echoCanceler?.release()
        echoCanceler = null

        audioRecord?.let {
            try { it.stop() } catch (_: Exception) {}
            it.release()
        }
        audioRecord = null

        audioTrack?.let {
            try { it.pause(); it.flush(); it.stop() } catch (_: Exception) {}
            it.release()
        }
        audioTrack = null

        teardownCommunicationAudio()
    }

    override fun onDestroy() {
        stopAudio()
        super.onDestroy()
    }
}
