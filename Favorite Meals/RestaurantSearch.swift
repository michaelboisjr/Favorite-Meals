import Foundation
import MapKit
import Observation

@Observable
class RestaurantSearchViewModel: NSObject { // Must be NSObject for the delegate
    var searchText: String = ""
    var results: [MKMapItem] = []
    
    var addressSearchText: String = ""
    var addressCompletions: [MKLocalSearchCompletion] = []
    
    private var completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address // Only suggest addresses
    }
    
    func searchNearby(query: String) {
        guard !query.isEmpty else { results = []; return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        MKLocalSearch(request: request).start { [weak self] res, _ in
            self?.results = res?.mapItems ?? []
        }
    }
    
    func searchAddress(query: String) {
        completer.queryFragment = query // This triggers the real-time search
    }
}

// Extend to handle the delegate
extension RestaurantSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.addressCompletions = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search error: \(error.localizedDescription)")
    }
}
