
import SwiftUI
import MapKit
import AVFoundation

@MainActor
class VideoGenerationManager: ObservableObject {
    @Published var isGenerating: Bool = false
    @Published var progress: Double = 0.0
    @Published var generatedVideoURL: URL?
    @Published var error: String?
    
    // Data
    var totalDistance: Double = 0
    
    // Closures hooked up by SmoothRouteMapView.Coordinator
    var onUpdateMapState: ((Double) -> Void)?
    var onGetSnapshot: (() -> UIImage?)?
    
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private let frameRate: Int32 = 24 // Optimized for speed (was 30)
    
    func startGeneration(duration: Double) {
        guard totalDistance > 0, let updateMap = onUpdateMapState, let getSnapshot = onGetSnapshot else {
            self.error = "Map not ready or route empty"
            return
        }
        
        self.isGenerating = true
        self.progress = 0
        self.generatedVideoURL = nil
        self.error = nil // Clear previous error
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("trip_video_\(Int(Date().timeIntervalSince1970)).mp4")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        // Setup Writer
        // Note: We need a snapshot to know size. We'll take one initial snapshot.
        guard let firstImage = getSnapshot() else {
            self.error = "Failed to capture initial snapshot"
            self.isGenerating = false
            return
        }
        
        let size = firstImage.size
        
        do {
            assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: .mp4)
            let settings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(size.width),
                AVVideoHeightKey: Int(size.height)
            ]
            assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            assetWriterInput?.expectsMediaDataInRealTime = false
            
            let attributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: Int(size.width),
                kCVPixelBufferHeightKey as String: Int(size.height)
            ]
            
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: assetWriterInput!,
                sourcePixelBufferAttributes: attributes
            )
            
            if assetWriter?.canAdd(assetWriterInput!) == true {
                assetWriter?.add(assetWriterInput!)
            }
            
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: .zero)
            
            // Start Loop
            let totalFrames = Int(frameRate) * Int(duration)
            let localTotalDistance = totalDistance
            let localFrameRate = frameRate

            Task.detached(priority: .userInitiated) { [weak self] in
                guard let self = self else { return }

                for i in 0...totalFrames {
                    let isStillGenerating = await MainActor.run { self.isGenerating }
                    if !isStillGenerating { break } // Cancelled

                    let frameProgress = Double(i) / Double(totalFrames)
                    let dist = frameProgress * localTotalDistance

                    // Main Actor for Map Updates
                    await MainActor.run {
                        updateMap(dist)
                        self.progress = frameProgress
                    }
                    
                    // Wait for render (heuristic)
                    // Reduced to 10ms to speed up generation (approx 100fps processing speed if CPU allows)
                    try? await Task.sleep(nanoseconds: 10_000_000)
                    
                    // Snapshot and Write
                    if let image = await MainActor.run(body: { getSnapshot() }) {
                        if let buffer = self.buffer(from: image) {
                            let time = CMTime(value: Int64(i), timescale: localFrameRate)

                            var isReady = await MainActor.run { self.assetWriterInput?.isReadyForMoreMediaData ?? false }
                            while !isReady {
                                try? await Task.sleep(nanoseconds: 10_000_000)
                                isReady = await MainActor.run { self.assetWriterInput?.isReadyForMoreMediaData ?? false }
                            }

                            await MainActor.run {
                                self.pixelBufferAdaptor?.append(buffer, withPresentationTime: time)
                            }
                        }
                    }
                }

                await self.finishWriting(fileURL: fileURL)
            }
            
        } catch {
            self.error = error.localizedDescription
            self.isGenerating = false
        }
    }
    
    private func finishWriting(fileURL: URL) async {
        assetWriterInput?.markAsFinished()
        await assetWriter?.finishWriting()
        
        await MainActor.run {
            self.isGenerating = false
            self.generatedVideoURL = fileURL
        }
    }
    
    // Buffer conversion
    nonisolated private func buffer(from image: UIImage) -> CVPixelBuffer? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, nil, &buffer)
        guard status == kCVReturnSuccess, let pixelBuffer = buffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        return pixelBuffer
    }
}
