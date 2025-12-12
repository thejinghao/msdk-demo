//
//  HybridCheckoutView.swift
//  msdk-demo
//
//  Hybrid checkout using WKWebView with Klarna Hybrid SDK
//

import SwiftUI
import WebKit
import KlarnaMobileSDK

struct HybridCheckoutView: View {
    @Environment(\.dismiss) var dismiss
    
    let productName: String
    let productPrice: Double
    let productSKU: String
    
    @State private var navigateToConfirmation = false
    @State private var orderId: String?
    @State private var orderAmount: Double = 0
    @State private var shippingAddress: ShippingAddress?
    @State private var estimatedDelivery: String = "5-7 business days"
    
    var body: some View {
        ZStack {
            HybridWebViewContainer(
                productName: productName,
                productPrice: productPrice,
                productSKU: productSKU,
                onOrderComplete: { id, amount, shipping, delivery in
                    orderId = id
                    orderAmount = amount
                    shippingAddress = shipping
                    estimatedDelivery = delivery
                    navigateToConfirmation = true
                }
            )
            .edgesIgnoringSafeArea(.all)
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            NavigationLink(
                destination: OrderConfirmationView(
                    orderId: orderId ?? "N/A",
                    orderAmount: orderAmount,
                    productName: productName,
                    shippingAddress: shippingAddress ?? ShippingAddress(
                        firstName: "", lastName: "", addressLine1: "",
                        addressLine2: "", city: "", state: "", zipCode: "",
                        country: "", email: ""
                    ),
                    estimatedDelivery: estimatedDelivery
                ),
                isActive: $navigateToConfirmation,
                label: { EmptyView() }
            )
        )
    }
}

// MARK: - WebView Container

