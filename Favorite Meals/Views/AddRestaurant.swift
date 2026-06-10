import MapKit
import PhotosUI
import SwiftData
import SwiftUI

struct AddRestaurantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showNameSearch = false
    @State private var showAddressSearch = false

    @State private var viewModel = RestaurantSearchViewModel()
    @State private var isSelectingResult = false
    
    var restaurantToEdit: Restaurant?
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
                Section("Restaurant Details") {

                    // 1. Name Field
                    ZStack(alignment: .leading) {
                        TextField("Restaurant Name", text: $name)
                            .disabled(true)  // Force the search sheet interaction

                        Button("") { showNameSearch = true }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // 2. Address Field
                    ZStack(alignment: .leading) {
                        TextField("Address", text: $address)
                            .disabled(true)

                        Button("") { showAddressSearch = true }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                }
                .withListRow()

                Section("Logo") {
                    PhotosPicker(selection: $logoItem, matching: .images) {
                        if let data = logoData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Label("Select Logo", systemImage: "photo")
                        }
                    }
                }
                .withListRow()
            }
            .navigationTitle(
                restaurantToEdit == nil ? "New Restaurant" : "Edit Restaurant"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let restaurant = restaurantToEdit {
                            // Update Existing
                            restaurant.name = name
                            restaurant.address = address
                            restaurant.logoData = logoData // FIX: Persist updated data
                            onSave(restaurant)
                        } else {
                            // Create New
                            let newRestaurant = Restaurant(name: name, address: address)
                            newRestaurant.logoData = logoData // FIX: Persist brand data
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
            }
            .onChange(of: logoItem) { _, _ in
                Task {
                    guard let data = try? await logoItem?.loadTransferable(type: Data.self),
                          let uiImage = UIImage(data: data) else { return }

                    // Process and compress using your custom extension
                    if let resized = uiImage.resized(toWidth: 400),
                       let compressed = resized.jpegData(compressionQuality: 0.7) {
                        await MainActor.run {
                            self.logoData = compressed
                        }
                    }
                }
            }
            .sheet(isPresented: $showNameSearch) {
                SearchSheetView(viewModel: viewModel, isAddressSearch: false) { nameResult, addressResult in
                    self.name = nameResult
                    self.address = addressResult
                }
            }
            .sheet(isPresented: $showAddressSearch) {
                SearchSheetView(viewModel: viewModel, isAddressSearch: true) { _, addressResult in
                    self.address = addressResult
                }
            }
        }
        .withAppBackground()
    }
}
