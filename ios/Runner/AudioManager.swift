import AVFoundation
import Flutter

// Handles mic capture + PCM playback through a single AVAudioEngine. The OS
// voice-processing unit (enabled by the AVAudioSession .voiceChat mode) has
// access to both the speaker reference and the mic signal, giving proper echo
// cancellation. Full-duplex barge-in is achieved on the Dart side by never
// muting the mic — the .voiceChat AEC keeps the model's voice out of the
// capture, so the user can interrupt while the model is speaking.
//
// NOTE: we deliberately do NOT call inputNode.setVoiceProcessingEnabled(true).
// That separate AUVoiceProcessing API reconfigures the input node's I/O graph
// and conflicts with the manual inputNode → micMixer → mainMixer routing below,
// which stops the input tap from ever firing. .voiceChat mode already provides
// the echo cancellation we need.
class VoiceAudioManager: NSObject, FlutterStreamHandler {

    static let shared = VoiceAudioManager()

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var inputConverter: AVAudioConverter?
    private var lastInputFormat: AVAudioFormat?
    // Captura del mic en rutas Bluetooth — el tap del inputNode de
    // AVAudioEngine nunca dispara con BT (ver buildAndStartEngine).
    private var captureSession: AVCaptureSession?
    private var captureDelegate: MicCaptureDelegate?
    // Selector de salida: el usuario forzó la bocina aunque haya headset.
    // Se resetea al iniciar cada sesión de voz.
    private var forcedSpeaker = false
    // Debounce de reinicios por cambio de ruta: al levantar SCO (HFP) iOS
    // dispara varias AVAudioEngineConfigurationChange seguidas.
    private var restartWorkItem: DispatchWorkItem?
    private var eventSink: FlutterEventSink?
    var onPlaybackFinished: (() -> Void)?
    // Diagnóstico: reenvía los logs nativos a Dart vía MethodChannel —
    // print() de Swift NO llega a la consola de `flutter run` en dispositivo
    // físico, solo a Xcode/Console.app.
    var onLog: ((String) -> Void)?
    private var tapBuffersDelivered = 0
    private var activeBufferCount = 0

    private func log(_ msg: String) {
        print("[VoiceAudio] \(msg)")
        onLog?(msg)
    }
    
    // Serial queue and accumulator to prevent flooding the Flutter Platform Channel
    private let audioQueue = DispatchQueue(label: "com.amconnect.audio")
    private var captureAccumulator = Data()

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?,
                  eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    // MARK: - Lifecycle

