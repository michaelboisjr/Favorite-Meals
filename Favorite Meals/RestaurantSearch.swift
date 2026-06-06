import Foundation
import MapKit
import Observation

@Observable
class RestaurantSearchViewModel {
    var searchText: String = ""
    var results: [MKMapItem] = []
    
    // Add these for the address search
    var addressSearchText: String = ""
    var addressResults: [MKMapItem] = []
    
    // Existing search for restaurants
    func searchNearby(query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, _ in
            self?.results = response?.mapItems ?? []
        }
    }
    
    // New search specifically for addresses
    func searchAddress(query: String) {
        guard !query.isEmpty else {
            addressResults = []
            return
        }
        print("Searching for: \(query)") // Check Xcode console
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .address // <--- Crucial: set to address
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, _ in
            self?.addressResults = response?.mapItems ?? []
            print("Found \(response?.mapItems.count ?? 0) results") // Check Xcode console
        }
    }
}
