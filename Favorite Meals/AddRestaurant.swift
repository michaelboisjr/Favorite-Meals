import MapKit
import PhotosUI
import SwiftData
import SwiftUI

struct AddRestaurantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = RestaurantSearchViewModel()
    @State private var isSelectingResult = false
    // Optional: Pass an existing restaurant to edit
    var restaurantToEdit: Restaurant?
    // Callback to pass the selected restaurant back
    var onSave: (Restaurant) -> Void

    // Restaurant State
    @State private var name: String = ""
    @State private var address: String = ""

    // Logo Selection
    @State private var logoItem: PhotosPickerItem?
    @State private var logoData: Data?

    init(
        restaurantToEdit: Restaurant? = nil,
        onSave: @escaping (Restaurant) -> Void
    ) {
        self.restaurantToEdit = restaurantToEdit
        self.onSave = onSave
        _name = State(initialValue: restaurantToEdit?.name ?? "")
        _address = State(initialValue: restaurantToEdit?.address ?? "")
        _logoData = State(initialValue: restaurantToEdit?.logoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Logo") {
                    PhotosPicker(selection: $logoItem, matching: .images) {
                        if let data = logoData,
                            let uiImage = UIImage(data: data)
                        {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Label("Select Logo", systemImage: "photo")
                        }
                    }  // 👈 This is the end of PhotosPicker
                }  // 👈 This is the end of Logo section
                .withListRow()

                Section("Restaurant Details") {
                    // 1. Unified Input Field
                    TextField("Restaurant Name", text: $viewModel.searchText)
                        .onChange(of: viewModel.searchText) { oldValue, newValue in
                            if isSelectingResult { return }
                            name = newValue
                            viewModel.searchNearby(query: newValue)
                        }

                    TextField("Address", text: $address)
                        .onChange(of: address) { _, newValue in
                            // Stop the search if we are currently selecting a result
                            if isSelectingResult { return }
                            
                            viewModel.addressSearchText = newValue
                            viewModel.searchAddress(query: newValue)
                        }

                    // 2. The Result List (Wrapped in a VStack, NOT a Section)
                    if (!viewModel.results.isEmpty && !viewModel.searchText.isEmpty) ||
                       (!viewModel.addressCompletions.isEmpty && !viewModel.addressSearchText.isEmpty) {
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                Text("Suggestions")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Dismiss") {
                                    viewModel.results = []
                                }
                                .font(.subheadline)
                                .foregroundStyle(.red)
                            }
                            .padding(.horizontal, 5)
                            .padding(.bottom, 5)

                            // Scrollable List
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    // If we have restaurant results, show them
                                    if !viewModel.results.isEmpty {
                                        ForEach(viewModel.results, id: \.self) { item in
                                            Button {
                                                print("Selecting item: \(item.name ?? "No Name")")
                                                print("Address found: \(item.address?.fullAddress ?? "NIL")")
                                                isSelectingResult = true
                                                name = item.name ?? ""
                                                viewModel.searchText = item.name ?? ""
                                                // Use async to force the TextField to pick up the new value
                                                    DispatchQueue.main.async {
                                                        address = item.address?.fullAddress ?? ""
                                                    }
                                                // Clear the search results
                                                viewModel.results = []
                                                viewModel.addressCompletions = []
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    isSelectingResult = false
                                                }
                                            } label: {
                                                VStack(alignment: .leading) {
                                                    Text(item.name ?? "").font(.headline)
                                                    Text(item.address?.fullAddress ?? "").font(.caption)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                }
                                                .padding()
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .background(Theme.Colors.fields.opacity(0.7))
                                            Divider()
                                        }
                                    }
                                    // If we have address results, show them
                                    if !viewModel.addressCompletions.isEmpty {
                                        ForEach(viewModel.addressCompletions, id: \.self) { completion in
                                            Button {
                                                // 1. Mark as selecting so onChange ignores the upcoming text changes
                                                isSelectingResult = true
                                                
                                                let request = MKLocalSearch.Request(completion: completion)
                                                MKLocalSearch(request: request).start { response, _ in
                                                    if let item = response?.mapItems.first {
                                                        // 2. Use MainActor to ensure UI updates happen immediately
                                                        DispatchQueue.main.async {
                                                            address = item.placemark.title ?? ""
                                                            viewModel.addressSearchText = ""
                                                            viewModel.addressCompletions = [] // Clear the list
                                                            
                                                            // 3. Clear focus so the next interaction is a fresh start
                                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                                                            to: nil, from: nil, for: nil)
                                                            
                                                            // 4. Delay clearing the flag to ensure all state updates are finished
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                                isSelectingResult = false
                                                            }
                                                        }
                                                    }
                                                }
                                            } label: {
                                                VStack(alignment: .leading) {
                                                    Text(completion.title).font(.headline)
                                                    Text(completion.subtitle).font(.caption)
                                                }
                                                .padding(.horizontal)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .withListRow()
            }  // 👈 This is the end of Form
            .navigationTitle(
                restaurantToEdit == nil ? "New Restaurant" : "Edit Restaurant"
            )
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let restaurant = restaurantToEdit {
                            restaurant.name = name
                            restaurant.address = address
                            onSave(restaurant)
                        } else {
                            let newRestaurant = Restaurant(
                                name: name,
                                address: address
                            )
                            modelContext.insert(newRestaurant)
                            onSave(newRestaurant)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }  // 👈 This is the end of .toolbar
            // Logo Optimization (reuse the resizing logic)
            .onChange(of: logoItem) {
                Task {
                    guard
                        let data = try? await logoItem?.loadTransferable(
                            type: Data.self
                        ),
                        let uiImage = UIImage(data: data)
                    else { return }

                    // Logos are typically small, so 400px width is sufficient
                    if let resized = uiImage.resized(toWidth: 400),
                        let compressed = resized.jpegData(
                            compressionQuality: 0.7
                        )
                    {
                        await MainActor.run { self.logoData = compressed }
                    }
                }
            }  // 👈 This is the end of .onChange
        }  // 👈 This is the end of Navigation stack
        .withAppBackground()
    }  // 👈 This is the end of View
}  // 👈 This is the end of Struct
