//
//  msdk_demoApp.swift
//  msdk-demo
//
//  Created by Jing Hao on 12/2/25.
//

import SwiftUI
import SwiftData

@main
struct msdk_demoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // Configure URL scheme handler for Klarna redirects
    init() {
        // Note: With the URL scheme configured in Info.plist via Xcode,
        // the app will automatically handle msdk-demo:// URLs
        print("App initialized with URL scheme support")
    }
    
    private func handleIncomingURL(_ url: URL) {
        print("Received URL: \(url.absoluteString)")
        
        // Handle Klarna redirect URLs
        // Format: msdk-demo://order-confirmation
        if url.scheme == "msdk-demo" {
            if url.host == "order-confirmation" {
                print("Klarna flow completed, returning to order confirmation")
                // The navigation is handled in CheckoutView
            }
        }
    }
}
