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
    
    // Compute the top meal
    private var topMeal: Meal? {
        meals.sorted(by: { $0.rating > $1.rating }).first
    }
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Featured Section
                    if let meal = topMeal {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Featured Favorite").font(.headline).foregroundStyle(.secondary)
                            NavigationLink(destination: MealDetailView(meal: meal)) {
                                FeaturedCardView(meal: meal)
                            }
                            .buttonStyle(ScalableButtonStyle()) // Apply here
                        }
                        .padding(.horizontal)
                    }
                    
                    // All Meals Grid
                    Text("All Meals").font(.headline).foregroundStyle(.secondary).padding(.horizontal)
                    MealListView(sortOrder: sortOrder)
                }// 👈 This is the closing bracket of VStack
                .padding(.top)
            }// 👈 This is the closing bracket of ScrollView
            .withAppBackground()
            .navigationTitle("Favorite Meals")
            // MODERN DESIGN: Frosted glass effect
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
                            SortDescriptor(\Meal.restaurant?.name),
                            SortDescriptor(\Meal.name) // This ensures meals within the same restaurant are alphabetical
                        ])
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showOptions = true }) {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                    .confirmationDialog("Add New", isPresented: $showOptions) {
                        Button("Add Meal") { showingAddMeal = true }
                        Button("Add Restaurant") { showingAddRestaurant = true }
                    }
                }
            }// 👈 This is the closing bracket of .toolbar

            .sheet(isPresented: $showingAddMeal) { AddMealView() }
            .sheet(isPresented: $showingAddRestaurant) {
                AddRestaurantView(onSave: { _ in })
            }
            
        }// 👈 This is the closing bracket of Navigation Stack
    }// 👈 This is the closing bracket of some View
    
}// 👈 This is the closing bracket of Struct

