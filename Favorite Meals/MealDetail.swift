import SwiftUI
import SwiftData

struct MealDetailView: View {
    var meal: Meal
    @State private var showingEditSheet = false

    var body: some View {
        Form {
            Section {
                if let data = meal.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.vertical, 5) // Adds breathing room
                } else {
                    // Optional: Show a placeholder if no image exists
                    ContentUnavailableView("No Photo", systemImage: "photo", description: Text("Add a photo in edit mode."))
                        .foregroundStyle(.secondary)
                }
            }
            .withListRow()
            
            Section("Details") {
                            // Use Text to display data, not TextField
                            LabeledContent("Name", value: meal.name)
                            LabeledContent("Rating", value: "\(meal.rating)")
                            LabeledContent("Notes", value: meal.notes)
                        }
            .withListRow()
            
            if let restaurant = meal.restaurant {
                Section("Restaurant") {
                    Text(restaurant.name).font(.headline)
                    Text(restaurant.address).font(.subheadline)
                }
                .withListRow()
            }
            
        }
        .withAppBackground()

        .navigationTitle(meal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") {
                            showingEditSheet = true
                        }
                    }
                }
        .sheet(isPresented: $showingEditSheet) {
                    AddMealView(mealToEdit: meal)
                }
    }
}
