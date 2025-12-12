//
//  KlarnaOSMViewWrapper.swift
//  msdk-demo
//
//  SwiftUI wrapper for Klarna On-Site Messaging (OSM) native view
//

import SwiftUI
import KlarnaMobileSDK
import SafariServices

/// SwiftUI wrapper for KlarnaOSMView
struct KlarnaOSMViewWrapper: UIViewRepresentable {
    let purchaseAmount: Double
    @Binding var height: CGFloat
    
    // Constants for OSM configuration
    private let clientId = "klarna_test_client_Rz9lVUchJChzJTlQU1lTS3g4KClpOUE0ZS9XIXNFOUcsODZiOWMxYzItYTMxYi00OWRjLTk3MzctMjA5ZWRjY2Q2MTEwLDEsc3hyRllrcDFMVmJ5cGRvR3huNm5VVHVBdDlUeEZUaHJDSnMycmRNRlhtRT0"
    private let placementKey = "credit-promotion-badge"
    
    func makeUIView(context: Context) -> KlarnaOSMView {
        let osmView = KlarnaOSMView()
        
        // Configure OSM parameters
        // Note: Using .demo environment avoids URL whitelist restrictions
        // For playground/production, contact Klarna to whitelist specific URLs
        osmView.clientId = clientId
        osmView.placementKey = placementKey
        osmView.locale = "en-US"
        osmView.environment = .demo  // Using demo to bypass URL whitelist restrictions
        osmView.region = .na
        osmView.theme = .automatic
        
        // Convert purchase amount to minor units (cents)
        // $259.00 becomes 25900
        osmView.purchaseAmount = Int(purchaseAmount * 100)
        
        // Set the sizing delegate to handle dynamic height changes
        osmView.sizingDelegate = context.coordinator
        
        // Set host view controller for internal navigation (used by SDK for URL opening)
        osmView.hostViewController = context.coordinator.viewController
        
        // Debug logging
        if let vc = context.coordinator.viewController {
            print("🔵 OSM: hostViewController set to: \(type(of: vc))")
        } else {
            print("⚠️ OSM: hostViewController is nil!")
        }
        
        // Render the OSM view
        print("🔵 OSM: Starting render with amount: \(osmView.purchaseAmount)")
        osmView.render { [weak osmView] error in
            if let error = error {
                print("❌ OSM Render Error: \(error.name) - \(error.message)")
                print("❌ OSM Error details - isFatal: \(error.isFatal)")
                // Set a minimal height on error
                DispatchQueue.main.async {
                    context.coordinator.updateHeight(0)
                }
            } else {
                print("✅ OSM rendered successfully")
            }
        }
        
        return osmView
    }
    
    func updateUIView(_ uiView: KlarnaOSMView, context: Context) {
        // Update the host view controller reference in case it changed
        let topVC = Coordinator.getTopmostViewController()
        context.coordinator.viewController = topVC
        uiView.hostViewController = topVC
        
        if let vc = topVC {
            print("🔄 OSM: Updated hostViewController to: \(type(of: vc))")
        }
        
        // Update purchase amount if changed
        let newAmount = Int(purchaseAmount * 100)
        if uiView.purchaseAmount != newAmount {
            uiView.purchaseAmount = newAmount
            
            // Re-render with updated amount
            uiView.render { error in
                if let error = error {
                    print("❌ OSM Update Error: \(error.name) - \(error.message)")
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(height: $height)
    }
    
    class Coordinator: NSObject, KlarnaSizingDelegate {
        @Binding var height: CGFloat
        weak var viewController: UIViewController?
        
        init(height: Binding<CGFloat>) {
            self._height = height
            super.init()
            
            // Get the topmost view controller for proper modal presentation
            self.viewController = Self.getTopmostViewController()
        }
        
        // KlarnaSizingDelegate method
        func klarnaComponent(_ klarnaComponent: KlarnaComponent, resizedToHeight height: CGFloat) {
            print("🟢 OSM Sizing Delegate called with height: \(height)")
            updateHeight(height)
        }
        
        func updateHeight(_ newHeight: CGFloat) {
            print("🟢 OSM updating height to: \(newHeight)")
            DispatchQueue.main.async {
                self.height = newHeight
            }
        }
        
        // Helper to find the topmost view controller
        static func getTopmostViewController() -> UIViewController? {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                return nil
            }
            
            return findTopViewController(from: rootVC)
        }
        
        static func findTopViewController(from viewController: UIViewController) -> UIViewController {
            if let presented = viewController.presentedViewController {
                return findTopViewController(from: presented)
            }
            
            if let navigationController = viewController as? UINavigationController {
                if let topVC = navigationController.topViewController {
                    return findTopViewController(from: topVC)
                }
            }
            
            if let tabBarController = viewController as? UITabBarController {
                if let selectedVC = tabBarController.selectedViewController {
                    return findTopViewController(from: selectedVC)
                }
            }
            
            return viewController
        }
    }
}

// Preview helper
#if DEBUG
struct KlarnaOSMViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            KlarnaOSMViewWrapper(
                purchaseAmount: 259.00,
                height: .constant(100)
            )
            .frame(height: 100)
        }
        .padding()
    }
}
#endif
