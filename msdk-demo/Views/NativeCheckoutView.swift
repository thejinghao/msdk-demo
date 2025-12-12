//
//  NativeCheckoutView.swift
//  msdk-demo
//
//  Mock checkout page with shipping options and Klarna payment integration
//

import SwiftUI
import UIKit
import KlarnaMobileSDK

// MARK: - Shipping Option Model

struct ShippingOption: Identifiable {
    let id: String
    let name: String
    let price: Double
    let deliveryTime: String
    
    static let standard = ShippingOption(
        id: "standard",
        name: "Standard Shipping",
        price: 0.00,
        deliveryTime: "5-7 business days"
    )
    
    static let express = ShippingOption(
        id: "express",
        name: "Express Shipping",
        price: 15.00,
        deliveryTime: "2-3 business days"
    )
    
    static let overnight = ShippingOption(
        id: "overnight",
        name: "Overnight Shipping",
        price: 35.00,
        deliveryTime: "next business day"
    )
    
    static let allOptions = [standard, express, overnight]
}

// MARK: - Payment Method

enum PaymentMethod: String, CaseIterable {
    case creditCard = "Credit Card"
    case klarna = "Klarna"
}

// MARK: - Native Checkout View

struct NativeCheckoutView: View {
    @Environment(\.dismiss) var dismiss
    
    // Product information
    let productName: String
    let productPrice: Double
    let productSKU: String
    
    // Shipping form fields (prepopulated with mock data)
    @State private var firstName = "John"
    @State private var lastName = "Doe"
    @State private var addressLine1 = "123 Main Street"
    @State private var addressLine2 = "Apt 4B"
    @State private var city = "San Francisco"
    @State private var stateRegion = "CA"
    @State private var zipCode = "94102"
    @State private var country = "United States"
    @State private var phoneNumber = "+13106683312"
    @State private var email = "customer@email.us"
    
    // Shipping and payment selection
    @State private var selectedShipping: ShippingOption = .standard
    @State private var selectedPayment: PaymentMethod = .klarna
    
    // Klarna state
    @State private var isCreatingSession = false
    @State private var clientToken: String?
    @State private var sessionError: String?
    @State private var isProcessingOrder = false
    
    // Success/Error alerts
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var orderId: String?
    @State private var navigateToConfirmation = false
    
    // Klarna Service
    private let klarnaService = KlarnaService.makeDefaultService()
    
    var totalAmount: Double {
        productPrice + selectedShipping.price
    }
    
    var body: some View {
        NavigationStack {
            contentView
        }
        .background(
            NavigationLink(
                destination: OrderConfirmationView(
                    orderId: orderId ?? "N/A",
                    orderAmount: totalAmount,
                    productName: productName,
                    shippingAddress: makeShippingAddress(),
                    estimatedDelivery: makeEstimatedDelivery()
                ),
                isActive: $navigateToConfirmation,
                label: { EmptyView() }
            )
        )
    }
    
    private var contentView: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Order Summary
                    orderSummarySection
                    
                    Divider()
                    
                    // Shipping Information
                    shippingFormSection
                    
                    Divider()
                    
                    // Shipping Options
                    shippingOptionsSection
                    
                    Divider()
                    
                    // Payment Method
                    paymentMethodSection
                    
                    // Embedded Klarna Payment View (hidden)
                    if let token = clientToken {
                        KlarnaPaymentViewEmbedded(
                            clientToken: token,
                            onInitialized: { paymentView in
                                // Store reference and call load
                                paymentView.load()
                            },
                            onAuthorization: handleAuthorizationSuccess,
                            onError: handleAuthorizationError
                        )
                        .frame(height: 0)
                        .hidden()
                    }
                    
