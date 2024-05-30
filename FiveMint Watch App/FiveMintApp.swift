import SwiftUI

@main
struct FiveMint_Watch_AppApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var delegate: ExtensionDelegate
        // It can be ignored that @WKExtensionDelegateAdaptor should only be used within an extension based process

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
