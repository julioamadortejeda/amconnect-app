import AVFoundation
import Flutter

// Handles mic capture + PCM playback through a single AVAudioEngine so that
// the OS voice-processing unit (enabled via .voiceChat mode) has access to
// both the speaker reference and the mic signal — giving proper echo
// cancellation without any client-side muting tricks.
class VoiceAudioManager: NSObject, FlutterStreamHandler {

    static let shared = VoiceAudioManager()

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var inputConverter: AVAudioConverter?
    private var lastInputFormat: AVAudioFormat?
    private var eventSink: FlutterEventSink?
    
    // Serial queue and accumulator to prevent flooding the Flutter Platform Channel
    private let audioQueue = DispatchQueue(label: "com.amconnect.audio")
    private var captureAccumulator = Data()

    // Tracks how many PCM buffers are currently scheduled but not yet played.
    // Used by isPlaybackDone so Flutter knows when the speaker has fully drained
    // before re-enabling the mic (half-duplex echo prevention).
    private let bufferQueue = DispatchQueue(label: "com.amconnect.buffer")
    private var buffersInFlight: Int = 0

    /// True when no audio buffers are waiting to be played.
    var isPlaybackDone: Bool {
        bufferQueue.sync { buffersInFlight == 0 }
    }

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
            do { try start(); completion(nil) } catch { completion(error) }
        case .undetermined:
            session.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        do { try self.start(); completion(nil) } catch { completion(error) }
                    } else {
                        completion(NSError(domain: "VoiceAudio", code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"]))
                    }
                }
            }
        case .denied:
            completion(NSError(domain: "VoiceAudio", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied. Enable in Settings → AmConnect → Microphone."]))
        @unknown default:
            do { try start(); completion(nil) } catch { completion(error) }
        }
    }

    func start() throws {
        if engine != nil {
            print("[VoiceAudio] Warning: Engine already exists. Tearing down first.")
            stop()
        }

        // Fail fast if mic is explicitly denied
        let perm = AVAudioSession.sharedInstance().recordPermission
        print("[VoiceAudio] Mic permission: \(perm == .granted ? "granted" : perm == .denied ? "DENIED" : "undetermined")")
        guard perm != .denied else {
            throw NSError(domain: "VoiceAudio", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied. Go to Settings → AmConnect → Microphone."])
        }

        print("[VoiceAudio] Starting audio session...")
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat,
                                    options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            print("[VoiceAudio] AVAudioSession active (.voiceChat).")

            let eng = AVAudioEngine()
            let inputNode = eng.inputNode

            // Playback: player → mainMixerNode → speakers
            let player = AVAudioPlayerNode()
            let playFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                        sampleRate: 24_000, channels: 1, interleaved: false)!
            eng.attach(player)
            eng.connect(player, to: eng.mainMixerNode, format: playFmt)

            // Connect inputNode → micMixer → mainMixerNode BEFORE starting the engine.
            // Without a downstream connection the inputNode format stays "0 Hz" and the
            // hardware is never initialized. outputVolume = 0.001 (-60 dB, inaudible) is
            // critical: 0.0 tells the render thread to skip this path entirely, so the
            // tap never fires. Any non-zero value keeps the graph active.
            let micMixer = AVAudioMixerNode()
            eng.attach(micMixer)
            eng.connect(inputNode, to: micMixer, format: nil)
            eng.connect(micMixer, to: eng.mainMixerNode, format: nil)
            micMixer.outputVolume = 0.001

            print("[VoiceAudio] Starting AVAudioEngine...")
            try eng.start()
            player.play()
            print("[VoiceAudio] Engine started, player armed.")

            // Read the format AFTER the engine starts — now the hardware is active.
            let inputFmt = inputNode.outputFormat(forBus: 0)
            print("[VoiceAudio] Input format: \(inputFmt)")

            let capFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                       sampleRate: 16_000, channels: 1, interleaved: false)!

            inputNode.installTap(onBus: 0, bufferSize: 4_096, format: inputFmt) { [weak self] buf, _ in
                print("[VoiceAudio] TAP \(buf.frameLength)f")
                self?.handleCapture(buf, targetFmt: capFmt)
            }
            print("[VoiceAudio] Tap installed.")

            engine = eng
            playerNode = player
        } catch {
            print("[VoiceAudio] ERROR in start(): \(error.localizedDescription)")
            throw error
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

        bufferQueue.async { self.buffersInFlight += 1 }
        player.scheduleBuffer(buf) { [weak self] in
            // Fires when this buffer slot is released — either played or canceled (stop).
            self?.bufferQueue.async { self?.buffersInFlight -= 1 }
        }
    }

    /// Stop audio playback immediately (barge-in / interrupt).
    /// Cancels all scheduled buffers; their completion handlers fire and decrement
    /// buffersInFlight, so isPlaybackDone returns true once they all drain.
    func stopPlayback() {
        playerNode?.stop()
        playerNode?.play() // re-arm for next audio
    }

    /// Tear down the engine at session end.
    func stop() {
        print("[VoiceAudio] Stopping and tearing down audio engine...")
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
        bufferQueue.async { [weak self] in
            self?.buffersInFlight = 0
        }
        
        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation)
        print("[VoiceAudio] Audio engine stopped and resources released.")
    }

    // MARK: - Private

    private func handleCapture(_ buffer: AVAudioPCMBuffer, targetFmt: AVAudioFormat) {
        // Lazily create or recreate the converter if the format changes
        if inputConverter == nil || lastInputFormat != buffer.format {
            print("[VoiceAudio] Creating converter from \(buffer.format) to \(targetFmt)")
            inputConverter = AVAudioConverter(from: buffer.format, to: targetFmt)
            if inputConverter == nil {
                print("[VoiceAudio] ERROR: Failed to create AVAudioConverter.")
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
            print("[VoiceAudio] AVAudioConverter conversion status/error: \(error.localizedDescription)")
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
