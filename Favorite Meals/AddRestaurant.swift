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
                Section("Restaurant Details") {

                    // 1. Name Field
                    ZStack(alignment: .leading) {
                        TextField("Restaurant Name", text: $name)
                            .disabled(true)  // Disable typing, we want to force the search

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

                }  // 👈 This is the end of Section Restaurant Details
                .withListRow()

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
            }  // 👈 This is the end of Form
            .navigationTitle(
                restaurantToEdit == nil ? "New Restaurant" : "Edit Restaurant"
            )
            .navigationBarTitleDisplayMode(.inline)
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

            .sheet(isPresented: $showNameSearch) {
                SearchSheetView(viewModel: viewModel, isAddressSearch: false) {
                    nameResult,
                    addressResult in
                    self.name = nameResult
                    self.address = addressResult
                }
            }
            .sheet(isPresented: $showAddressSearch) {
                SearchSheetView(viewModel: viewModel, isAddressSearch: true) {
                    _,
                    addressResult in
                    self.address = addressResult
                }
            }

            //End of options for Form
        }  // 👈 This is the end of Navigation stack
        .withAppBackground()
    }  // 👈 This is the end of View
}  // 👈 This is the end of Struct