    // Entry point from AppDelegate — requests mic permission if needed, then calls start().
    func startRequestingPermissionIfNeeded(completion: @escaping (Error?) -> Void) {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.start()
                    DispatchQueue.main.async { completion(nil) }
                } catch {
                    DispatchQueue.main.async { completion(error) }
                }
            }
        case .undetermined:
            session.requestRecordPermission { granted in
                if granted {
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            try self.start()
                            DispatchQueue.main.async { completion(nil) }
                        } catch {
                            DispatchQueue.main.async { completion(error) }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(NSError(domain: "VoiceAudio", code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"]))
                    }
                }
            }
        case .denied:
            completion(NSError(domain: "VoiceAudio", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied. Enable in Settings → AmConnect → Microphone."]))
        @unknown default:
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.start()
                    DispatchQueue.main.async { completion(nil) }
                } catch {
                    DispatchQueue.main.async { completion(error) }
                }
            }
        }
    }

    func start() throws {
        if engine != nil {
            log("Warning: Engine already exists. Tearing down first.")
            stop()
        }
        forcedSpeaker = false // cada sesión arranca en ruteo automático

        // Fail fast if mic is explicitly denied
        let perm = AVAudioSession.sharedInstance().recordPermission
        log("Mic permission: \(perm == .granted ? "granted" : perm == .denied ? "DENIED" : "undetermined")")
        guard perm != .denied else {
            throw NSError(domain: "VoiceAudio", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied. Go to Settings → AmConnect → Microphone."])
        }

        log("Starting audio session...")
        do {
            let session = AVAudioSession.sharedInstance()
            // HFP (.allowBluetooth), NOT A2DP: HFP is the only BT profile with a
            // microphone, so with a headset both mic AND output live there — the
            // same combo WebRTC/LiveKit use (.playAndRecord + .voiceChat + HFP).
            // A2DP has no mic channel, and .defaultToSpeaker beats Bluetooth
            // routing in .playAndRecord (BT doesn't count as "headphones" for
            // its exception) — speaker-by-default is done with the override
            // in applySpeakerOverrideIfNeeded instead. HFP route changes (SCO
            // coming up 1-3s after activation, headset connect/disconnect)
            // stop the engine; the AVAudioEngineConfigurationChange observer
            // rebuilds ONLY the engine graph — never the session — and
            // re-reads the new input format (HFP runs at 8/16 kHz).
            try session.setCategory(.playAndRecord, mode: .voiceChat,
                                    options: [.allowBluetooth])
            // Suelta cualquier entrada forzada de antes — el dictado fija el
            // mic integrado (ver useBuiltInMic) y esa preferencia sobrevive a
            // la sesión. Sin esto, dictar una vez dejaba a la voz Live hablando
            // por el headset pero oyendo por el micrófono del teléfono.
            try session.setPreferredInput(nil)
            try session.setActive(true)
            try applySpeakerOverrideIfNeeded(session)
            try buildAndStartEngine()
        } catch {
            log("ERROR in start(): \(error.localizedDescription)")
            throw error
        }
    }

    // Speaker by default ONLY when no external output is present. With a
    // BT/wired headset the route is left untouched so audio and mic stay on
    // the headset. Re-evaluated on every engine (re)build.
    private func applySpeakerOverrideIfNeeded(_ session: AVAudioSession) throws {
        if forcedSpeaker {
            try session.overrideOutputAudioPort(.speaker)
            log("Session route check. forcedSpeaker=true → speaker.")
            return
        }
        let externalPorts: [AVAudioSession.Port] = [
            .bluetoothHFP, .bluetoothA2DP, .bluetoothLE,
            .headphones, .usbAudio, .carAudio,
        ]
        let hasExternalOutput = session.currentRoute.outputs
            .contains { externalPorts.contains($0.portType) }
        try session.overrideOutputAudioPort(hasExternalOutput ? .none : .speaker)
        log("Session route check. externalOutput=\(hasExternalOutput). Route: \(session.currentRoute)")
    }

    // ── Selector de salida (contrato compartido con Android) ─────────────────
    //  getAudioDevices → [{id, name, type: speaker|bluetooth|wired|other, selected}]
    //  selectAudioDevice(id) — "speaker" es un pseudo-id; el resto son UIDs de
    //  availableInputs. Cambiar la ruta dispara AVAudioEngineConfigurationChange
    //  y el rebuild re-decide el camino de captura (tap vs AVCaptureSession).

    func getAudioDevices() -> [[String: Any]] {
        let session = AVAudioSession.sharedInstance()
        let outputTypes = session.currentRoute.outputs.map { $0.portType }
        let onSpeaker = outputTypes.contains(.builtInSpeaker)
        var devices: [[String: Any]] = [
            ["id": "speaker", "name": "", "type": "speaker", "selected": onSpeaker],
        ]
        for input in session.availableInputs ?? [] {
            switch input.portType {
            case .bluetoothHFP, .bluetoothLE:
                devices.append([
                    "id": input.uid, "name": input.portName, "type": "bluetooth",
                    "selected": !onSpeaker &&
                        (outputTypes.contains(.bluetoothHFP) || outputTypes.contains(.bluetoothLE)),
                ])
            case .headsetMic:
                devices.append([
                    "id": input.uid, "name": input.portName, "type": "wired",
                    "selected": !onSpeaker && outputTypes.contains(.headphones),
                ])
            default:
                break
            }
        }
        return devices
    }

    /// Fuerza la entrada al micrófono integrado. Para el dictado
    /// (`speech_to_text`), y hay que llamarlo ANTES de `listen()`.
    ///
    /// Ese plugin captura con `inputNode.installTap` de `AVAudioEngine`, que es
    /// exactamente lo que **nunca entrega buffers en rutas Bluetooth** en iOS
    /// — la misma limitación que ya obligó a capturar con `AVCaptureSession`
    /// en la voz Live (ver `buildAndStartEngine`, Apple Forums #819555). No es
    /// cuestión de A2DP vs HFP: ni con una ruta HFP perfecta dispara el tap.
    /// Como el plugin no expone forma de cambiar su captura, la única salida es
    /// que la entrada ya sea el mic integrado cuando instala el tap.
    ///
    /// El orden importa: el plugin fija la categoría, instala el tap y arranca
    /// su engine, todo dentro de `listen()`. Cambiar la ruta después deja el
    /// tap con un formato que ya no corresponde y la captura muere igual.
    ///
    /// NO se desactiva la sesión aquí: hacerlo tira el enlace SCO y dispara el
    /// bucle de cambios de ruta documentado en `rebuildEngineAfterRouteChange`.
    func useBuiltInMic() {
        let session = AVAudioSession.sharedInstance()
        guard let builtin = session.availableInputs?
            .first(where: { $0.portType == .builtInMic }) else {
            log("useBuiltInMic: no built-in mic in availableInputs.")
            return
        }
        do {
            // `setPreferredInput` falla si la categoría activa no admite
            // entrada (.ambient, .playback). Al llamarse antes de `listen()`
            // la sesión bien puede estar en una de ésas, así que primero se
            // deja en una que grabe. El plugin la vuelve a fijar enseguida con
            // las suyas; la preferencia de entrada sobrevive porque el puerto
            // integrado sigue disponible.
            if session.category != .playAndRecord && session.category != .record {
                try session.setCategory(.playAndRecord, mode: .default,
                                        options: [.defaultToSpeaker, .allowBluetoothA2DP])
            }
            try session.setPreferredInput(builtin)
            log("useBuiltInMic. Route now: \(session.currentRoute)")
        } catch {
            log("ERROR useBuiltInMic: \(error.localizedDescription)")
        }
    }

    func selectAudioDevice(_ id: String) {
        let session = AVAudioSession.sharedInstance()
        do {
            if id == "speaker" {
                forcedSpeaker = true
                if let builtin = session.availableInputs?
                    .first(where: { $0.portType == .builtInMic }) {
                    try session.setPreferredInput(builtin)
                }
                try session.overrideOutputAudioPort(.speaker)
            } else {
                forcedSpeaker = false
                if let port = session.availableInputs?.first(where: { $0.uid == id }) {
                    try session.setPreferredInput(port)
                }
                try session.overrideOutputAudioPort(.none)
            }
            log("selectAudioDevice(\(id)). Route now: \(session.currentRoute)")
        } catch {
            log("ERROR selectAudioDevice(\(id)): \(error.localizedDescription)")
        }
    }

    // Builds the engine graph on whatever route the (already active) session
    // has right now. Separate from start() so route-change rebuilds don't
    // touch the AVAudioSession: deactivating it tears down the BT SCO link,
    // which retriggers a configuration change — an infinite restart loop where
    // the tap never fires.
    private func buildAndStartEngine() throws {
        // En rutas Bluetooth el tap del inputNode de AVAudioEngine NUNCA
        // entrega buffers aunque la ruta y el formato se vean válidos
        // (probado en device 2026-07-17 con soundcore Space Q45: ruta HFP
        // correcta, formato 16 kHz, tap instalado, cero callbacks — mismo
        // síntoma documentado en Apple Forums #819555). El mic BT se captura
        // con AVCaptureSession, cuyo delegate sí dispara con BT; el engine
        // queda solo para reproducción. En ruta de mic integrado se conserva
        // el grafo probado (micMixer 0.001 + tap con formato post-start).
        let session = AVAudioSession.sharedInstance()
        let btInput = session.currentRoute.inputs.contains {
            $0.portType == .bluetoothHFP || $0.portType == .bluetoothLE
        }

        let eng = AVAudioEngine()

        // Playback: player → mainMixerNode → salida activa (bocina o headset)
        let player = AVAudioPlayerNode()
        let playFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                    sampleRate: 24_000, channels: 1, interleaved: false)!
        eng.attach(player)
        eng.connect(player, to: eng.mainMixerNode, format: playFmt)

        if !btInput {
            let inputNode = eng.inputNode
            // Connect inputNode → micMixer → mainMixerNode BEFORE starting the engine.
            // Without a downstream connection the inputNode format stays "0 Hz" and the
            // hardware is never initialized. outputVolume = 0.001 (-60 dB, inaudible) is
            // critical: 0.0 tells the render thread to skip this path entirely, so the
            // tap never fires. Any non-zero value keeps the graph active. (Proven on the
            // feature/voice branch — do not lower below 0.001.)
            let micMixer = AVAudioMixerNode()
            eng.attach(micMixer)
            eng.connect(inputNode, to: micMixer, format: nil)
            eng.connect(micMixer, to: eng.mainMixerNode, format: nil)
            micMixer.outputVolume = 0.001
        }

        log("Starting AVAudioEngine... (btInput=\(btInput))")
        try eng.start()
        player.play()
        log("Engine started, player armed.")

        tapBuffersDelivered = 0

        if !btInput {
            let inputNode = eng.inputNode
            // Read the format AFTER the engine starts — now the hardware is active and
            // reports its real format. Installing the tap with this exact format (not nil)
            // is what makes the tap callback fire reliably (proven on the feature/voice branch).
            let inputFmt = inputNode.outputFormat(forBus: 0)
            log("Input format: \(inputFmt)")

            let capFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                       sampleRate: 16_000, channels: 1, interleaved: false)!

            inputNode.installTap(onBus: 0, bufferSize: 4_096, format: inputFmt) { [weak self] buf, _ in
                guard let self = self else { return }
                self.tapBuffersDelivered += 1
                if self.tapBuffersDelivered == 1 {
                    self.log("TAP first buffer: \(buf.frameLength)f @ \(buf.format.sampleRate) Hz")
                }
                self.handleCapture(buf, targetFmt: capFmt)
            }
            log("Tap installed.")
        }

        engine = eng
        playerNode = player

        // iOS stops the engine (without error) when the audio route changes
        // mid-session — e.g. headphones connect/disconnect. Without this
        // observer both capture and playback die silently.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEngineConfigurationChange),
            name: .AVAudioEngineConfigurationChange,
            object: eng)

        if btInput {
            try startBtCaptureSession()
        }
    }

    // Captura del mic Bluetooth. AVCaptureSession NO debe reconfigurar la
    // AVAudioSession (ya está activa en .voiceChat/HFP) — si la toca, tira
    // la ruta SCO.
    private func startBtCaptureSession() throws {
        let cap = AVCaptureSession()
        cap.automaticallyConfiguresApplicationAudioSession = false
        guard let device = AVCaptureDevice.default(for: .audio) else {
            throw NSError(domain: "VoiceAudio", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "No audio capture device available"])
        }
        let input = try AVCaptureDeviceInput(device: device)
        cap.beginConfiguration()
        guard cap.canAddInput(input) else {
            cap.commitConfiguration()
            throw NSError(domain: "VoiceAudio", code: -4,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot add mic input to capture session"])
        }
        cap.addInput(input)
        let output = AVCaptureAudioDataOutput()
        let delegate = MicCaptureDelegate { [weak self] sampleBuffer in
            self?.handleCaptureSampleBuffer(sampleBuffer)
        }
        output.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "com.amconnect.btcapture"))
        guard cap.canAddOutput(output) else {
            cap.commitConfiguration()
            throw NSError(domain: "VoiceAudio", code: -5,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot add audio output to capture session"])
        }
        cap.addOutput(output)
        cap.commitConfiguration()
        captureDelegate = delegate
        captureSession = cap
        // startRunning bloquea — nunca llamarlo en main.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            cap.startRunning()
            self?.log("AVCaptureSession running (BT mic).")
        }
    }

    // CMSampleBuffer → AVAudioPCMBuffer y de ahí al mismo pipeline de
    // conversión a 16 kHz Int16 que usa el tap del engine.
    private func handleCaptureSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let fmtDesc = CMSampleBufferGetFormatDescription(sampleBuffer),
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmtDesc) else { return }
        let frames = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        guard frames > 0,
              let format = AVAudioFormat(streamDescription: asbd),
              let pcm = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        pcm.frameLength = frames
        let status = CMSampleBufferCopyPCMDataIntoAudioBufferList(
            sampleBuffer, at: 0, frameCount: Int32(frames), into: pcm.mutableAudioBufferList)
        guard status == noErr else { return }
        tapBuffersDelivered += 1
        if tapBuffersDelivered == 1 {
            log("BT capture first buffer: \(frames)f @ \(format.sampleRate) Hz")
        }
        let capFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: 16_000, channels: 1, interleaved: false)!
        handleCapture(pcm, targetFmt: capFmt)
    }

    // Debounced: while SCO (HFP) comes up iOS fires several configuration
    // changes in a row — rebuilding on each one re-kills the tap before it
    // ever delivers a buffer. Only the last notification wins.
    @objc private func handleEngineConfigurationChange(_ note: Notification) {
        guard engine != nil else { return } // deliberate stop() — nothing to do
        log("Engine configuration change (route changed) — scheduling rebuild...")
        restartWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.rebuildEngineAfterRouteChange() }
        restartWorkItem = work
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    // Tears down and rebuilds ONLY the engine graph. The AVAudioSession stays
    // active and configured — deactivating it would drop the BT SCO link and
    // retrigger the configuration change (infinite restart loop).
    private func rebuildEngineAfterRouteChange() {
        guard engine != nil else { return }
        log("Rebuilding engine after route change (session kept active)...")
        NotificationCenter.default.removeObserver(
            self, name: .AVAudioEngineConfigurationChange, object: nil)
        captureSession?.stopRunning()
        captureSession = nil
        captureDelegate = nil
        engine?.inputNode.removeTap(onBus: 0)
        playerNode?.stop()
        engine?.stop()
        engine = nil
        playerNode = nil
        inputConverter = nil
        lastInputFormat = nil
        audioQueue.async { [weak self] in self?.captureAccumulator.removeAll() }
        do {
            try applySpeakerOverrideIfNeeded(AVAudioSession.sharedInstance())
            try buildAndStartEngine()
            log("Engine rebuilt after route change.")
        } catch {
            log("ERROR rebuilding after route change: \(error.localizedDescription)")
        }
    }

    /// Feed a chunk of raw 16-bit PCM from Gemini (24 kHz mono LE) for playback.
    func playPcm(_ data: Data) {
        guard let player = playerNode, let eng = engine, eng.isRunning else { return }

        let frameCount = data.count / 2
        guard frameCount > 0 else { return }

        let fmt = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                sampleRate: 24_000, channels: 1, interleaved: false)!
        guard let buf = AVAudioPCMBuffer(pcmFormat: fmt,
                                         frameCapacity: AVAudioFrameCount(frameCount)) else { return }
        buf.frameLength = AVAudioFrameCount(frameCount)

        guard let floatPtr = buf.floatChannelData?[0] else { return }
        data.withUnsafeBytes { raw in
            guard let src = raw.bindMemory(to: Int16.self).baseAddress else { return }
            for i in 0..<frameCount { floatPtr[i] = Float(src[i]) / 32_768.0 }
        }

        audioQueue.async { [weak self] in
            self?.activeBufferCount += 1
        }

        player.scheduleBuffer(buf, completionHandler: { [weak self] in
            guard let self = self else { return }
            self.audioQueue.async {
                if self.activeBufferCount > 0 {
                    self.activeBufferCount -= 1
                    if self.activeBufferCount == 0 {
                        self.onPlaybackFinished?()
                    }
                }
            }
        })
    }

    /// Stop audio playback immediately (barge-in / interrupt).
    /// Cancels all scheduled buffers so the model's voice cuts off the instant the
    /// user barges in (full-duplex: the mic never stopped, so Gemini already heard it).
    func stopPlayback() {
        audioQueue.async { [weak self] in
            self?.activeBufferCount = 0
        }
        playerNode?.stop()
        playerNode?.play() // re-arm for next audio
    }

    /// Tear down the engine at session end.
    func stop() {
        log("Stopping and tearing down audio engine...")
        restartWorkItem?.cancel()
        restartWorkItem = nil
        NotificationCenter.default.removeObserver(
            self, name: .AVAudioEngineConfigurationChange, object: nil)
        captureSession?.stopRunning()
        captureSession = nil
        captureDelegate = nil
        engine?.inputNode.removeTap(onBus: 0)
        playerNode?.stop()
        engine?.stop()
        engine = nil
        playerNode = nil
        inputConverter = nil
        lastInputFormat = nil

        // Clear accumulator on stop
        audioQueue.async { [weak self] in
            self?.captureAccumulator.removeAll()
        }

        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation)
        log("Audio engine stopped and resources released.")
    }

    // MARK: - Private

    private func handleCapture(_ buffer: AVAudioPCMBuffer, targetFmt: AVAudioFormat) {
        // Lazily create or recreate the converter if the format changes
        if inputConverter == nil || lastInputFormat != buffer.format {
            log("Creating converter from \(buffer.format) to \(targetFmt)")
            inputConverter = AVAudioConverter(from: buffer.format, to: targetFmt)
            if inputConverter == nil {
                log("ERROR: Failed to create AVAudioConverter.")
            }
            lastInputFormat = buffer.format
        }
        
        guard let converter = inputConverter else { return }

        let capacity = AVAudioFrameCount(
            ceil(Double(buffer.frameLength) * targetFmt.sampleRate / buffer.format.sampleRate)
        )
        guard capacity > 0,
              let out = AVAudioPCMBuffer(pcmFormat: targetFmt, frameCapacity: capacity) else { return }

        var inputDone = false
        var err: NSError?
        converter.convert(to: out, error: &err) { _, status in
            if inputDone { status.pointee = .noDataNow; return nil }
            inputDone = true
            status.pointee = .haveData
            return buffer
        }

        if let error = err {
            // Note: Ran dry is normal/non-fatal, but good to print if there are other errors
            log("AVAudioConverter conversion status/error: \(error.localizedDescription)")
        }

        // We ignore `err` if we successfully produced Float32 frames
        guard out.frameLength > 0, let floatPtr = out.floatChannelData?[0] else { return }

        // Manually convert Float32 [-1.0, 1.0] samples to Int16 [-32768, 32767]
        let frameCount = Int(out.frameLength)
        var int16Samples = [Int16](repeating: 0, count: frameCount)
        for i in 0..<frameCount {
            let sample = floatPtr[i]
            let scaled = sample * 32767.0
            if scaled > 32767.0 {
                int16Samples[i] = 32767
            } else if scaled < -32768.0 {
                int16Samples[i] = -32768
            } else {
                int16Samples[i] = Int16(scaled)
            }
        }
        
        let bytes = Data(bytes: int16Samples, count: frameCount * 2)
        
        // Process on our serial queue to avoid blocking high-priority audio threads
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureAccumulator.append(bytes)

            // 50ms of 16kHz 16-bit mono PCM is 1600 bytes (800 samples * 2 bytes)
            let chunkSize = 1600
            while self.captureAccumulator.count >= chunkSize {
                let chunk = self.captureAccumulator.prefix(chunkSize)
                self.captureAccumulator.removeFirst(chunkSize)

                // Dispatch aggregated chunk to the main thread for Flutter
                DispatchQueue.main.async {
                    self.eventSink?(FlutterStandardTypedData(bytes: chunk))
                }
            }
        }
    }
}

// Delegate del AVCaptureSession para el mic Bluetooth — el tap del inputNode
// de AVAudioEngine no dispara en rutas BT; este callback sí (Apple Forums
// #819555).
private final class MicCaptureDelegate: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    private let onBuffer: (CMSampleBuffer) -> Void

    init(onBuffer: @escaping (CMSampleBuffer) -> Void) {
        self.onBuffer = onBuffer
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        onBuffer(sampleBuffer)
    }
}
