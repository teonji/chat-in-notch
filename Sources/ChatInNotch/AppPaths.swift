import Foundation

enum AppPaths {
    /// The app's data folder (~/Library/Application Support/ChatInNotch).
    static let support: URL = {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("ChatInNotch", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
}
