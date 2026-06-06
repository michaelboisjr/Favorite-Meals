import MapKit
import SwiftUI

struct SearchSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var viewModel: RestaurantSearchViewModel
    var isAddressSearch: Bool
    var onSelect: (String, String) -> Void  // Returns (Name, Address)

    @State private var searchText = ""
    @State private var isSearchPresented = true

    var body: some View {
        NavigationStack {
            List {
                if isAddressSearch {
                    ForEach(viewModel.addressCompletions, id: \.self) {
                        completion in
                        Button(action: {
                            performAddressSearch(completion)
                        }) {
                            VStack(alignment: .leading) {
                                Text(completion.title).font(.headline)
                                Text(completion.subtitle).font(.caption)
                            }
                        }
                    }
                } else {
                    ForEach(viewModel.results, id: \.self) { item in
                        Button(action: {
                            onSelect(
                                item.name ?? "",
                                item.address?.fullAddress ?? ""
                            )
                            dismiss()
                        }) {
                            VStack(alignment: .leading) {
                                Text(item.name ?? "").font(.headline)
                                Text(item.address?.fullAddress ?? "").font(
                                    .caption
                                )
                            }
                        }
                    }
                }
            }
            .searchable(
                text: $searchText,
                isPresented: $isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .always)
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: searchText) { _, newValue in
                if isAddressSearch {
                    viewModel.addressSearchText = newValue
                    viewModel.searchAddress(query: newValue)
                } else {
                    viewModel.searchText = newValue
                    viewModel.searchNearby(query: newValue)
                }
            }
        }
        .withAppBackground()
    }

    private func performAddressSearch(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            if let item = response?.mapItems.first {
                onSelect("", item.placemark.title ?? "")
                dismiss()
            }
        }
    }
}
