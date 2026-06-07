import SwiftUI

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
                    .clipped()
            } else {
                Rectangle().fill(Theme.Colors.fields).frame(height: 200)
            }
            
            // Text Overlay
            LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .top)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name).font(.title2).bold().foregroundStyle(.white)
                Text(meal.restaurant?.name ?? "").font(.subheadline).foregroundStyle(.white.opacity(0.8))
            }
            .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
