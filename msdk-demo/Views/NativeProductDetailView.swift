//
//  NativeProductDetailView.swift
//  msdk-demo
//
//  Created by Jing Hao on 12/2/25.
//

import SwiftUI

struct NativeProductDetailView: View {
    @State private var showingCheckout = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var osmHeight: CGFloat = 0
    
    // Mock product data
    private let productName = "Classic T-Shirt"
    private let productPrice = 259.00
    private let productDescription = "Premium cotton t-shirt with modern fit. Perfect for everyday wear."
    private let productSKU = "SKU-123"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Product Image
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Product Image")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Product Name
                    Text(productName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Price
                    Text("$\(String(format: "%.2f", productPrice))")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    // Klarna On-Site Messaging
                    KlarnaOSMViewWrapper(
                        purchaseAmount: productPrice,
                        height: $osmHeight
                    )
                    .frame(height: osmHeight > 0 ? osmHeight : 100)
                    .opacity(osmHeight > 0 ? 1 : 0)
                    .padding(.vertical, 4)
                    
                    // SKU
                    Text("SKU: \(productSKU)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(productDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(icon: "checkmark.circle.fill", text: "100% Premium Cotton")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Machine Washable")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Available in Multiple Sizes")
                        FeatureRow(icon: "checkmark.circle.fill", text: "Free Shipping")
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 100)
            }
        }
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                NavigationLink(destination: NativeCheckoutView(
                    productName: productName,
                    productPrice: productPrice,
                    productSKU: productSKU
                )) {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        
                        Text("Checkout")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color(uiColor: .systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.system(size: 14))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        NativeProductDetailView()
    }
}
