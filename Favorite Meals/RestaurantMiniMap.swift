import SwiftUI
import MapKit

struct RestaurantMiniMap: View {
    let restaurantName: String
    let address: String
    @State private var position: MapCameraPosition = .automatic
    @State private var markerCoordinate: CLLocationCoordinate2D? // Start as nil

    var body: some View {
        Map(position: $position) {
            if let coord = markerCoordinate {
                Marker(restaurantName, coordinate: coord)
            }
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            geocodeAddress()
        }
        .overlay {
            Button(action: openInMaps) { Color.clear }
        }
    }

    private func geocodeAddress() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(restaurantName), \(address)"
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            if let item = response?.mapItems.first {
                self.markerCoordinate = item.location.coordinate
                self.position = .item(item) // Center map on the result
            }
        }
    }

    private func openInMaps() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(restaurantName), \(address)"
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let item = response?.mapItems.first else { return }
            item.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        }
    }
}
