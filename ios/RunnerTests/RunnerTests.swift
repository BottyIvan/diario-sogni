import AVFoundation
import Darwin
import XCTest
@testable import DreamNative

final class RunnerTests: XCTestCase {
    func testWhisperSymbolSurvivesStaticLinking() {
        let handle = dlopen(nil, RTLD_NOW)
        XCTAssertNotNil(handle)
        XCTAssertNotNil(dlsym(handle, "request"), "Dart FFI must be able to find request()")
        if let handle = handle { dlclose(handle) }
    }

    func testConversionRejectsPathsOutsideApplicationContainer() {
        XCTAssertThrowsError(try DreamPlatform.convert(input: "/tmp/foreign.wav", output: NSTemporaryDirectory() + "probe.wav"))
    }

    func testStereoPCMBecomesMono16kHzWave() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = directory.appendingPathComponent("synthetic.wav")
        let output = directory.appendingPathComponent("converted.wav")
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2))
        let pcm = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 48000))
        pcm.frameLength = 48000
        let samples = try XCTUnwrap(pcm.floatChannelData)
        for index in 0..<48000 {
            let value = Float(sin(Double(index) * 2 * .pi * 440 / 48000) * 0.2)
            samples[0][index] = value
            samples[1][index] = value
        }
        do {
            let writer = try AVAudioFile(forWriting: input, settings: format.settings)
            try writer.write(from: pcm)
        }
        XCTAssertEqual(try DreamPlatform.convert(input: input.path, output: output.path), output.path)
        let reader = try AVAudioFile(forReading: output)
        XCTAssertEqual(reader.fileFormat.sampleRate, 16000)
        XCTAssertEqual(reader.fileFormat.channelCount, 1)
        XCTAssertEqual(reader.fileFormat.commonFormat, .pcmFormatInt16)
        XCTAssertEqual(Double(reader.length), 16000, accuracy: 2)
        let bytes = try Data(contentsOf: output)
        XCTAssertEqual(String(data: bytes.prefix(4), encoding: .ascii), "RIFF")
        XCTAssertEqual(String(data: bytes[8..<12], encoding: .ascii), "WAVE")
    }
}
