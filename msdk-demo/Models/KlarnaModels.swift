//
//  KlarnaModels.swift
//  msdk-demo
//
//  Klarna Payments API models for direct API integration
//

import Foundation

// MARK: - Order Line Item

/// Represents a line item in an order
struct OrderLine: Codable {
    let type: String
    let reference: String
    let name: String
    let quantity: Int
    let quantityUnit: String
    let unitPrice: Int
    let taxRate: Int
    let totalAmount: Int
    let totalTaxAmount: Int
    
    enum CodingKeys: String, CodingKey {
        case type, reference, name, quantity
        case quantityUnit = "quantity_unit"
        case unitPrice = "unit_price"
        case taxRate = "tax_rate"
        case totalAmount = "total_amount"
        case totalTaxAmount = "total_tax_amount"
    }
}

// MARK: - Session Request

/// Request body for creating a Klarna payment session
/// API: POST /payments/v1/sessions
struct SessionRequest: Codable {
    let purchaseCountry: String
    let purchaseCurrency: String
    let locale: String
    let orderAmount: Int
    let orderTaxAmount: Int
    let orderLines: [OrderLine]
    let intent: String?
    
    enum CodingKeys: String, CodingKey {
        case purchaseCountry = "purchase_country"
        case purchaseCurrency = "purchase_currency"
        case locale
        case orderAmount = "order_amount"
        case orderTaxAmount = "order_tax_amount"
        case orderLines = "order_lines"
        case intent
    }
}

// MARK: - Session Response (Direct Klarna API)

/// Response from Klarna Payments session creation
/// API: POST /payments/v1/sessions
struct KlarnaSessionResponse: Codable {
    /// Client token used to initialize the Klarna MSDK
    let clientToken: String
    
    /// Session ID for tracking
    let sessionId: String?
    
    /// Available payment method categories
    let paymentMethodCategories: [PaymentMethodCategory]?
    
    enum CodingKeys: String, CodingKey {
        case clientToken = "client_token"
        case sessionId = "session_id"
        case paymentMethodCategories = "payment_method_categories"
    }
}

/// A payment method category available for the session
struct PaymentMethodCategory: Codable {
    let identifier: String
    let name: String?
    let assetUrls: AssetUrls?
    
    enum CodingKeys: String, CodingKey {
        case identifier
        case name
        case assetUrls = "asset_urls"
    }
}

/// Asset URLs for payment method branding
struct AssetUrls: Codable {
    let standard: String?
    let descriptive: String?
}

// MARK: - Order Request

/// Request body for creating an order after authorization
/// API: POST /payments/v1/authorizations/{authorizationToken}/order
struct OrderRequest: Codable {
    let purchaseCountry: String
    let purchaseCurrency: String
    let locale: String
    let orderAmount: Int
    let orderTaxAmount: Int
    let orderLines: [OrderLine]
    let merchantReference1: String?
    
    enum CodingKeys: String, CodingKey {
        case purchaseCountry = "purchase_country"
        case purchaseCurrency = "purchase_currency"
        case locale
        case orderAmount = "order_amount"
        case orderTaxAmount = "order_tax_amount"
        case orderLines = "order_lines"
        case merchantReference1 = "merchant_reference1"
    }
}

// MARK: - Order Response (Direct Klarna API)

/// Response from Klarna order creation
/// API: POST /payments/v1/authorizations/{authorizationToken}/order
struct KlarnaOrderResponse: Codable {
    /// The unique order ID assigned by Klarna
    let orderId: String
    
    /// Fraud status of the order
    let fraudStatus: String?
    
    /// Details about the authorized payment method
    let authorizedPaymentMethod: AuthorizedPaymentMethod?
    
    /// Redirect URL (if applicable)
    let redirectUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case fraudStatus = "fraud_status"
        case authorizedPaymentMethod = "authorized_payment_method"
        case redirectUrl = "redirect_url"
    }
}

/// Information about the payment method used
struct AuthorizedPaymentMethod: Codable {
    let type: String?
    let numberOfInstallments: Int?
    
    enum CodingKeys: String, CodingKey {
        case type
        case numberOfInstallments = "number_of_installments"
    }
}

// MARK: - Error Response

/// Klarna API error response structure
struct KlarnaErrorResponse: Codable {
    let correlationId: String?
    let errorCode: String?
    let errorMessages: [String]?
    
    enum CodingKeys: String, CodingKey {
        case correlationId = "correlation_id"
        case errorCode = "error_code"
        case errorMessages = "error_messages"
    }
}
