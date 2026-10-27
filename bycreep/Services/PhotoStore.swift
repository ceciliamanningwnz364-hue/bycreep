import SwiftUI
import UIKit
import ImageIO

// MARK: - Disk + memory photo store

final class PhotoStore: @unchecked Sendable {
    static let shared = PhotoStore()

    private let cache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(
        label: "com.bycreep.photos",
        qos: .userInitiated,
        attributes: .concurrent
    )
    private let directory: URL

    private init() {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        directory = base.appendingPathComponent("ProgressPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        cache.countLimit = 36
        cache.totalCostLimit = 64 * 1024 * 1024
    }

    // MARK: Saving

    /// Downsamples, re-encodes and writes the image. Returns a stable file name.
    func save(data: Data, id: UUID = UUID()) async throws -> String {
        let fileName = "\(id.uuidString).jpg"
        let destination = directory.appendingPathComponent(fileName)

        let jpeg: Data = await withCheckedContinuation { continuation in
            queue.async {
                let resized = Self.downsample(data: data, maxPixel: 2400)
                let encoded = resized?.jpegData(compressionQuality: 0.84) ?? data
                continuation.resume(returning: encoded)
            }
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                do {
                    try jpeg.write(to: destination, options: [.atomic])
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        return fileName
    }

    // MARK: Loading

    func image(fileName: String, maxPixel: CGFloat) async -> UIImage? {
        let key = "\(fileName)-\(Int(maxPixel))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        return await withCheckedContinuation { continuation in
            queue.async {
                let url = self.directory.appendingPathComponent(fileName)
                let image = Self.downsample(url: url, maxPixel: maxPixel)
                if let image {
                    let cost = Int(image.size.width * image.size.height * 4)
                    self.cache.setObject(image, forKey: key, cost: cost)
                }
                continuation.resume(returning: image)
            }
        }
    }

    func preview(from data: Data, maxPixel: CGFloat = 1400) async -> UIImage? {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(
                    returning: Self.downsample(data: data, maxPixel: maxPixel)
                )
            }
        }
    }

    // MARK: Deleting

    func delete(fileName: String) {
        let url = directory.appendingPathComponent(fileName)
        queue.async(flags: .barrier) {
            // Drop every cached resolution so a deleted photo can never be
            // served from memory again.
            self.cache.removeAllObjects()
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: Downsampling

    private static func downsample(url: URL, maxPixel: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return nil
        }
        return downsample(source: source, maxPixel: maxPixel)
    }

    private static func downsample(data: Data, maxPixel: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }
        return downsample(source: source, maxPixel: maxPixel)
    }

    private static func downsample(source: CGImageSource, maxPixel: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(160, maxPixel)
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Lazy photo view

struct StoredPhotoView: View {
    let fileName: String
    var maxPixel: CGFloat = 700
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var didAttempt = false

    var body: some View {
        ZStack {
            Theme.surfaceSoft

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if didAttempt {
                Image(systemName: "photo")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Theme.tertiary)
            } else {
                ProgressView()
                    .tint(Theme.tertiary)
                    .scaleEffect(0.7)
            }
        }
        .clipped()
        .task(id: "\(fileName)-\(Int(maxPixel))") {
            image = nil
            didAttempt = false

            guard !fileName.isEmpty else {
                didAttempt = true
                return
            }
            let loaded = await PhotoStore.shared.image(
                fileName: fileName,
                maxPixel: maxPixel
            )
            guard !Task.isCancelled else { return }
            image = loaded
            didAttempt = true
        }
    }
}
