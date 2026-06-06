import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.name) private var meals: [Meal]

    //State for controlling the dialog and the two sheets
    @State private var showOptions = false
    @State private var showingAddMeal = false
    @State private var showingAddRestaurant = false

    //State for sorting
    @State private var sortOrder: [SortDescriptor<Meal>] = [SortDescriptor(\Meal.name)]

    var body: some View {
        NavigationStack {
            // 2. Use the new MealListView and pass the sortOrder
            MealListView(sortOrder: sortOrder)
                .navigationTitle("Favorite Meals")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        // 3. Sorting Picker
                        Picker("Sort", selection: $sortOrder) {
                            Text("Name").tag([SortDescriptor(\Meal.name)])
                            
                            Text("Rating").tag([
                                SortDescriptor(\Meal.rating, order: .reverse),
                                SortDescriptor(\Meal.name) // Secondary sort
                            ])
                            
                            Text("Restaurant").tag([
                                SortDescriptor(\Meal.restaurantName),
                                SortDescriptor(\Meal.name) // This ensures meals within the same restaurant are alphabetical
                            ])
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showOptions = true }) {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }
                    }
                }
                .confirmationDialog("Add New", isPresented: $showOptions) {
                    Button("Add Meal") { showingAddMeal = true }
                    Button("Add Restaurant") { showingAddRestaurant = true }
                }
                .sheet(isPresented: $showingAddMeal) { AddMealView() }
                .sheet(isPresented: $showingAddRestaurant) {
                    AddRestaurantView(onSave: { _ in })
                }
        }
    }
    
}

// Sub-component for a consistent Card look
struct MealCardView: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image Section
            ZStack {
                if let data = meal.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    // Refined Placeholder UI
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.fields)
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Text Section
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(meal.restaurant?.name ?? "No Restaurant")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                StarRatingView(rating: meal.rating)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Theme.Colors.fields)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Sub-component for star rating
struct StarRatingView: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(
                        index <= rating ? Theme.Colors.accent : .gray.opacity(0.5)
                    )
            }
        }
    }
}

//Grid layout for sorted meals
struct MealListView: View {
    @Query private var meals: [Meal]
    // Responsive grid: 2 columns
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    init(sortOrder: [SortDescriptor<Meal>]) {
        // The _meals property wrapper allows us to dynamically inject the sort order
        _meals = Query(sort: sortOrder)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(meals) { meal in
                    NavigationLink(destination: MealDetailView(meal: meal)) {
                        MealCardView(meal: meal)
                    }
                }
            }
            .padding()
        }
        .withAppBackground()
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: Item.self, inMemory: true)
}
