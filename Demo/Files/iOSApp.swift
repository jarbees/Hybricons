import SwiftUI

@main
struct HybriconsApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                DemoView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        DemoView()
    }
}
