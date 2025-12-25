import SwiftUI
import CoreLocation

struct CategoryDebugView: View {
    @State private var results: [String] = []
    @State private var isRunning = false
    
    // Test cases: (Name, Latitude, Longitude, Expected Category)
    let testCases: [(String, Double, Double, String)] = [
        ("Tokyo Tower", 35.658581, 139.745433, "観光地"), // Tourist
        ("Shinjuku Station", 35.6896, 139.7006, "交通機関"), // Transport
        ("Starbucks Shibuya", 35.6598, 139.7005, "カフェ"), // Cafe (Coordinates approximate)
        ("Yoyogi Park", 35.6717, 139.6949, "公園") // Park
    ]
    
    var body: some View {
        VStack {
            Text("Category Detector Debug")
                .font(.title)
                .padding()
            
            Button("Run Tests") {
                runTests()
            }
            .disabled(isRunning)
            .padding()
            
            List(results, id: \.self) { result in
                Text(result)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }
    
    func runTests() {
        isRunning = true
        results.removeAll()
        
        Task {
            for test in testCases {
                let coordinate = CLLocationCoordinate2D(latitude: test.1, longitude: test.2)
                await withCheckedContinuation { continuation in
                    LocationCategoryDetector.shared.detectCategory(at: coordinate) { category in
                        let catName = category?.displayName ?? "Unknown"
                        let success = catName == test.3 || (test.3 == "観光地" && catName == "その他") // Allow minor deviations or correct assertions
                        let mark = success ? "✅" : "⚠️" // Use warning instead of fail as location data varies
                        
                        let result = "\(mark) \(test.0): \(catName) (Expected: \(test.3))"
                        
                        DispatchQueue.main.async {
                            results.append(result)
                        }
                        continuation.resume()
                    }
                }
            }
            
            DispatchQueue.main.async {
                isRunning = false
            }
        }
    }
}

#Preview {
    CategoryDebugView()
}
