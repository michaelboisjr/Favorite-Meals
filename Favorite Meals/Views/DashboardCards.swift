import SwiftUI
import SwiftData

// MARK: - Star Rating View
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

// MARK: - Featured Meal Card
struct FeaturedCardView: View {
    let meal: Meal
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            if let data = meal.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Theme.Colors.fields)
                    .frame(height: 200)
            }
            
            // Text Overlay Gradient
            LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .top)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
                Text(meal.restaurant?.name ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Standard Meal Card
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
                    .foregroundStyle(.primary) // Override NavigationLink accent color
                
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

// MARK: - Grid Layout for Sorted Meals
struct MealListView: View {
    @Environment(\.modelContext) private var modelContext // 👈 Add context
    @Query private var meals: [Meal]
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    init(sortOrder: [SortDescriptor<Meal>]) {
        _meals = Query(sort: sortOrder)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(meals) { meal in
                NavigationLink(destination: MealDetailView(meal: meal)) {
                    MealCardView(meal: meal)
                }
                .buttonStyle(ScalableButtonStyle())
                // ⬇️ ADD THE CONTEXT MENU HERE
                .contextMenu {
                    Button(role: .destructive) {
                        deleteMeal(meal)
                    } label: {
                        Label("Delete Meal", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // ⬇️ ADD THE DELETION LOGIC
    private func deleteMeal(_ meal: Meal) {
        // Capture the restaurant reference before deleting the meal
        let associatedRestaurant = meal.restaurant
        
        // Remove the meal from disk storage
        modelContext.delete(meal)
        
        // Optional Cleanup: If the restaurant now has zero meals left, delete it too
        if let restaurant = associatedRestaurant {
            // Check if this was the last meal for this restaurant
            if (restaurant.meals?.count ?? 0) <= 1 {
                modelContext.delete(restaurant)
            }
        }
        
        // Save the changes explicitly (or let SwiftData auto-save handle it)
        try? modelContext.save()
    }
}
