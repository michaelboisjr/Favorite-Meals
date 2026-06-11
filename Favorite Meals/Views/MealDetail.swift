import SwiftUI
import SwiftData
import CloudKit

struct MealDetailView: View {
    @Environment(\.modelContext) private var modelContext
    var meal: Meal
    @State private var showingEditSheet = false
    
    // Sharing Presentation States
    @State private var activeShare: CKShare?
    @State private var activeContainer: CKContainer?
    @State private var isPresentingShareSheet = false
    @State private var isProcessingShare = false
    
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
            ToolbarItem(placement: .primaryAction) {
                Button {
                    generateCloudKitInvite()
                } label: {
                    if isProcessingShare {
                        ProgressView()
                    } else {
                        Image(systemName: "person.badge.plus")
                    }
                }
                .disabled(isProcessingShare)
            }
        } //End of .toolbar
        .sheet(isPresented: $showingEditSheet) {
            AddMealView(mealToEdit: meal)
        }
        .sheet(isPresented: $isPresentingShareSheet) {
            if let share = activeShare, let container = activeContainer {
                CloudShareView(share: share, container: container)
                    .ignoresSafeArea()
            }
        }
    }
    // Run the background extraction worker safely
        private func generateCloudKitInvite() {
            isProcessingShare = true
            
            Task {
                do {
                    let (share, container) = try await modelContext.fetchOrCreateShare(for: meal)
                    await MainActor.run {
                        self.activeShare = share
                        self.activeContainer = container
                        self.isProcessingShare = false
                        self.isPresentingShareSheet = true
                    }
                } catch {
                    print("Failed to initialize CloudKit Share Reference: \(error.localizedDescription)")
                    await MainActor.run {
                        self.isProcessingShare = false
                    }
                }
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
