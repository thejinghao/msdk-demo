//
//  OrderConfirmationView.swift
//  msdk-demo
//
//  Order confirmation page shown after successful Klarna checkout
//

import SwiftUI

struct OrderConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    
    let orderId: String
    let orderAmount: Double
    let productName: String
    let shippingAddress: ShippingAddress
    let estimatedDelivery: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Success Icon
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Order Confirmed!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Thank you for your purchase")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Order Details Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("Order Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        DetailRow(label: "Order Number", value: orderId)
                        DetailRow(label: "Product", value: productName)
                        DetailRow(label: "Total Amount", value: "$\(String(format: "%.2f", orderAmount))")
                        DetailRow(label: "Payment Method", value: "Klarna")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Shipping Information Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("Shipping Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(shippingAddress.firstName) \(shippingAddress.lastName)")
                            .fontWeight(.medium)
                        Text(shippingAddress.addressLine1)
                        if !shippingAddress.addressLine2.isEmpty {
                            Text(shippingAddress.addressLine2)
                        }
                        Text("\(shippingAddress.city), \(shippingAddress.state) \(shippingAddress.zipCode)")
                        Text(shippingAddress.country)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "truck.box.fill")
                            .foregroundColor(.blue)
                        Text("Estimated Delivery:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(estimatedDelivery)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Email Confirmation
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    Text("A confirmation email has been sent to")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(shippingAddress.email)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Order Confirmed")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    // Dismiss to root
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Shipping Address Model

struct ShippingAddress: Codable {
    let firstName: String
    let lastName: String
    let addressLine1: String
    let addressLine2: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let email: String
}

// MARK: - Preview

#Preview {
    NavigationView {
        OrderConfirmationView(
            orderId: "KL-2024-001234",
            orderAmount: 274.00,
            productName: "Classic T-Shirt",
            shippingAddress: ShippingAddress(
                firstName: "John",
                lastName: "Doe",
                addressLine1: "123 Main Street",
                addressLine2: "Apt 4B",
                city: "San Francisco",
                state: "CA",
                zipCode: "94102",
                country: "United States",
                email: "customer@email.us"
            ),
            estimatedDelivery: "Dec 9-11, 2024"
        )
    }
}
