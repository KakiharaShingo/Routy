
import SwiftUI
import MapKit

struct SmoothRouteMapView: UIViewRepresentable {
    let checkpoints: [Checkpoint]
    let routeCoordinates: [CLLocationCoordinate2D]
    let routeSegmentTypes: [RouteAnimationViewModel.TransportMode]
    let transportMode: RouteAnimationViewModel.TransportMode

    @Binding var isPlaying: Bool
    @Binding var progress: Double
    @Binding var animationSpeed: Double
    @Binding var currentCoordinate: CLLocationCoordinate2D?
    @Binding var selectedCheckpoint: Checkpoint?
    @Binding var currentDateString: String?
    @Binding var cameraFollowEnabled: Bool

    // Video Generation
    @ObservedObject var videoManager: VideoGenerationManager
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.overrideUserInterfaceStyle = .dark
        mapView.isPitchEnabled = true
        
        // Enable selection
        mapView.selectableMapFeatures = [.pointsOfInterest] // Basic setup
        
        if let first = checkpoints.first {
            let region = MKCoordinateRegion(
                center: first.coordinate(),
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )
            mapView.setRegion(region, animated: false)
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.parent = self

        // Connect Video Manager
        // We only need to set these once or when the view re-appears.
        // Doing it every update is fine as they capture weak references.
        let coordinator = context.coordinator
        videoManager.onUpdateMapState = { [weak coordinator] distance in
            coordinator?.seek(to: distance)
        }
        videoManager.onGetSnapshot = { [weak uiView] in
            guard let view = uiView else { return nil }
            return coordinator.snapshot(view: view)
        }
        
        context.coordinator.update(
            checkpoints: checkpoints,
            routeCoordinates: routeCoordinates,
            routeSegmentTypes: routeSegmentTypes,
            transportMode: transportMode,
            isPlaying: isPlaying,
            speed: animationSpeed,
            mapView: uiView
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class CheckpointAnnotation: MKPointAnnotation {
        var checkpoint: Checkpoint
        
        init(checkpoint: Checkpoint) {
            self.checkpoint = checkpoint
            super.init()
            self.coordinate = checkpoint.coordinate()
            self.title = checkpoint.name ?? "Checkpoint"
        }
    }
    
    // MARK: - Coordinator (Animation Engine)
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: SmoothRouteMapView
        weak var mapView: MKMapView?
        
        // Animation Data
        private var fullRoutePoints: [CLLocationCoordinate2D] = []
        private var fullRouteTypes: [RouteAnimationViewModel.TransportMode] = []
        private var cumulativeDistances: [Double] = []
        private var totalDistance: Double = 0
        private var checkpointDistances: [Double] = [] // Distance to each checkpoint along route
        
        // State
        private var currentTransportMode: RouteAnimationViewModel.TransportMode = .straight
        
        private var currentPolyline: MKPolyline?
        private var markerAnnotation: MKPointAnnotation?
        private var activePolyline: MKPolyline?
        private var lastPolylineIndex: Int = -1
        private var lastMarkerCoordinate: CLLocationCoordinate2D?
        private var lastCameraCoordinate: CLLocationCoordinate2D?
        private var lastReachedCheckpointIndex: Int = -1 // Track last reached checkpoint
        private var lastDisplayedDate: String? // Track last displayed date

        // Control
        private var displayLink: CADisplayLink?
        private var lastTimestamp: CFTimeInterval = 0
        private var currentAnimDistance: Double = 0

        private var baseSpeedMPS: Double = 100.0
        
        init(_ parent: SmoothRouteMapView) {
            self.parent = parent
            self.currentTransportMode = parent.transportMode
        }
        
        // Exposed method for Video Manager
        func seek(to distance: Double) {
            self.currentAnimDistance = distance
            self.updateMapState()
            // We don't necessarily update parent.progress here to avoid SwiftUI loop during fast generation
        }
        
        func snapshot(view: UIView) -> UIImage? {
            UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, UIScreen.main.scale)
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: false) // 'false' is significantly faster
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        
        func update(checkpoints: [Checkpoint], routeCoordinates: [CLLocationCoordinate2D], routeSegmentTypes: [RouteAnimationViewModel.TransportMode], transportMode: RouteAnimationViewModel.TransportMode, isPlaying: Bool, speed: Double, mapView: MKMapView) {
            self.mapView = mapView
            
            let newPoints = routeCoordinates
            let isRouteChanged = newPoints.count != fullRoutePoints.count || (newPoints.first?.latitude != fullRoutePoints.first?.latitude)
            
            if isRouteChanged {
                self.fullRoutePoints = newPoints
                self.fullRouteTypes = routeSegmentTypes

                // Pre-calculate distances
                var dists: [Double] = [0]
                var total: Double = 0
                if newPoints.count > 1 {
                    for i in 0..<newPoints.count - 1 {
                        let p1 = MKMapPoint(newPoints[i])
                        let p2 = MKMapPoint(newPoints[i+1])
                        let d = p1.distance(to: p2)
                        total += d
                        dists.append(total)
                    }
                }
                self.cumulativeDistances = dists
                self.totalDistance = total

                if total > 0 {
                    self.baseSpeedMPS = total / 180.0
                }

                // Push total distance to Video Manager
                DispatchQueue.main.async {
                    self.parent.videoManager.totalDistance = total
                }

                // Calculate checkpoint distances by finding closest route point for each checkpoint
                var cpDistances: [Double] = []
                for checkpoint in checkpoints {
                    let cpCoord = checkpoint.coordinate()
                    var minDistance = Double.greatestFiniteMagnitude
                    var closestRouteDistance: Double = 0

                    for (idx, routePoint) in newPoints.enumerated() {
                        let distance = MKMapPoint(cpCoord).distance(to: MKMapPoint(routePoint))
                        if distance < minDistance {
                            minDistance = distance
                            closestRouteDistance = idx < dists.count ? dists[idx] : total
                        }
                    }
                    cpDistances.append(closestRouteDistance)
                }
                self.checkpointDistances = cpDistances
                
                mapView.removeOverlays(mapView.overlays)
                mapView.removeAnnotations(mapView.annotations)
                
                if !fullRoutePoints.isEmpty {
                    let backgroundPolyline = MKPolyline(coordinates: fullRoutePoints, count: fullRoutePoints.count)
                    backgroundPolyline.subtitle = "background"
                    mapView.addOverlay(backgroundPolyline, level: .aboveRoads)
                }
                
                for cp in checkpoints {
                    let annotation = CheckpointAnnotation(checkpoint: cp)
                    mapView.addAnnotation(annotation)
                }
                
                if let first = fullRoutePoints.first {
                    markerAnnotation = MKPointAnnotation()
                    markerAnnotation?.coordinate = first
                    markerAnnotation?.title = "Current"
                    mapView.addAnnotation(markerAnnotation!)
                    
                    // Avoid modifying state during view update
                    DispatchQueue.main.async {
                        self.parent.currentCoordinate = first
                        self.parent.progress = 0
                    }
                }
                
                // Initial mode
                if let firstType = fullRouteTypes.first {
                    self.currentTransportMode = firstType
                } else {
                    self.currentTransportMode = transportMode
                }
                
                currentAnimDistance = 0
                lastCameraCoordinate = nil // Reset camera tracking
                lastReachedCheckpointIndex = -1 // Reset checkpoint tracking
                lastDisplayedDate = nil // Reset date tracking

                // Set initial camera if follow is enabled
                if parent.cameraFollowEnabled, let first = fullRoutePoints.first {
                    let camera = MKMapCamera(lookingAtCenter: first, fromDistance: 8000, pitch: 50, heading: 0)
                    mapView.setCamera(camera, animated: false)
                    lastCameraCoordinate = first
                }
            } else {
                // Determine if manual override happened or just refresh
                // Check if progress changed externally (Seek)
                if totalDistance > 0 && !parent.videoManager.isGenerating { // Avoid conflicting with generation
                    let expectedDist = parent.progress * totalDistance
                    // If difference is significant (e.g. > 5 meters or percentage based), jump.
                    // This handles Scrubbing.
                    if abs(expectedDist - currentAnimDistance) > 10.0 {
                        currentAnimDistance = expectedDist

                        // Reset checkpoint and date tracking when scrubbing
                        lastReachedCheckpointIndex = -1
                        lastDisplayedDate = nil

                        // Re-calculate which checkpoints should be marked as passed
                        for i in 0..<checkpointDistances.count {
                            if checkpointDistances[i] < currentAnimDistance {
                                lastReachedCheckpointIndex = i

                                // Update last displayed date to the last passed checkpoint's date
                                let checkpoint = parent.checkpoints[i]
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy年M月d日"
                                dateFormatter.locale = Locale(identifier: "ja_JP")
                                lastDisplayedDate = dateFormatter.string(from: checkpoint.timestamp)
                            }
                        }

                        updateMapState()
                    }
                }
            }
            
            // Handle Play/Pause
            if isPlaying && displayLink == nil {
                startAnimation()
            } else if !isPlaying && displayLink != nil {
                stopAnimation()
            }
        }
        
        private func startAnimation() {
            lastTimestamp = CACurrentMediaTime()
            displayLink = CADisplayLink(target: self, selector: #selector(step))
            displayLink?.add(to: .main, forMode: .common)

            // Show date popup at start if it's the beginning (progress near 0)
            if currentAnimDistance < 10.0 && parent.checkpoints.count > 0 && lastDisplayedDate == nil {
                let firstCheckpoint = parent.checkpoints[0]
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy年M月d日"
                dateFormatter.locale = Locale(identifier: "ja_JP")
                let dateStr = dateFormatter.string(from: firstCheckpoint.timestamp)

                lastDisplayedDate = dateStr
                DispatchQueue.main.async {
                    withAnimation {
                        self.parent.currentDateString = dateStr
                    }
                }

                // Auto-hide after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.parent.currentDateString = nil
                    }
                }
            }
        }
        
