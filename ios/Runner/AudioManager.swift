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
    private var eventSink: FlutterEventSink?

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

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        // Enhance options to ensure AEC is prioritized
        try session.setCategory(.playAndRecord, mode: .voiceChat,
                                options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        let eng = AVAudioEngine()
        
        // Enable Hardware Acoustic Echo Cancellation (AEC)
        if #available(iOS 13.0, *) {
            try eng.inputNode.setVoiceProcessingEnabled(true)
        }

        let player = AVAudioPlayerNode()

        // Playback path: 24 kHz mono Float32 (we convert from Int16 on feed)
        let playFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                    sampleRate: 24_000, channels: 1, interleaved: false)!
        eng.attach(player)
        eng.connect(player, to: eng.mainMixerNode, format: playFmt)

        // Capture path: hardware format → convert to 16 kHz Int16 for Gemini
        let inputNode = eng.inputNode
        let hwFmt = inputNode.inputFormat(forBus: 0)
        let capFmt = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                   sampleRate: 16_000, channels: 1, interleaved: true)!
        guard let conv = AVAudioConverter(from: hwFmt, to: capFmt) else {
            throw NSError(domain: "VoiceAudio", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot create input converter"])
        }
        inputConverter = conv

        inputNode.installTap(onBus: 0, bufferSize: 4_096, format: hwFmt) { [weak self] buf, _ in
            self?.handleCapture(buf, converter: conv, targetFmt: capFmt)
        }

        try eng.start()
        player.play()

        engine = eng
        playerNode = player
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

        player.scheduleBuffer(buf)
    }

    /// Stop audio playback immediately (barge-in / interrupt).
    func stopPlayback() {
        playerNode?.stop()
        playerNode?.play() // re-arm for next audio
    }

    /// Tear down the engine at session end.
    func stop() {
        engine?.inputNode.removeTap(onBus: 0)
        playerNode?.stop()
        engine?.stop()
        engine = nil
        playerNode = nil
        inputConverter = nil
        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Private

    private func handleCapture(_ buffer: AVAudioPCMBuffer,
                                converter: AVAudioConverter,
                                targetFmt: AVAudioFormat) {
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

        // We ignore `err` if we successfully produced frames (err might be "ran dry" which is normal)
        guard out.frameLength > 0, let int16Ptr = out.int16ChannelData?[0] else { return }
        
        let bytes = Data(bytes: int16Ptr, count: Int(out.frameLength) * 2)
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(FlutterStandardTypedData(bytes: bytes))
        }
    }
}
