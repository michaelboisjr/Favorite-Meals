import SwiftData
import SwiftUI

struct AddMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // The meal we are editing (if any)
    var mealToEdit: Meal?

    // Meal State
    @State private var name: String = ""
    @State private var rating: Int = 3
    @State private var notes: String = ""
    @State private var selectedRestaurant: Restaurant?
    @State private var restaurantName: String = ""

    // Photo Selection State
    @State private var mealImageData: Data?
    
    //ImagePicker State
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showPhotoOptions = false

    @Query(sort: \Restaurant.name) private var restaurants: [Restaurant]
    @State private var showingAddRestaurant = false
    @State private var searchText = ""

    // Initialize with existing data if present
    init(mealToEdit: Meal? = nil) {
        self.mealToEdit = mealToEdit
        _name = State(initialValue: mealToEdit?.name ?? "")
        _rating = State(initialValue: mealToEdit?.rating ?? 3)
        _notes = State(initialValue: mealToEdit?.notes ?? "")
        _selectedRestaurant = State(initialValue: mealToEdit?.restaurant)
        _mealImageData = State(initialValue: mealToEdit?.imageData)
    }

    var filteredRestaurants: [Restaurant] {
        if searchText.isEmpty {
            return restaurants
        } else {
            return restaurants.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    Section("Photo") {
                        Button {
                            showPhotoOptions = true
                        } label: {
                            ZStack {
                                if let data = mealImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Theme.Colors.fields)
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                    
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                        Text("Add Photo")
                                            .font(.headline)
                                    }
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .withListRow()
                }
                .withListRow()

                Section("Meal Details") {
                    TextField("Food Name", text: $name)
                    Picker("Rating", selection: $rating) {
                        ForEach(1...5, id: \.self) { Text("\($0)").tag($0) }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                }
                .withListRow()

                Section("Restaurant") {
                    Picker("Select Restaurant", selection: $selectedRestaurant) {
                        Text("Select a restaurant").tag(nil as Restaurant?)
                        ForEach(filteredRestaurants) { restaurant in
                            Text(restaurant.name).tag(restaurant as Restaurant?)
                        }
                    }
                    
                    // Dynamic Button
                    Button(selectedRestaurant == nil ? "Add New Restaurant" : "Edit Restaurant") {
                        showingAddRestaurant = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue) // Make it look like a tappable link
                }
                .withListRow()
            }  // 👈 This is the closing bracket of Form
            .navigationTitle(mealToEdit == nil ? "New Meal" : "Edit Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let meal = mealToEdit {
                            // Apply "Draft" to the original object
                            meal.name = name
                            meal.rating = rating
                            meal.notes = notes
                            meal.restaurant = selectedRestaurant
                            meal.imageData = mealImageData
                        } else {
                            // Create new object
                            let newMeal = Meal(
                                name: name,
                                rating: rating,
                                notes: notes
                            )
                            newMeal.restaurant = selectedRestaurant
                            newMeal.imageData = mealImageData
                            modelContext.insert(newMeal)
                        }
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                Button("Camera") {
                    sourceType = .camera
                    showImagePicker = true
                }
                Button("Photo Library") {
                    sourceType = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: sourceType, selectedImage: Binding(
                    get: { nil },
                    set: { newImage in
                        // Move your resizing/compression logic here
                        if let uiImage = newImage {
                            // Assuming you have your .resized() extension available
                            if let resizedImage = uiImage.resized(toWidth: 800),
                               let compressedData = resizedImage.jpegData(compressionQuality: 0.8) {
                                self.mealImageData = compressedData
                            } else {
                                // Fallback if resizing fails
                                self.mealImageData = uiImage.jpegData(compressionQuality: 0.8)
                            }
                        }
                    }
                ))
            }
            .sheet(isPresented: $showingAddRestaurant) {
                // Pass the currently selected restaurant into the editor
                AddRestaurantView(restaurantToEdit: selectedRestaurant) { updatedRestaurant in
                    self.selectedRestaurant = updatedRestaurant
                    // Ensure the denormalized name is updated
                    self.restaurantName = updatedRestaurant.name
                }
            }
            .withAppBackground()
        }  // 👈 This is the closing bracket of Navigation Stack
        .onChange(of: selectedRestaurant) {
            self.restaurantName = selectedRestaurant?.name ?? "No Restaurant"
        }
    }  // 👈 This is the closing bracket of SomeView
}  // 👈 This is the closing bracket of Struct