struct HybridWebViewContainer: UIViewRepresentable {
    let productName: String
    let productPrice: Double
    let productSKU: String
    let onOrderComplete: (String, Double, ShippingAddress, String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = context.coordinator.createWebView()
        context.coordinator.loadCheckoutPage()
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            productName: productName,
            productPrice: productPrice,
            productSKU: productSKU,
            onOrderComplete: onOrderComplete
        )
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, KlarnaEventHandler {
        let productName: String
        let productPrice: Double
        let productSKU: String
        let onOrderComplete: (String, Double, ShippingAddress, String) -> Void
        
        private var webView: WKWebView!
        private var hybridSDK: KlarnaHybridSDK!
        private let klarnaService = KlarnaService.makeDefaultService()
        private var currentClientToken: String?
        private var isPageLoaded = false
        
        init(productName: String, productPrice: Double, productSKU: String,
             onOrderComplete: @escaping (String, Double, ShippingAddress, String) -> Void) {
            self.productName = productName
            self.productPrice = productPrice
            self.productSKU = productSKU
            self.onOrderComplete = onOrderComplete
            super.init()
        }
        
        func createWebView() -> WKWebView {
            // Configure WKWebView with message handler
            let configuration = WKWebViewConfiguration()
            configuration.userContentController.add(self, name: "klarnaApp")
            
            // Enable JavaScript
            let preferences = WKWebpagePreferences()
            preferences.allowsContentJavaScript = true
            configuration.defaultWebpagePreferences = preferences
            
            // Create WebView
            webView = WKWebView(frame: .zero, configuration: configuration)
            webView.navigationDelegate = self
            webView.scrollView.contentInsetAdjustmentBehavior = .never
            
            // Initialize Klarna Hybrid SDK
            let returnURL = URL(string: "msdk-demo://order-confirmation")!
            hybridSDK = KlarnaHybridSDK(returnUrl: returnURL, klarnaEventHandler: self)
            hybridSDK.loggingLevel = .verbose
            
            // Add webView to hybrid SDK
            hybridSDK.addWebView(webView)
            
            return webView
        }
        
        func loadCheckoutPage() {
            // Try multiple ways to load the HTML file
            
            // Method 1: Try from WebContent subdirectory
            if let htmlPath = Bundle.main.path(forResource: "hybrid-checkout", ofType: "html", inDirectory: "WebContent") {
                print("Found HTML at path: \(htmlPath)")
                if let htmlContent = try? String(contentsOfFile: htmlPath, encoding: .utf8) {
                    print("Loaded HTML content, length: \(htmlContent.count)")
                    // Use HTTPS base URL to allow loading external resources (Klarna CDN)
                    let baseURL = URL(string: "https://x.klarnacdn.net/")!
                    webView.loadHTMLString(htmlContent, baseURL: baseURL)
                    return
                }
            }
            
            // Method 2: Try from main bundle root
            if let htmlPath = Bundle.main.path(forResource: "hybrid-checkout", ofType: "html") {
                print("Found HTML at root path: \(htmlPath)")
                if let htmlContent = try? String(contentsOfFile: htmlPath, encoding: .utf8) {
                    print("Loaded HTML content from root, length: \(htmlContent.count)")
                    let baseURL = URL(string: "https://x.klarnacdn.net/")!
                    webView.loadHTMLString(htmlContent, baseURL: baseURL)
                    return
                }
            }
            
            // Method 3: Try loading URL directly if file is in bundle
            if let htmlURL = Bundle.main.url(forResource: "hybrid-checkout", withExtension: "html", subdirectory: "WebContent") {
                print("Found HTML URL: \(htmlURL)")
                webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
                return
            }
            
            print("Error: Could not load hybrid-checkout.html from any location")
            print("Available paths in bundle:")
            if let resourcePath = Bundle.main.resourcePath {
                print("Resource path: \(resourcePath)")
            }
            
            // Fallback: Load a simple test HTML to verify WebView works
            let fallbackHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Loading Error</title>
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                        padding: 20px;
                        text-align: center;
                    }
                    .error {
                        color: #ff3b30;
                        margin-top: 40px;
                    }
                </style>
            </head>
            <body>
                <h1 class="error">Failed to Load Checkout</h1>
                <p>The hybrid-checkout.html file could not be found in the app bundle.</p>
                <p>Please ensure the WebContent folder is added to the target's Copy Bundle Resources.</p>
                <button onclick="notifyNative()">Retry</button>
                <script>
                    function notifyNative() {
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.klarnaApp) {
                            window.webkit.messageHandlers.klarnaApp.postMessage({
                                action: 'error',
                                message: 'HTML file not found in bundle'
                            });
                        }
                    }
                </script>
            </body>
            </html>
            """
            let baseURL = URL(string: "https://x.klarnacdn.net/")!
            webView.loadHTMLString(fallbackHTML, baseURL: baseURL)
        }
        
        // MARK: - WKNavigationDelegate (Required for Hybrid SDK)
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Notify hybrid SDK before navigation (required per docs)
            let shouldFollow = hybridSDK.shouldFollowNavigation(withRequest: navigationAction.request)
            decisionHandler(shouldFollow ? .allow : .cancel)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // Notify hybrid SDK after navigation starts (required per docs)
            hybridSDK.newPageLoad(in: webView)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView finished loading")
            isPageLoaded = true
            // Page is now ready to receive messages from JavaScript
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView navigation failed: \(error.localizedDescription)")
        }
        
        // MARK: - WKScriptMessageHandler (JavaScript Bridge)
        
        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "klarnaApp",
                  let body = message.body as? [String: Any],
                  let action = body["action"] as? String else {
                print("Invalid message received from web")
                return
            }
            
            print("Received message from web: \(action)")
            
            switch action {
            case "createSession":
                handleCreateSession(data: body["data"] as? [String: Any])
                
            case "createOrder":
                handleCreateOrder(
                    authToken: body["authorizationToken"] as? String,
                    orderData: body["orderData"] as? [String: Any],
                    shippingInfo: body["shippingInfo"] as? [String: Any]
                )
                
            case "error":
                if let errorMessage = body["message"] as? String {
                    print("Error from web: \(errorMessage)")
                    sendErrorToWeb(errorMessage)
                }
                
            default:
                print("Unknown action: \(action)")
            }
        }
        
        // MARK: - Session Creation
        
        private func handleCreateSession(data: [String: Any]?) {
            print("Creating Klarna session...")
            
            Task {
                do {
                    let sessionRequest = makeSessionRequest()
                    let response = try await klarnaService.createSession(request: sessionRequest)
                    
                    await MainActor.run {
                        currentClientToken = response.clientToken
                        print("Session created, client token: \(response.clientToken.prefix(20))...")
                        
                        guard isPageLoaded else {
                            print("Page not loaded yet, cannot inject client token")
                            return
                        }
                        
                        // Inject client token into web page
                        let jsCode = "if (typeof setClientToken === 'function') { setClientToken('\(response.clientToken)'); }"
                        webView.evaluateJavaScript(jsCode) { result, error in
                            if let error = error {
                                print("Error injecting client token: \(error.localizedDescription)")
                            } else {
                                print("Client token injected successfully")
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        print("Session creation error: \(error.localizedDescription)")
                        sendErrorToWeb("Failed to create session: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        private func makeSessionRequest() -> SessionRequest {
            // Simple session with just the product price
            let productPriceInMinorUnits = Int(productPrice * 100)
            
            let productLine = OrderLine(
                type: "physical",
                reference: productSKU,
                name: productName,
                quantity: 1,
                quantityUnit: "pcs",
                unitPrice: productPriceInMinorUnits,
                taxRate: 0,
                totalAmount: productPriceInMinorUnits,
                totalTaxAmount: 0
            )
            
            return SessionRequest(
                purchaseCountry: "US",
                purchaseCurrency: "USD",
                locale: "en-US",
                orderAmount: productPriceInMinorUnits,
                orderTaxAmount: 0,
                orderLines: [productLine],
                intent: "buy"
            )
        }
        
        // MARK: - Order Creation
        
        private func handleCreateOrder(authToken: String?, orderData: [String: Any]?,
                                       shippingInfo: [String: Any]?) {
            guard let token = authToken else {
                sendErrorToWeb("Missing authorization token")
                return
            }
            
            guard let orderData = orderData else {
                sendErrorToWeb("Missing order data")
                return
            }
            
            print("Creating order with auth token: \(token.prefix(20))...")
            
            Task {
                do {
                    let orderRequest = parseOrderRequest(from: orderData)
                    let response = try await klarnaService.createOrder(
                        authorizationToken: token,
                        request: orderRequest
                    )
                    
                    await MainActor.run {
                        print("Order created successfully: \(response.orderId)")
                        
                        // Parse shipping info
                        let shipping = parseShippingAddress(from: shippingInfo)
                        let totalAmount = Double(orderRequest.orderAmount) / 100.0
                        let delivery = calculateEstimatedDelivery(from: orderData)
                        
                        // Navigate to confirmation
                        onOrderComplete(response.orderId, totalAmount, shipping, delivery)
                    }
                } catch {
                    await MainActor.run {
                        print("Order creation error: \(error.localizedDescription)")
                        sendErrorToWeb("Failed to create order: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        private func parseOrderRequest(from data: [String: Any]) -> OrderRequest {
            let purchaseCountry = data["purchase_country"] as? String ?? "US"
            let purchaseCurrency = data["purchase_currency"] as? String ?? "USD"
            let locale = data["locale"] as? String ?? "en-US"
            let orderAmount = data["order_amount"] as? Int ?? 0
            let orderTaxAmount = data["order_tax_amount"] as? Int ?? 0
            
            var orderLines: [OrderLine] = []
            if let lines = data["order_lines"] as? [[String: Any]] {
                orderLines = lines.compactMap { parseOrderLine(from: $0) }
            }
            
            return OrderRequest(
                purchaseCountry: purchaseCountry,
                purchaseCurrency: purchaseCurrency,
                locale: locale,
                orderAmount: orderAmount,
                orderTaxAmount: orderTaxAmount,
                orderLines: orderLines,
                merchantReference1: "hybrid-\(UUID().uuidString.prefix(8))"
            )
        }
        
        private func parseOrderLine(from data: [String: Any]) -> OrderLine? {
            guard let type = data["type"] as? String,
                  let reference = data["reference"] as? String,
                  let name = data["name"] as? String,
                  let quantity = data["quantity"] as? Int,
                  let quantityUnit = data["quantity_unit"] as? String,
                  let unitPrice = data["unit_price"] as? Int,
                  let taxRate = data["tax_rate"] as? Int,
                  let totalAmount = data["total_amount"] as? Int,
                  let totalTaxAmount = data["total_tax_amount"] as? Int else {
                return nil
            }
            
            return OrderLine(
                type: type,
                reference: reference,
                name: name,
                quantity: quantity,
                quantityUnit: quantityUnit,
                unitPrice: unitPrice,
                taxRate: taxRate,
                totalAmount: totalAmount,
                totalTaxAmount: totalTaxAmount
            )
        }
        
        private func parseShippingAddress(from data: [String: Any]?) -> ShippingAddress {
            guard let data = data else {
                return ShippingAddress(
                    firstName: "John", lastName: "Doe",
                    addressLine1: "123 Main St", addressLine2: "",
                    city: "San Francisco", state: "CA",
                    zipCode: "94102", country: "United States",
                    email: "customer@email.us"
                )
            }
            
            return ShippingAddress(
                firstName: data["firstName"] as? String ?? "",
                lastName: data["lastName"] as? String ?? "",
                addressLine1: data["addressLine1"] as? String ?? "",
                addressLine2: data["addressLine2"] as? String ?? "",
                city: data["city"] as? String ?? "",
                state: data["state"] as? String ?? "",
                zipCode: data["zipCode"] as? String ?? "",
                country: data["country"] as? String ?? "",
                email: data["email"] as? String ?? ""
            )
        }
        
        private func calculateEstimatedDelivery(from orderData: [String: Any]) -> String {
            // Try to extract shipping method from order lines
            if let lines = orderData["order_lines"] as? [[String: Any]] {
                for line in lines {
                    if line["type"] as? String == "shipping_fee" {
                        let name = line["name"] as? String ?? ""
                        if name.contains("Express") {
                            return "2-3 business days"
                        } else if name.contains("Overnight") {
                            return "next business day"
                        }
                    }
                }
            }
            return "5-7 business days"
        }
        
        // MARK: - JavaScript Communication
        
        private func sendErrorToWeb(_ message: String) {
            guard isPageLoaded else {
                print("Cannot send error to web - page not loaded yet: \(message)")
                return
            }
            
            let escapedMessage = message.replacingOccurrences(of: "'", with: "\\'")
                                       .replacingOccurrences(of: "\n", with: "\\n")
            let jsCode = "if (typeof handleError === 'function') { handleError('\(escapedMessage)'); }"
            webView.evaluateJavaScript(jsCode) { _, error in
                if let error = error {
                    print("Error sending error to web: \(error.localizedDescription)")
                }
            }
        }
        
        // MARK: - KlarnaEventHandler (Required for Hybrid SDK)
        
        func klarnaComponent(_ klarnaComponent: KlarnaComponent, dispatchedEvent event: KlarnaProductEvent) {
            print("Klarna event dispatched: \(event)")
        }
        
        func klarnaComponent(_ klarnaComponent: KlarnaComponent, encounteredError error: KlarnaError) {
            print("Klarna error encountered: \(error.name) - \(error.message)")
            DispatchQueue.main.async {
                self.sendErrorToWeb("Klarna error: \(error.message)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        HybridCheckoutView(
            productName: "Classic T-Shirt",
            productPrice: 259.00,
            productSKU: "SKU-123"
        )
    }
}
