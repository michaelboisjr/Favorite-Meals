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
    @Query private var meals: [Meal]
    
    // Responsive grid: 2 columns
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    init(sortOrder: [SortDescriptor<Meal>]) {
        // Dynamically inject the sort descriptor configuration array
        _meals = Query(sort: sortOrder)
    }
    
    var body: some View {
        // FIX: ScrollView wrapper removed so it leverages DashboardView's scroll hierarchy
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(meals) { meal in
                NavigationLink(destination: MealDetailView(meal: meal)) {
                    MealCardView(meal: meal)
                }
                .buttonStyle(ScalableButtonStyle())
            }
        }
        .padding(.horizontal)
    }
}