        private func stopAnimation() {
            displayLink?.invalidate()
            displayLink = nil
        }
        
        @objc private func step() {
            guard mapView != nil, fullRoutePoints.count >= 2, totalDistance > 0 else { return }
            
            let now = CACurrentMediaTime()
            let deltaTime = now - lastTimestamp
            lastTimestamp = now
            let safeDelta = min(deltaTime, 0.1)
            
            let moveDist = baseSpeedMPS * parent.animationSpeed * safeDelta
            currentAnimDistance += moveDist
            
            if currentAnimDistance >= totalDistance {
                currentAnimDistance = totalDistance
                parent.isPlaying = false
                stopAnimation()
            }
            
            // Sync back to parent
            parent.progress = currentAnimDistance / totalDistance
            
            updateMapState()
        }
        
        private func updateMapState() {
            guard let mapView = mapView else { return }

            let (coordinate, index) = coordinateForDistance(currentAnimDistance)

            // Only update bindings if NOT generating video to avoid overhead/conflicts
            if !parent.videoManager.isGenerating {
                parent.currentCoordinate = coordinate
            }

            // Check if reached a checkpoint
            checkCheckpointReached(currentDistance: currentAnimDistance)

            // Update Mode based on index
            if index < fullRouteTypes.count {
                let newMode = fullRouteTypes[index]
                if newMode != currentTransportMode {
                    currentTransportMode = newMode
                    // Refresh marker icon
                    if let marker = markerAnnotation {
                        mapView.removeAnnotation(marker)
                        mapView.addAnnotation(marker)
                    }
                }
            }
            
            // Update marker coordinate efficiently
            if let marker = markerAnnotation {
                // Only update if position changed significantly (reduces annotation view updates)
                let shouldUpdate: Bool
                if let lastCoord = lastMarkerCoordinate {
                    let latDiff = abs(coordinate.latitude - lastCoord.latitude)
                    let lonDiff = abs(coordinate.longitude - lastCoord.longitude)
                    shouldUpdate = latDiff > 0.00001 || lonDiff > 0.00001
                } else {
                    shouldUpdate = true
                }

                if shouldUpdate {
                    marker.coordinate = coordinate
                    lastMarkerCoordinate = coordinate
                }
            }
            
            // Update Trail (Active Polyline)
            updatePolyline(to: coordinate, index: index)

            // Camera Follow - Only update if enabled and coordinate changed significantly
            if parent.cameraFollowEnabled {
                let shouldUpdateCamera: Bool
                if let lastCoord = lastCameraCoordinate {
                    let latDiff = abs(coordinate.latitude - lastCoord.latitude)
                    let lonDiff = abs(coordinate.longitude - lastCoord.longitude)
                    // Update camera less frequently (0.0001 degrees ≈ 11 meters)
                    shouldUpdateCamera = latDiff > 0.0001 || lonDiff > 0.0001
                } else {
                    shouldUpdateCamera = true
                }

                if shouldUpdateCamera {
                    let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: 8000, pitch: 50, heading: 0)
                    mapView.setCamera(camera, animated: false)
                    lastCameraCoordinate = coordinate
                }
            }
        }
        
        private func coordinateForDistance(_ distance: Double) -> (CLLocationCoordinate2D, Int) {
            if distance <= 0 { return (fullRoutePoints.first ?? kCLLocationCoordinate2DInvalid, 0) }
            if distance >= totalDistance { return (fullRoutePoints.last ?? kCLLocationCoordinate2DInvalid, fullRoutePoints.count - 1) }

            for i in 0..<cumulativeDistances.count - 1 {
                if distance >= cumulativeDistances[i] && distance < cumulativeDistances[i+1] {
                    let startDist = cumulativeDistances[i]
                    let endDist = cumulativeDistances[i+1]
                    let segmentLen = endDist - startDist

                    // Use smooth interpolation (ease-in-out)
                    var fraction = (distance - startDist) / segmentLen
                    // Apply smoothing curve for more natural movement
                    fraction = smoothInterpolation(fraction)

                    let start = fullRoutePoints[i]
                    let end = fullRoutePoints[i+1]

                    let lat = start.latitude + (end.latitude - start.latitude) * fraction
                    let lon = start.longitude + (end.longitude - start.longitude) * fraction
                    return (CLLocationCoordinate2D(latitude: lat, longitude: lon), i)
                }
            }
            return (fullRoutePoints.last ?? kCLLocationCoordinate2DInvalid, fullRoutePoints.count - 1)
        }

        // Smooth interpolation using ease-in-out curve
        private func smoothInterpolation(_ t: Double) -> Double {
            // Simple smoothstep function: 3t^2 - 2t^3
            return t * t * (3.0 - 2.0 * t)
        }

        // Check if reached a checkpoint
        private func checkCheckpointReached(currentDistance: Double) {
            guard !parent.videoManager.isGenerating else { return }
            guard parent.checkpoints.count > 0 else { return }
            guard checkpointDistances.count == parent.checkpoints.count else { return }

            // Check each checkpoint in order
            for i in 0..<parent.checkpoints.count {
                let checkpointDistance = checkpointDistances[i]

                // Check if this is a new checkpoint we've reached
                // Use a tolerance of 100m to ensure we catch it
                let tolerance: Double = 100.0
                if i > lastReachedCheckpointIndex && currentDistance >= (checkpointDistance - tolerance) && currentDistance <= (checkpointDistance + tolerance) {
                    lastReachedCheckpointIndex = i
                    let checkpoint = parent.checkpoints[i]

                    // Check if date has changed
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy年M月d日"
                    dateFormatter.locale = Locale(identifier: "ja_JP")
                    let currentDateStr = dateFormatter.string(from: checkpoint.timestamp)

                    // Stop the display link
                    stopAnimation()

                    if lastDisplayedDate != currentDateStr {
                        // Date changed - show date popup first (2s) then photo (2s)
                        lastDisplayedDate = currentDateStr
                        DispatchQueue.main.async {
                            withAnimation {
                                self.parent.currentDateString = currentDateStr
                            }
                        }

                        // Auto-hide date popup after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                self.parent.currentDateString = nil
                            }

                            // Show photo popup after date popup disappears
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self.parent.isPlaying = false
                                self.parent.selectedCheckpoint = checkpoint

                                // Auto-resume after 2 seconds (photo display time)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    if self.parent.selectedCheckpoint?.id == checkpoint.id {
                                        self.parent.selectedCheckpoint = nil
                                        self.parent.isPlaying = true
                                        self.startAnimation()
                                    }
                                }
                            }
                        }
                    } else {
                        // Same date - show photo popup immediately (2s)
                        DispatchQueue.main.async {
                            self.parent.isPlaying = false
                            self.parent.selectedCheckpoint = checkpoint
                        }

                        // Auto-resume after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if self.parent.selectedCheckpoint?.id == checkpoint.id {
                                self.parent.selectedCheckpoint = nil
                                self.parent.isPlaying = true
                                self.startAnimation()
                            }
                        }
                    }
                    break
                }
            }
        }
        
        private func updatePolyline(to currentPos: CLLocationCoordinate2D, index: Int) {
            // Always update polyline for smooth real-time tracking
            guard let mapView = mapView else { return }

            if let current = activePolyline {
                mapView.removeOverlay(current)
            }

            var points = Array(fullRoutePoints.prefix(index + 1))
            points.append(currentPos)

            let newPolyline = MKPolyline(coordinates: points, count: points.count)
            newPolyline.subtitle = "active"
            mapView.addOverlay(newPolyline, level: .aboveRoads)
            activePolyline = newPolyline
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.lineCap = .round
                renderer.lineJoin = .round
                
                if polyline.subtitle == "background" {
                    renderer.strokeColor = UIColor.systemGray.withAlphaComponent(0.3)
                    renderer.lineWidth = 4
                } else if polyline.subtitle == "active" {
                    renderer.strokeColor = UIColor.systemBlue
                    renderer.lineWidth = 6
                    renderer.alpha = 0.9
                } else {
                    renderer.strokeColor = .systemBlue
                    renderer.lineWidth = 4
                }
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // MARK: - Annotation Handling
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation === markerAnnotation {
                // Walker Icon (Keep existing logic)
                let identifier = "Walker"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                var iconName = "figure.walk.circle.fill"
                switch currentTransportMode {
                case .car: iconName = "car.circle.fill"
                case .train: iconName = "tram.circle.fill"
                case .plane: iconName = "airplane.circle.fill"
                case .walk, .straight: iconName = "figure.walk.circle.fill"
                }
                if view == nil {
                    view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    view?.frame.size = CGSize(width: 40, height: 40)
                } else {
                    view?.annotation = annotation
                }
                view?.image = UIImage(systemName: iconName)?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
                return view
            } else if let cpAnnotation = annotation as? CheckpointAnnotation {
                let identifier = "Checkpoint"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    view?.annotation = annotation
                }

                // カテゴリに応じてピンをカスタマイズ
                let checkpoint = cpAnnotation.checkpoint
                if let category = checkpoint.category {
                    view?.markerTintColor = categoryUIColor(for: category)
                    view?.glyphImage = UIImage(systemName: category.icon)
                } else {
                    view?.markerTintColor = .systemBlue
                    view?.glyphImage = UIImage(systemName: "photo")
                }

                // Custom Callout handling via didSelect
                view?.canShowCallout = false // We handle selection manually to show SwiftUI Text
                return view
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let cpAnnotation = view.annotation as? CheckpointAnnotation {
                parent.selectedCheckpoint = cpAnnotation.checkpoint

                // Deselect to allow re-selection
                mapView.deselectAnnotation(cpAnnotation, animated: true)
            }
        }

        private func categoryUIColor(for category: CheckpointCategory) -> UIColor {
            switch category {
            case .restaurant: return .systemOrange
            case .cafe: return .systemBrown
            case .gasStation: return .systemRed
            case .hotel: return .systemPurple
            case .tourist: return .systemBlue
            case .park: return .systemGreen
            case .shopping: return .systemPink
            case .transport: return .systemIndigo
            case .other: return .systemGray
            }
        }
    }
}
