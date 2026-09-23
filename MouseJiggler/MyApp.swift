import SwiftUI

@main
struct MyApp: App {
    @State private var model = JigglerModel()

    var body: some Scene {
        MenuBarExtra(
            "Mouse Jiggler",
            systemImage: model.isRunning ? "cursorarrow.motionlines" : "cursorarrow"
        ) {
            ContentView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
