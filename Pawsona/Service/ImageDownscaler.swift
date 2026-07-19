import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Downscales images to avoid pushing full-resolution photos through CloudKit sync,
/// PDF rendering, and JSON transfer, which can cause performance issues and hit limits.
nonisolated enum ImageDownscaler {
    /// Downscales the given image data to a JPEG with a maximum longest side of 1024 pixels.
    /// Returns the original data if it is already smaller or if downscaling fails.
    static func downscale(imageData: Data) -> Data {
        let maxPixelSize: Int = 1024

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return imageData
        }

        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return imageData
        }

        let destinationOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.8
        ]

        CGImageDestinationAddImage(destination, cgImage, destinationOptions as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            return imageData
        }

        let compressedData = outputData as Data
        if compressedData.count < imageData.count {
            return compressedData
        } else {
            return imageData
        }
    }
}
