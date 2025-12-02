//
//  KlarnaPaymentContainerView.swift
//  msdk-demo
//
//  Direct Klarna Playground API integration view
//

import SwiftUI

struct KlarnaPaymentContainerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isCreatingSession = false
    @State private var isCreatingOrder = false
    @State private var clientToken: String?
    @State private var authorizationToken: String?
    @State private var orderId: String?
    
    let productName: String
    let productPrice: Double
    let productSKU: String
    
    // Klarna Service - uses direct API calls to Klarna Playground
    private let klarnaService = KlarnaService.makeDefaultService()
    
    var body: some View {
        NavigationView {
            ZStack {
                if let token = clientToken {
                    // Show Klarna payment view
                    KlarnaPaymentViewWrapper(
                        clientToken: token,
                        orderData: makeOrderRequest(),
                        onAuthorization: handleAuthorization,
                        onError: handleError
                    )
                } else if isCreatingSession {
                    // Show loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Creating payment session...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Initial view - create session button
                    VStack(spacing: 20) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.pink)
                        
                        Text("Ready to pay with Klarna")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("\(productName)")
                            .font(.headline)
                        
                        Text("$\(String(format: "%.2f", productPrice))")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        Button(action: createSession) {
                            Text("Continue")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.pink)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Payment Successful!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                if let orderId = orderId {
                    Text("Your order has been placed successfully!\n\nOrder ID: \(orderId)")
                } else {
                    Text("Your order has been placed successfully!")
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {
                    errorMessage = ""
                }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            // Auto-create session on appear
            createSession()
        }
    }
    
    private func makeOrderRequest() -> OrderRequest {
        let priceInMinorUnits = Int(productPrice * 100)
        
        let orderLine = OrderLine(
            type: "physical",
            reference: productSKU,
            name: productName,
            quantity: 1,
            quantityUnit: "pcs",
            unitPrice: priceInMinorUnits,
            taxRate: 0,
            totalAmount: priceInMinorUnits,
            totalTaxAmount: 0
        )
        
        return OrderRequest(
            purchaseCountry: "US",
            purchaseCurrency: "USD",
            locale: "en-US",
            orderAmount: priceInMinorUnits,
            orderTaxAmount: 0,
            orderLines: [orderLine],
            merchantReference1: "demo-merchant-ref-\(UUID().uuidString.prefix(8))"
        )
    }
    
    private func makeSessionRequest() -> SessionRequest {
        let orderRequest = makeOrderRequest()
        
        return SessionRequest(
            purchaseCountry: orderRequest.purchaseCountry,
            purchaseCurrency: orderRequest.purchaseCurrency,
            locale: orderRequest.locale,
            orderAmount: orderRequest.orderAmount,
            orderTaxAmount: orderRequest.orderTaxAmount,
            orderLines: orderRequest.orderLines,
            intent: "buy"
        )
    }
    
    private func createSession() {
        isCreatingSession = true
        
        Task {
            do {
                let sessionRequest = makeSessionRequest()
                let response = try await klarnaService.createSession(request: sessionRequest)
                
                await MainActor.run {
                    isCreatingSession = false
                    // Direct API response - clientToken is directly on the response
                    clientToken = response.clientToken
                }
            } catch {
                await MainActor.run {
                    isCreatingSession = false
                    errorMessage = "Failed to create session: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func handleAuthorization(token: String, approved: Bool) {
        guard approved else {
            errorMessage = "Payment was not approved"
            showingError = true
            return
        }
        
        authorizationToken = token
        createOrder(with: token)
    }
    
    private func createOrder(with token: String) {
        isCreatingOrder = true
        
        Task {
            do {
                let orderRequest = makeOrderRequest()
                let response = try await klarnaService.createOrder(authorizationToken: token, request: orderRequest)
                
                await MainActor.run {
                    isCreatingOrder = false
                    // Direct API response - orderId is directly on the response
                    orderId = response.orderId
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isCreatingOrder = false
                    errorMessage = "Failed to create order: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

// MARK: - SwiftUI Wrapper for UIKit Payment View

struct KlarnaPaymentViewWrapper: UIViewControllerRepresentable {
    let clientToken: String
    let orderData: OrderRequest
    let onAuthorization: (String, Bool) -> Void
    let onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let paymentVC = KlarnaPaymentViewController(clientToken: clientToken)
        paymentVC.delegate = context.coordinator
        
        let navController = UINavigationController(rootViewController: paymentVC)
        
        // Auto-authorize after view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            paymentVC.authorize(orderData: orderData)
        }
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onAuthorization: onAuthorization, onError: onError)
    }
    
    class Coordinator: KlarnaPaymentDelegate {
        let onAuthorization: (String, Bool) -> Void
        let onError: (Error) -> Void
        
        init(onAuthorization: @escaping (String, Bool) -> Void, onError: @escaping (Error) -> Void) {
            self.onAuthorization = onAuthorization
            self.onError = onError
        }
        
        func didReceiveAuthorization(token: String, approved: Bool) {
            onAuthorization(token, approved)
        }
        
        func didEncounterError(_ error: Error) {
            onError(error)
        }
        
        func didComplete() {
            // Handle completion if needed
        }
    }
}
