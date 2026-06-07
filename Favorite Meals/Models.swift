import Foundation
import SwiftData

@Model
final class Restaurant {
    var name: String = ""
    var address: String = ""
    var logoData: Data?
    
    // Always keep as a non-optional array
    @Relationship(deleteRule: .cascade, inverse: \Meal.restaurant)
    var meals: [Meal]? = nil // Changed from [Meal] = [] to [Meal]? = nil
    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}

@Model
final class Meal {
    var name: String = ""
    var rating: Int = 0
    var notes: String = ""
    var imageData: Data?
    
    var restaurant: Restaurant?
    
    // Computed property avoids data synchronization bugs
    @Transient
    var restaurantName: String {
        restaurant?.name ?? "No Restaurant"
    }
    
    // Updated initializer to include the relationship
    init(name: String, rating: Int, notes: String, restaurant: Restaurant? = nil) {
        self.name = name
        self.rating = rating
        self.notes = notes
        self.restaurant = restaurant
    }
}
