import SwiftUI
import MapKit

struct RestaurantMiniMap: View {
    let restaurantName: String
    let address: String
    @State private var position: MapCameraPosition = .automatic
    @State private var coordinate: CLLocationCoordinate2D?

    var body: some View {
        Button(action: openInMaps) {
            ZStack {
                if let coordinate = coordinate {
                    Map(position: .constant(.region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))))) {
                        Marker(restaurantName, coordinate: coordinate)
                    }
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .allowsHitTesting(false) // Let the Button handle the tap
                } else {
                    ProgressView()
                        .frame(height: 150)
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear(perform: geocodeAddress)
    }

    private func geocodeAddress() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, _ in
            if let location = placemarks?.first?.location {
                self.coordinate = location.coordinate
            }
        }
    }

    private func openInMaps() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, _ in
            guard let placemark = placemarks?.first else { return }
            let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            mapItem.name = restaurantName
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
    }
}
