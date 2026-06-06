import Foundation
import SwiftData

@Model
final class Restaurant {
    var name: String = ""
    var address: String = ""
    var logoData: Data?
    
    // Change the relationship to be optional by default
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
    
    // Ensure the inverse relationship is also optional
    var restaurant: Restaurant? = nil
    
    var restaurantName: String = "No Restaurant"
    
    init(name: String, rating: Int, notes: String) {
        self.name = name
        self.rating = rating
        self.notes = notes
    }
}
