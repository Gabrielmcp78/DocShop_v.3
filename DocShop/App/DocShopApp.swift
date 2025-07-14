import SwiftUI

@main
struct DocShopApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
            
                Color.clear // fallback for unsupported OS
                    .background(.ultraThinMaterial)
                ContentView()
            }
        }
    }
}
