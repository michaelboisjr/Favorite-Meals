import Foundation
import SwiftData

@Model
final class Restaurant {
    // ✅ FIX: Inline default value satisfies CloudKit's schema requirements
    var uuid: UUID = UUID()
    var name: String = ""
    var address: String = ""
    var logoData: Data?
    
    @Relationship(deleteRule: .cascade, inverse: \Meal.restaurant)
    var meals: [Meal]? = nil
    
    init(name: String, address: String) {
        self.name = name
        self.address = address
        // No need to set self.uuid here anymore!
    }
}

@Model
final class Meal {
    // ✅ FIX: Inline default value satisfies CloudKit's schema requirements
    var uuid: UUID = UUID()
    var name: String = ""
    var rating: Int = 0
    var notes: String = ""
    var imageData: Data?
    
    var restaurant: Restaurant?
    
    @Transient
    var restaurantName: String {
        restaurant?.name ?? "No Restaurant"
    }
    
    init(name: String, rating: Int, notes: String, restaurant: Restaurant? = nil) {
        self.name = name
        self.rating = rating
        self.notes = notes
        self.restaurant = restaurant
        // No need to set self.uuid here anymore!
    }
}
