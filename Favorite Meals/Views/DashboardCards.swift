//file name: DashboardCards

import SwiftUI
import SwiftData
import Combine

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
    @Environment(\.modelContext) private var modelContext
    @Query private var meals: [Meal]
    @State private var refreshID = UUID()
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    init(sortOrder: [SortDescriptor<Meal>]) {
        _meals = Query(sort: sortOrder)
    }
    
    var body: some View {
        ScrollView { // Added wrapper to cleanly hold modifiers outside the loop
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(meals) { meal in
                    NavigationLink(destination: MealDetailView(meal: meal)) {
                        MealCardView(meal: meal)
                    }
                    .buttonStyle(ScalableButtonStyle())
                    .contextMenu {
                        // 🎯 NEW: Native Share Action Sheet Trigger
                        Button {
                            triggerShareSheet(for: meal)
                        } label: {
                            Label("Share Meal", systemImage: "person.badge.plus")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            deleteMeal(meal)
                        } label: {
                            Label("Delete Meal", systemImage: "trash")
                        }
                    }
                    .id(refreshID)
                }
            }
            .padding(.horizontal)
            // 🛠️ PERFORMANCE FIX: Modifiers moved out of the ForEach loop to prevent rapid-fire multiplication
            .navigationTitle("Favorite Meals")
            .onReceive(
                NotificationCenter.default
                    .publisher(for: NSNotification.Name("NSPersistentStoreRemoteChangeNotification"))
                    .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            ) { _ in
                refreshUILayout()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CloudKitShareAcceptanceSuccess"))) { _ in
                print("🏁 UI caught successful handshake notification! Forcing final data reveal...")
                refreshUILayout()
            }
        }
    }
    
    /// Finds the window view controller and prompts the Core Data bridge to present the system share sheet
    private func triggerShareSheet(for meal: Meal) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            print("⚠️ Could not locate root UIViewController hierarchy.")
            return
        }
        
        // ✅ FIXED: Using 'meal.uuid' instead of the system 'id'
        CloudKitShareManager.shared.presentShareSheet(
            for: meal.uuid,
            entityName: "Meal",
            from: rootVC
        )
    }
    
    private func deleteMeal(_ meal: Meal) {
        let associatedRestaurant = meal.restaurant
        modelContext.delete(meal)
        
        if let restaurant = associatedRestaurant {
            if (restaurant.meals?.count ?? 0) <= 1 {
                modelContext.delete(restaurant)
            }
        }
        try? modelContext.save()
    }
    
    private func refreshUILayout() {
        Task { @MainActor in
            print("🔄 Thread-safe UI refresh initialized...")
            modelContext.container.mainContext.processPendingChanges()
            withAnimation(.easeInOut) {
                refreshID = UUID()
            }
        }
    }
}
