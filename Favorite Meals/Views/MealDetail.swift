import SwiftUI
import SwiftData

struct MealDetailView: View {
    var meal: Meal
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Hero Image Header
                if let data = meal.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                        .overlay(LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                }

                VStack(alignment: .leading, spacing: 20) {
                    // 2. Title & Rating Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(meal.name)
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        StarRatingView(rating: meal.rating)
                    }

                    // 3. Info Cards
                    InfoCard(title: "Restaurant", content: meal.restaurant?.name ?? "Unknown")
                    
                    if let restaurant = meal.restaurant {
                        RestaurantMiniMap(restaurantName: restaurant.name, address: restaurant.address)
                    }

                    InfoCard(title: "Notes", content: meal.notes.isEmpty ? "No notes added." : meal.notes)
                }
                .padding()
            }
        }
        .withAppBackground()
        .ignoresSafeArea(edges: .top) // Extends image into the nav bar
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEditSheet = true }
                    .buttonStyle(.borderedProminent)
                    .clipShape(Capsule())
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddMealView(mealToEdit: meal)
        }
    }
}

// Reusable clean info card
struct InfoCard: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).bold().foregroundStyle(.secondary)
            Text(content).font(.body).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.Colors.fields)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
