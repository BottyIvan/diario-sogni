import AVFoundation
import Flutter
import UIKit
import UniformTypeIdentifiers

/// Native operations use the application container and the user-selected folder only.
public final class DreamPlatform: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
    private let worker = DispatchQueue(label: "it.diariosogni.files", qos: .utility)
    private let audioWorker = DispatchQueue(label: "it.diariosogni.audio", qos: .userInitiated)
    private var pickerResult: FlutterResult?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let bookmarkKey = "dreamArchiveBookmark"
    private let labelKey = "dreamArchiveLabel"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = DreamPlatform()
        let archive = FlutterMethodChannel(name: "it.diariosogni/archive", binaryMessenger: registrar.messenger())
        let background = FlutterMethodChannel(name: "it.diariosogni/background", binaryMessenger: registrar.messenger())
        archive.setMethodCallHandler { call, result in instance.handleArchive(call, result: result) }
        background.setMethodCallHandler { call, result in instance.handleBackground(call, result: result) }
    }

    private func handleBackground(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startTranscription":
            if backgroundTask == .invalid {
                backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Trascrizione locale") { [weak self] in
                    self?.endBackgroundTask()
                }
            }
            // Foreground transcription remains available even when iOS denies extra time.
            result(nil)
        case "stopTranscription":
            endBackgroundTask()
            result(nil)
        case "convertAudio":
            guard let args = call.arguments as? [String: Any],
                  let input = args["input"] as? String, let output = args["output"] as? String else {
                result(FlutterError(code: "AUDIO_PATH", message: "Percorso audio non disponibile", details: nil))
                return
            }
            audioWorker.async {
                do {
                    let destination = try Self.convert(input: input, output: output)
                    DispatchQueue.main.async { result(destination) }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "AUDIO_CONVERSION", message: "Formato audio non supportato o conversione non riuscita", details: nil))
                    }
                }
            }
        default: result(FlutterMethodNotImplemented)
        }
    }

    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        let task = backgroundTask
        backgroundTask = .invalid
        UIApplication.shared.endBackgroundTask(task)
    }

    private static func containerURL(_ path: String) throws -> URL {
        let root = URL(fileURLWithPath: NSHomeDirectory()).resolvingSymlinksInPath().path + "/"
        let url = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
        guard url.path.hasPrefix(root) else { throw NativeError.invalidPath }
        return url
    }

    /// AVFoundation streams AAC/PCM input into mono signed 16-bit, 16 kHz WAV.
    static func convert(input: String, output: String) throws -> String {
        let source = try containerURL(input)
        let destination = try containerURL(output)
        guard source != destination else { throw NativeError.invalidPath }
        var complete = false
        defer { if !complete { try? FileManager.default.removeItem(at: destination) } }
        let reader = try AVAudioFile(forReading: source)
        guard reader.length > 0,
              let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true),
              let converter = AVAudioConverter(from: reader.processingFormat, to: format) else {
            throw NativeError.unsupportedAudio
        }
        let writer = try AVAudioFile(forWriting: destination, settings: format.settings,
                                     commonFormat: .pcmFormatInt16, interleaved: true)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8192) else {
            throw NativeError.unsupportedAudio
        }
        var readError: Error?
        var written: AVAudioFramePosition = 0
        var lastProgress = Date()
        while true {
            var conversionError: NSError?
            let status = converter.convert(to: buffer, error: &conversionError) { requested, state in
                let remaining = reader.length - reader.framePosition
                if remaining <= 0 { state.pointee = .endOfStream; return nil }
                let frames = AVAudioFrameCount(min(remaining, AVAudioFramePosition(max(1, requested))))
                guard let chunk = AVAudioPCMBuffer(pcmFormat: reader.processingFormat, frameCapacity: frames) else {
                    readError = NativeError.unsupportedAudio
                    state.pointee = .noDataNow
                    return nil
                }
                do {
                    try reader.read(into: chunk, frameCount: frames)
                    state.pointee = chunk.frameLength == 0 ? .endOfStream : .haveData
                    return chunk.frameLength == 0 ? nil : chunk
                } catch {
                    readError = error
                    state.pointee = .noDataNow
                    return nil
                }
            }
            if let error = readError { throw error }
            if let error = conversionError { throw error }
            if buffer.frameLength > 0 {
                try writer.write(from: buffer)
                written += AVAudioFramePosition(buffer.frameLength)
                lastProgress = Date()
            }
            if status == .endOfStream { break }
            if status == .error || Date().timeIntervalSince(lastProgress) > 30 {
                throw NativeError.unsupportedAudio
            }
        }
        guard written > 0 else { throw NativeError.unsupportedAudio }
        complete = true
        return destination.path
    }

    private func handleArchive(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "choose" {
            guard pickerResult == nil, let presenter = Self.presenter() else {
                result(FlutterError(code: "ARCHIVE_PICKER", message: "Selezione cartella non disponibile", details: nil))
                return
            }
            pickerResult = result
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
            picker.delegate = self
            picker.allowsMultipleSelection = false
            presenter.present(picker, animated: true)
            return
        }
        if call.method == "disconnect" {
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
            UserDefaults.standard.removeObject(forKey: labelKey)
            result(nil)
            return
        }
        worker.async {
            do {
                let value: Any?
                switch call.method {
                case "restore":
                    // Restore preferences without contacting a cloud provider.
                    // Access and permissions are checked during an explicit sync.
                    if UserDefaults.standard.data(forKey: self.bookmarkKey) == nil { value = nil }
                    else { value = UserDefaults.standard.string(forKey: self.labelKey) ?? "Cartella condivisa" }
                case "list":
                    value = try self.withArchive { folder in
                        try Self.coordinate(folder, writing: false) { location in
                            try FileManager.default.contentsOfDirectory(at: location, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey])
                                .filter { Self.validName($0.lastPathComponent) && (try? $0.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])).map { $0.isRegularFile == true && $0.isSymbolicLink != true } == true }
                                .map { $0.lastPathComponent }
                        }
                    }
                case "read", "write", "remove":
                    guard let args = call.arguments as? [String: Any], let name = args["name"] as? String,
                          Self.validName(name) else { throw NativeError.invalidPath }
                    value = try self.withArchive { folder in
                        let file = folder.appendingPathComponent(name, isDirectory: false)
                        if (try? file.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true {
                            throw NativeError.invalidPath
                        }
                        switch call.method {
                        case "read":
                            return try Self.coordinate(file, writing: false) { location -> Any? in
                                let size = try location.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                                guard size <= 100 * 1024 * 1024 else { throw NativeError.tooLarge }
                                return FlutterStandardTypedData(bytes: try Data(contentsOf: location))
                            }
                        case "write":
                            guard let bytes = args["bytes"] as? FlutterStandardTypedData,
                                  bytes.data.count <= 100 * 1024 * 1024 else { throw NativeError.tooLarge }
                            return try Self.coordinate(file, writing: true) { location -> Any? in
                                try bytes.data.write(to: location, options: .atomic)
                                return nil
                            }
                        default:
                            return try Self.coordinate(file, writing: true) { location -> Any? in
                                if FileManager.default.fileExists(atPath: location.path) { try FileManager.default.removeItem(at: location) }
                                return nil
                            }
                        }
                    }
                default:
                    DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
                    return
                }
                DispatchQueue.main.async { result(value) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "ARCHIVE_IO", message: "Cartella non disponibile. Verifica il servizio nell’app File o collega nuovamente la cartella.", details: nil))
                }
            }
        }
    }

    private func withArchive<T>(_ operation: (URL) throws -> T) throws -> T {
        guard let bookmark = UserDefaults.standard.data(forKey: bookmarkKey) else { throw NativeError.noFolder }
        var stale = false
        let selected = try URL(resolvingBookmarkData: bookmark, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &stale)
        let scoped = selected.startAccessingSecurityScopedResource()
        defer { if scoped { selected.stopAccessingSecurityScopedResource() } }
        if stale {
            UserDefaults.standard.set(try selected.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil), forKey: bookmarkKey)
        }
        let folder = try Self.archiveFolder(selected)
        return try operation(folder)
    }

    private static func archiveFolder(_ selected: URL) throws -> URL {
        if selected.lastPathComponent == "Diario dei sogni" || FileManager.default.fileExists(atPath: selected.appendingPathComponent("diario-sogni-archive.json").path) {
            return selected
        }
        let folder = selected.appendingPathComponent("Diario dei sogni", isDirectory: true)
        if (try? folder.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true { throw NativeError.invalidPath }
        try coordinate(folder, writing: true) { location in
            try FileManager.default.createDirectory(at: location, withIntermediateDirectories: false)
        }
        return folder
    }

    private static func coordinate<T>(_ url: URL, writing: Bool, _ operation: (URL) throws -> T) throws -> T {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var outcome: Result<T, Error>?
        if writing {
            coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { location in
                outcome = Result { try operation(location) }
            }
        } else {
            coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { location in
                outcome = Result { try operation(location) }
            }
        }
        if let error = coordinationError { throw error }
        guard let result = outcome else { throw NativeError.noFolder }
        return try result.get()
    }

    private static func validName(_ name: String) -> Bool {
        name.range(of: "^[a-zA-Z0-9_.-]{1,200}$", options: .regularExpression) != nil && !name.contains("..")
    }

    private static func presenter() -> UIViewController? {
        var controller = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }.flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
        while let presented = controller?.presentedViewController { controller = presented }
        return controller
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        let result = pickerResult
        pickerResult = nil
        result?(nil)
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selected = urls.first, let result = pickerResult else { return }
        pickerResult = nil
        worker.async {
            let scoped = selected.startAccessingSecurityScopedResource()
            defer { if scoped { selected.stopAccessingSecurityScopedResource() } }
            do {
                let folder = try Self.archiveFolder(selected)
                let data = try selected.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(data, forKey: self.bookmarkKey)
                UserDefaults.standard.set(folder.lastPathComponent, forKey: self.labelKey)
                DispatchQueue.main.async { result(folder.lastPathComponent) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "ARCHIVE_PICKER", message: "Il servizio non consente l’accesso a questa cartella", details: nil))
                }
            }
        }
    }

    private enum NativeError: Error { case invalidPath, unsupportedAudio, noFolder, tooLarge }
}