                    // Spacer for bottom button
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                placeOrderButton
            }
            .onAppear {
                createKlarnaSession()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {
                    errorMessage = ""
                    isProcessingOrder = false
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Order Summary Section
    
    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(productName)
                        .font(.subheadline)
                    Text("SKU: \(productSKU)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("$\(String(format: "%.2f", productPrice))")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Subtotal breakdown
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text("$\(String(format: "%.2f", productPrice))")
                }
                .font(.subheadline)
                
                HStack {
                    Text("Shipping")
                    Spacer()
                    Text("$\(String(format: "%.2f", selectedShipping.price))")
                }
                .font(.subheadline)
                
                Divider()
                
                HStack {
                    Text("Total")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("$\(String(format: "%.2f", totalAmount))")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .font(.headline)
            }
        }
    }
    
    // MARK: - Shipping Form Section
    
    private var shippingFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shipping Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("First Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Address Line 1")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Street Address", text: $addressLine1)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Address Line 2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Apt, Suite, etc. (optional)", text: $addressLine2)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("City")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("City", text: $city)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("State/Region")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("State", text: $stateRegion)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ZIP Code")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("ZIP Code", text: $zipCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Country")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Country", text: $country)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Phone Number")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Phone Number", text: $phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Email Address")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
        }
    }
    
    // MARK: - Shipping Options Section
    
    private var shippingOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shipping Method")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(ShippingOption.allOptions) { option in
                ShippingOptionRow(
                    option: option,
                    isSelected: selectedShipping.id == option.id,
                    onSelect: { selectedShipping = option }
                )
            }
        }
    }
    
    // MARK: - Payment Method Section
    
    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Method")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Credit Card option (disabled)
            PaymentMethodRow(
                method: .creditCard,
                isSelected: selectedPayment == .creditCard,
                isDisabled: true,
                onSelect: { }
            )
            
            // Klarna option (active)
            PaymentMethodRow(
                method: .klarna,
                isSelected: selectedPayment == .klarna,
                isDisabled: false,
                onSelect: { selectedPayment = .klarna }
            )
            
            // Klarna session status
            if isCreatingSession {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Initializing Klarna payment...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            } else if let error = sessionError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Place Order Button
    
    private var placeOrderButton: some View {
        VStack(spacing: 0) {
            Button(action: placeOrder) {
                HStack(spacing: 12) {
                    if isProcessingOrder {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    Text(isProcessingOrder ? "Processing..." : "Place Order")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canPlaceOrder ? Color.pink : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canPlaceOrder || isProcessingOrder)
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(uiColor: .systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
    }
    
    // MARK: - Validation
    
    private var canPlaceOrder: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !addressLine1.isEmpty &&
        !city.isEmpty &&
        !stateRegion.isEmpty &&
        !zipCode.isEmpty &&
        !country.isEmpty &&
        !phoneNumber.isEmpty &&
        !email.isEmpty &&
        clientToken != nil &&
        selectedPayment == .klarna
    }
    
    // MARK: - Klarna Session Creation
    
    private func createKlarnaSession() {
        isCreatingSession = true
        sessionError = nil
        
        Task {
            do {
                let sessionRequest = makeSessionRequest()
                let response = try await klarnaService.createSession(request: sessionRequest)
                
                await MainActor.run {
                    isCreatingSession = false
                    clientToken = response.clientToken
                }
            } catch {
                await MainActor.run {
                    isCreatingSession = false
                    sessionError = error.localizedDescription
                }
            }
        }
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
    
    // MARK: - Place Order
    
    private func placeOrder() {
        guard canPlaceOrder else { return }
        
        // Trigger authorization on the embedded payment view
        isProcessingOrder = true
        
        // The embedded payment view will handle the authorize call
        NotificationCenter.default.post(
            name: NSNotification.Name("TriggerKlarnaAuthorization"),
            object: nil,
            userInfo: ["orderData": makeOrderRequest()]
        )
    }
    
    private func handleAuthorizationSuccess(token: String, approved: Bool) {
        guard approved else {
            isProcessingOrder = false
            errorMessage = "Payment was not approved"
            showingError = true
            return
        }
        
        // Create order with authorization token
        Task {
            do {
                let orderRequest = makeOrderRequest()
                let response = try await klarnaService.createOrder(authorizationToken: token, request: orderRequest)
                
                await MainActor.run {
                    isProcessingOrder = false
                    orderId = response.orderId
                    
                    // Navigate to confirmation page
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        navigateToConfirmation = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessingOrder = false
                    errorMessage = "Failed to create order: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func handleAuthorizationError(_ error: Error) {
        isProcessingOrder = false
        errorMessage = error.localizedDescription
        showingError = true
    }
    
    private func makeOrderRequest() -> OrderRequest {
        // Product line item
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
        
        // Shipping line item
        let shippingPriceInMinorUnits = Int(selectedShipping.price * 100)
        let shippingLine = OrderLine(
            type: "shipping_fee",
            reference: selectedShipping.id,
            name: selectedShipping.name,
            quantity: 1,
            quantityUnit: "pcs",
            unitPrice: shippingPriceInMinorUnits,
            taxRate: 0,
            totalAmount: shippingPriceInMinorUnits,
            totalTaxAmount: 0
        )
        
        // Total amount
        let totalAmountInMinorUnits = productPriceInMinorUnits + shippingPriceInMinorUnits
        
        return OrderRequest(
            purchaseCountry: "US",
            purchaseCurrency: "USD",
            locale: "en-US",
            orderAmount: totalAmountInMinorUnits,
            orderTaxAmount: 0,
            orderLines: [productLine, shippingLine],
            merchantReference1: "checkout-\(UUID().uuidString.prefix(8))"
        )
    }
    
    private func makeShippingAddress() -> ShippingAddress {
        ShippingAddress(
            firstName: firstName,
            lastName: lastName,
            addressLine1: addressLine1,
            addressLine2: addressLine2,
            city: city,
            state: stateRegion,
            zipCode: zipCode,
            country: country,
            email: email
        )
    }
    
    private func makeEstimatedDelivery() -> String {
        let calendar = Calendar.current
        let today = Date()
        
        // Parse delivery time from selected shipping
        let deliveryTimeComponents = selectedShipping.deliveryTime.components(separatedBy: " ")
        
        if selectedShipping.deliveryTime.contains("next business day") {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: today) {
                return formatDeliveryDate(nextDay)
            }
        } else if let firstNumber = deliveryTimeComponents.first, 
                  let daysMin = Int(firstNumber.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789").inverted)) {
            if let startDate = calendar.date(byAdding: .day, value: daysMin, to: today) {
                // If range like "5-7", add a few more days
                let endDays = selectedShipping.deliveryTime.contains("-") ? daysMin + 2 : daysMin
                if let endDate = calendar.date(byAdding: .day, value: endDays, to: today) {
                    return "\(formatDeliveryDate(startDate)) - \(formatDeliveryDate(endDate))"
                }
                return formatDeliveryDate(startDate)
            }
        }
        
        // Default fallback
        return "5-7 business days"
    }
    
    private func formatDeliveryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Shipping Option Row

struct ShippingOptionRow: View {
    let option: ShippingOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Radio button
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .pink : .gray)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(option.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if option.price == 0 {
                            Text("FREE")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        } else {
                            Text("$\(String(format: "%.2f", option.price))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Text(option.deliveryTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.pink : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Payment Method Row

struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let isDisabled: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Radio button
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isDisabled ? .gray.opacity(0.3) : (isSelected ? .pink : .gray))
                    .font(.system(size: 20))
                
                HStack {
                    if method == .klarna {
                        Text(method.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(isDisabled ? .gray : .primary)
                    } else {
                        Text(method.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(isDisabled ? .gray : .primary)
                    }
                    
                    if isDisabled {
                        Text("(For illustration only)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isDisabled ? Color.gray.opacity(0.2) : (isSelected ? Color.pink : Color.gray.opacity(0.3)),
                        lineWidth: isSelected && !isDisabled ? 2 : 1
                    )
            )
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Embedded Klarna Payment View

struct KlarnaPaymentViewEmbedded: UIViewRepresentable {
    let clientToken: String
    let onInitialized: (KlarnaPaymentView) -> Void
    let onAuthorization: (String, Bool) -> Void
    let onError: (Error) -> Void
    
    func makeUIView(context: Context) -> KlarnaPaymentView {
        let paymentView = KlarnaPaymentView(category: "klarna", eventListener: context.coordinator)
        context.coordinator.paymentView = paymentView
        
        // Initialize with client token and return URL for Klarna redirect
        // This URL will be called after the Klarna flow completes
        let returnURL = URL(string: "msdk-demo://order-confirmation")!
        paymentView.initialize(clientToken: clientToken, returnUrl: returnURL)
        
        return paymentView
    }
    
    func updateUIView(_ uiView: KlarnaPaymentView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onInitialized: onInitialized,
            onAuthorization: onAuthorization,
            onError: onError
        )
    }
    
    class Coordinator: NSObject, KlarnaPaymentEventListener {
        let onInitialized: (KlarnaPaymentView) -> Void
        let onAuthorization: (String, Bool) -> Void
        let onError: (Error) -> Void
        
        weak var paymentView: KlarnaPaymentView?
        private var authorizationObserver: NSObjectProtocol?
        
        init(
            onInitialized: @escaping (KlarnaPaymentView) -> Void,
            onAuthorization: @escaping (String, Bool) -> Void,
            onError: @escaping (Error) -> Void
        ) {
            self.onInitialized = onInitialized
            self.onAuthorization = onAuthorization
            self.onError = onError
            super.init()
            
            // Listen for authorization trigger
            authorizationObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("TriggerKlarnaAuthorization"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self,
                      let paymentView = self.paymentView,
                      let orderData = notification.userInfo?["orderData"] as? OrderRequest else {
                    return
                }
                
                // Convert OrderRequest to JSON and call authorize
                do {
                    let encoder = JSONEncoder()
                    encoder.keyEncodingStrategy = .convertToSnakeCase
                    let jsonData = try encoder.encode(orderData)
                    
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        paymentView.authorize(autoFinalize: true, jsonData: jsonString)
                    }
                } catch {
                    self.onError(error)
                }
            }
        }
        
        deinit {
            if let observer = authorizationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        // MARK: - KlarnaPaymentEventListener
        
        func klarnaInitialized(paymentView: KlarnaPaymentView) {
            DispatchQueue.main.async { [weak self] in
                self?.onInitialized(paymentView)
            }
        }
        
        func klarnaLoaded(paymentView: KlarnaPaymentView) {
            // Payment view loaded successfully
        }
        
        func klarnaLoadedPaymentReview(paymentView: KlarnaPaymentView) {
            // Payment review loaded
        }
        
        func klarnaAuthorized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?, finalizeRequired: Bool) {
            DispatchQueue.main.async { [weak self] in
                if approved, let token = authToken {
                    self?.onAuthorization(token, approved)
                } else {
                    self?.onAuthorization("", false)
                }
            }
        }
        
        func klarnaReauthorized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?) {
            DispatchQueue.main.async { [weak self] in
                if let token = authToken {
                    self?.onAuthorization(token, approved)
                }
            }
        }
        
        func klarnaFinalized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?) {
            DispatchQueue.main.async { [weak self] in
                if let token = authToken {
                    self?.onAuthorization(token, approved)
                }
            }
        }
        
        func klarnaResized(paymentView: KlarnaPaymentView, to newHeight: CGFloat) {
            // Handle resize if needed
        }
        
        func klarnaFailed(inPaymentView paymentView: KlarnaPaymentView, withError error: KlarnaPaymentError) {
            DispatchQueue.main.async { [weak self] in
                let nsError = NSError(
                    domain: "KlarnaPayment",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "\(error.name): \(error.message)"]
                )
                self?.onError(nsError)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        NativeCheckoutView(
            productName: "Classic T-Shirt",
            productPrice: 259.00,
            productSKU: "SKU-123"
        )
    }
}




