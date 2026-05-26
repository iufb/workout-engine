import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        RootTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: StoredPreset.self, inMemory: true)
}
