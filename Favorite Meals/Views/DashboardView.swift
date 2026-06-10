import SwiftData
import SwiftUI
import CloudKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.name) private var meals: [Meal]
    
    // State for controlling the dialog and the two sheets
    @State private var showOptions = false
    @State private var showingAddMeal = false
    @State private var showingAddRestaurant = false
    
    // State for sorting
    @State private var sortOrder: [SortDescriptor<Meal>] = [SortDescriptor(\Meal.name)]
    
    // 2. Share state tracking variables
    @State private var activeShare: CKShare?
    @State private var activeContainer: CKContainer?
    @State private var isShowingShareSheet = false
    @State private var isLoadingShare = false
    
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
                            .buttonStyle(ScalableButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    
                    // All Meals Grid
                    Text("All Meals").font(.headline).foregroundStyle(.secondary).padding(.horizontal)
                    MealListView(sortOrder: sortOrder)
                }
                .padding(.top)
            }
            .withAppBackground()
            .navigationTitle("Favorite Meals")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Sort", selection: $sortOrder) {
                        Text("Name").tag([SortDescriptor(\Meal.name)])
                        
                        Text("Rating").tag([
                            SortDescriptor(\Meal.rating, order: .reverse),
                            SortDescriptor(\Meal.name)
                        ])
                        
                        Text("Restaurant").tag([
                            SortDescriptor(\Meal.restaurant?.name),
                            SortDescriptor(\Meal.name)
                        ])
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showOptions = true }) {
                        // Show a loading spinner right on the toolbar icon if processing a share
                        if isLoadingShare {
                            ProgressView()
                        } else {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }
                    }
                    .disabled(isLoadingShare)
                    .confirmationDialog("Add New", isPresented: $showOptions) {
                        Button("Add Meal") { showingAddMeal = true }
                        Button("Add Restaurant") { showingAddRestaurant = true }
                        
                        // FIX: Dialogue buttons must be simple string titles
                        Button("Share Feed with Friends") {
                            initiateFeedShare()
                        }
                        .disabled(meals.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let share = activeShare, let container = activeContainer {
                    CloudKitShareRepresentable(share: share, container: container)
                        .presentationDetents([.medium, .large])
                }
            }
            .sheet(isPresented: $showingAddMeal) { AddMealView() }
            .sheet(isPresented: $showingAddRestaurant) {
                AddRestaurantView(onSave: { _ in })
            }
        }
    } // 👈 Closing bracket of 'some View'
    
    // FIX: This sharing logic has been moved inside the struct boundary scope
    /// Collects the target data payload and requests a secure invitation link
    private func initiateFeedShare() {
        guard let primaryMealToShare = meals.first else { return }
        
        isLoadingShare = true
        
        Task {
            // Fetch structural data container details from our shared state system
            let coordinator = CloudDataCoordinator.shared
            
            let manager = CloudKitShareManager(
                modelContext: modelContext,
                persistentContainer: coordinator.persistentContainer
            )
            
            do {
                let (share, container) = try await manager.getOrCreateShare(for: primaryMealToShare)
                
                self.activeShare = share
                self.activeContainer = container
                self.isShowingShareSheet = true
            } catch {
                print("❌ Failed to initiate sharing loop from toolbar: \(error)")
            }
            
            isLoadingShare = false
        }
    }

} // 👈 Closing bracket of 'DashboardView' struct
