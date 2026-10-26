import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Attached images are resized and copied locally, next to the conversations.
enum ImageStorage {
    private static let maxPixelSize = 1280
    private static let cache = NSCache<NSString, NSImage>()

    static let directory: URL = {
        let dir = AppPaths.support.appendingPathComponent("Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static func url(_ name: String) -> URL { directory.appendingPathComponent(name) }

    /// Saves an image's data (any readable format) as a resized JPEG. Returns the file name.
    static func ingest(data: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return write(source)
    }

    private static func write(_ source: CGImageSource) -> String? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let name = UUID().uuidString + ".jpg"
        guard let dest = CGImageDestinationCreateWithURL(url(name) as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
        else { return nil }
        CGImageDestinationAddImage(dest, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        return CGImageDestinationFinalize(dest) ? name : nil
    }

    /// Saves an already decoded image (e.g. a generated one) without resizing it.
    static func ingest(cgImage: CGImage) -> String? {
        let name = UUID().uuidString + ".jpg"
        guard let dest = CGImageDestinationCreateWithURL(url(name) as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
        else { return nil }
        CGImageDestinationAddImage(dest, cgImage, [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary)
        return CGImageDestinationFinalize(dest) ? name : nil
    }

    static func ingest(fileURL: URL) -> String? {
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else { return nil }
        return write(source)
    }

    static func remove(_ names: [String]) {
        for name in names {
            cache.removeObject(forKey: name as NSString)
            try? FileManager.default.removeItem(at: url(name))
        }
    }

    static func image(_ name: String) -> NSImage? {
        if let cached = cache.object(forKey: name as NSString) { return cached }
        guard let image = NSImage(contentsOf: url(name)) else { return nil }
        cache.setObject(image, forKey: name as NSString)
        return image
    }
}
