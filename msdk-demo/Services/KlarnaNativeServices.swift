//
//  KlarnaNativeServices.swift
//  msdk-demo
//
//  Native service facades that mirror the former backend proxy routes.
//

import Foundation

/// High-level entry point that exposes native service objects for the various Klarna domains.
final class KlarnaNativeServices {
    let client: KlarnaService
    let payments: KlarnaPaymentsService
    let customerTokens: KlarnaCustomerTokenService
    let orderManagement: KlarnaOrderManagementService
    let disputes: KlarnaDisputesService
    let distribution: KlarnaDistributionService
    let hpp: KlarnaHostedPaymentPageService
    
    init(client: KlarnaService = .makeDefaultService()) {
        self.client = client
        self.payments = KlarnaPaymentsService(client: client)
        self.customerTokens = KlarnaCustomerTokenService(client: client)
        self.orderManagement = KlarnaOrderManagementService(client: client)
        self.disputes = KlarnaDisputesService(client: client)
        self.distribution = KlarnaDistributionService(client: client)
        self.hpp = KlarnaHostedPaymentPageService(client: client)
    }
}

// MARK: - Payments

final class KlarnaPaymentsService {
    private let client: KlarnaService
    
    init(client: KlarnaService) {
        self.client = client
    }
    
    func createSession(request: SessionRequest) async throws -> KlarnaSessionResponse {
        try await client.createSession(request: request)
    }
    
    func createOrder(authorizationToken: String, request: OrderRequest) async throws -> KlarnaOrderResponse {
        try await client.createOrder(authorizationToken: authorizationToken, request: request)
    }
    
    func createCustomerToken(
        authorizationToken: String,
        body: (any Encodable)? = nil
    ) async throws -> KlarnaCustomerTokenResponse {
        let encodedToken = authorizationToken.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? authorizationToken
        let response = try await client.performRequest(
            path: "/payments/v1/authorizations/\(encodedToken)/customer-token",
            method: .POST,
            body: body
        )
        return try response.decodeOrThrowServiceError(KlarnaCustomerTokenResponse.self)
    }
}

// MARK: - Customer Tokens

final class KlarnaCustomerTokenService {
    private let client: KlarnaService
    
    init(client: KlarnaService) {
        self.client = client
    }
    
    func read(customerToken: String) async throws -> KlarnaCustomerTokenDetails {
        let encodedToken = customerToken.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? customerToken
        let response = try await client.performRequest(
            path: "/customer-token/v1/tokens/\(encodedToken)",
            method: .GET,
            body: nil
        )
        return try response.decodeOrThrowServiceError(KlarnaCustomerTokenDetails.self)
    }
    
    func createOrder(
        customerToken: String,
        request: OrderRequest
    ) async throws -> KlarnaOrderResponse {
        let encodedToken = customerToken.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? customerToken
        let response = try await client.performRequest(
            path: "/customer-token/v1/tokens/\(encodedToken)/order",
            method: .POST,
            body: request
        )
        return try response.decodeOrThrowServiceError(KlarnaOrderResponse.self)
    }
}

// MARK: - Order Management

final class KlarnaOrderManagementService {
    private let client: KlarnaService
    
    init(client: KlarnaService) {
        self.client = client
    }
    
    func getOrder(orderId: String) async throws -> KlarnaHTTPResponse {
        let encoded = orderId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? orderId
        return try await client.performRequest(
            path: "/ordermanagement/v1/orders/\(encoded)",
            method: .GET,
            body: nil
        )
    }
    
    func getCaptures(orderId: String) async throws -> KlarnaHTTPResponse {
        let encoded = orderId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? orderId
        return try await client.performRequest(
            path: "/ordermanagement/v1/orders/\(encoded)/captures",
            method: .GET,
            body: nil
        )
    }
    
    func captureOrder(orderId: String, request: KlarnaCaptureRequest) async throws -> KlarnaHTTPResponse {
        let encoded = orderId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? orderId
        return try await client.performRequest(
            path: "/ordermanagement/v1/orders/\(encoded)/captures",
            method: .POST,
            body: request
        )
    }
    
    func refundOrder(orderId: String, request: KlarnaRefundRequest) async throws -> KlarnaHTTPResponse {
        let encoded = orderId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? orderId
        return try await client.performRequest(
            path: "/ordermanagement/v1/orders/\(encoded)/refunds",
            method: .POST,
            body: request
        )
    }
    
    func cancelOrder(orderId: String, request: KlarnaCancelOrderRequest? = nil) async throws -> KlarnaHTTPResponse {
        let encoded = orderId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? orderId
        return try await client.performRequest(
            path: "/ordermanagement/v1/orders/\(encoded)/cancel",
            method: .POST,
            body: request
        )
    }
    
    func releaseRemainingAuthorization(orderId: String, idempotencyKey: String = UUID().uuidString) async throws -> KlarnaHTTPResponse {
        let encoded = orderId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? orderId
        return try await client.performRequest(
            path: "/ordermanagement/v1/orders/\(encoded)/release-remaining-authorization",
            method: .POST,
            body: nil,
            headers: ["Klarna-Idempotency-Key": idempotencyKey]
        )
    }
}

// MARK: - Disputes

final class KlarnaDisputesService {
    private let client: KlarnaService
    
    init(client: KlarnaService) {
        self.client = client
    }
    
    func listDisputes() async throws -> KlarnaDisputesResponse {
        let response = try await client.performRequest(
            path: "/disputes/v3/disputes",
            method: .GET,
            body: nil
        )
        return try response.decodeOrThrowServiceError(KlarnaDisputesResponse.self)
    }
}

// MARK: - Distribution Assets

final class KlarnaDistributionService {
    private let client: KlarnaService
    
    init(client: KlarnaService) {
        self.client = client
    }
    
    func fetchDistribution(resultURL: String) async throws -> KlarnaDistributionAsset {
        let resolvedURL = try resolve(resultURL: resultURL)
        let response = try await client.performAbsoluteRequest(
            url: resolvedURL,
            method: .GET,
            headers: ["Accept": "image/png, image/jpeg, application/json;q=0.9, */*;q=0.8"]
        )
        
        if let contentType = response.contentType, contentType.lowercased().hasPrefix("image/") {
            return KlarnaDistributionAsset(
                payload: response.data,
                contentType: contentType,
                sourceURL: resolvedURL,
                distribution: nil,
                qrImageData: nil
            )
        }
        
        if let contentType = response.contentType, contentType.contains("application/json") {
            let distribution = try response.decodeOrThrowServiceError(KlarnaDistributionStatus.self)
            var qrData: Data?
            if let qr = distribution.qr, let qrURL = URL(string: qr) {
                let qrResponse = try await client.performAbsoluteRequest(
                    url: qrURL,
                    method: .GET,
                    headers: ["Accept": "image/png,image/jpeg,image/gif;q=0.9,*/*;q=0.8"],
                    includeAuthorization: false
                )
                if qrResponse.statusCode < 400 {
                    qrData = qrResponse.data
                }
            }
            
            return KlarnaDistributionAsset(
                payload: response.data,
                contentType: contentType,
                sourceURL: resolvedURL,
                distribution: distribution,
                qrImageData: qrData
            )
        }
        
        let fallbackType = response.contentType ?? "application/octet-stream"
        return KlarnaDistributionAsset(
            payload: response.data,
            contentType: fallbackType,
            sourceURL: resolvedURL,
            distribution: nil,
            qrImageData: nil
        )
    }
    
    private func resolve(resultURL: String) throws -> URL {
        if let url = URL(string: resultURL), url.scheme != nil {
            return url
        }
        let base = client.apiBaseURL.hasSuffix("/") ? String(client.apiBaseURL.dropLast()) : client.apiBaseURL
        let suffix = resultURL.hasPrefix("/") ? resultURL : "/\(resultURL)"
        guard let url = URL(string: "\(base)\(suffix)") else {
            throw KlarnaServiceError.invalidURL
        }
        return url
    }
}

// MARK: - Hosted Payment Pages

final class KlarnaHostedPaymentPageService {
    private let client: KlarnaService
    
    init(client: KlarnaService) {
        self.client = client
    }
    
    func createSession(request: KlarnaHPPSessionRequest) async throws -> KlarnaHPPSessionResponse {
        let response = try await client.performRequest(
            path: "/hpp/v1/sessions",
            method: .POST,
            body: request
        )
        return try response.decodeOrThrowServiceError(KlarnaHPPSessionResponse.self)
    }
    
    func getSession(_ identifier: KlarnaHPPSessionIdentifier) async throws -> KlarnaHPPSessionResponse {
        let response: KlarnaHTTPResponse
        switch identifier {
        case .sessionId(let id):
            let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
            response = try await client.performRequest(
                path: "/hpp/v1/sessions/\(encoded)",
                method: .GET,
                body: nil
            )
        case .sessionURL(let urlString):
            response = try await client.performAbsoluteRequest(
                urlString: urlString,
                method: .GET,
                body: nil
            )
        }
        return try response.decodeOrThrowServiceError(KlarnaHPPSessionResponse.self)
    }
}

enum KlarnaHPPSessionIdentifier {
    case sessionId(String)
    case sessionURL(String)
}

// MARK: - Data Models

struct KlarnaCustomerTokenResponse: Codable {
    let customerTokenId: String
    let status: String?
    let paymentMethodType: String?
    let redirectUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case customerTokenId = "customer_token_id"
        case status
        case paymentMethodType = "payment_method_type"
        case redirectUrl = "redirect_url"
    }
}

struct KlarnaCustomerTokenDetails: Codable {
    let customerTokenId: String
    let status: String?
    let paymentMethodType: String?
    let paymentMethod: KlarnaCustomerTokenPaymentMethod?
    let billingAddress: KlarnaAddress?
    let customer: KlarnaCustomerDetails?
    
    enum CodingKeys: String, CodingKey {
        case customerTokenId = "customer_token_id"
        case status
        case paymentMethodType = "payment_method_type"
        case paymentMethod = "payment_method"
        case billingAddress = "billing_address"
        case customer
    }
}

struct KlarnaCustomerTokenPaymentMethod: Codable {
    let type: String?
    let tokenId: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case tokenId = "token_id"
    }
}

struct KlarnaCustomerTokenCreateRequest: Codable {
    let customer: KlarnaCustomerDetails?
    let billingAddress: KlarnaAddress?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case customer
        case billingAddress = "billing_address"
        case description
    }
}

struct KlarnaCustomerDetails: Codable {
    let dateOfBirth: String?
    let email: String?
    let phone: String?
    let givenName: String?
    let familyName: String?
    
    enum CodingKeys: String, CodingKey {
        case dateOfBirth = "date_of_birth"
        case email
        case phone
        case givenName = "given_name"
        case familyName = "family_name"
    }
}

struct KlarnaAddress: Codable {
    let streetAddress: String?
    let streetAddress2: String?
    let postalCode: String?
    let city: String?
    let region: String?
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case streetAddress = "street_address"
        case streetAddress2 = "street_address2"
        case postalCode = "postal_code"
        case city
        case region
        case country
    }
}

struct KlarnaCancelOrderRequest: Codable {
    let cancellationNote: String?
    
    enum CodingKeys: String, CodingKey {
        case cancellationNote = "cancellation_note"
    }
}

struct KlarnaCaptureRequest: Codable {
    let capturedAmount: Int
    let description: String?
    let orderLines: [OrderLine]?
    let shippingInfo: [KlarnaShippingInfo]?
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case capturedAmount = "captured_amount"
        case description
        case orderLines = "order_lines"
        case shippingInfo = "shipping_info"
        case metadata
    }
}

struct KlarnaShippingInfo: Codable {
    let shippingCompany: String?
    let trackingNumber: String?
    let trackingUri: String?
    
    enum CodingKeys: String, CodingKey {
        case shippingCompany = "shipping_company"
        case trackingNumber = "tracking_number"
        case trackingUri = "tracking_uri"
    }
}

struct KlarnaRefundRequest: Codable {
    let refundedAmount: Int
    let description: String?
    let orderLines: [OrderLine]?
    
    enum CodingKeys: String, CodingKey {
        case refundedAmount = "refunded_amount"
        case description
        case orderLines = "order_lines"
    }
}

struct KlarnaDisputesResponse: Codable {
    let disputes: [KlarnaDisputeSummary]
    let pagination: KlarnaDisputePagination?
}

struct KlarnaDisputeSummary: Codable {
    let disputeId: String?
    let orderId: String?
    let status: String?
    let reason: String?
    let createdAt: String?
    let updatedAt: String?
    let amount: Int?
    let currency: String?
    
    enum CodingKeys: String, CodingKey {
        case disputeId = "dispute_id"
        case orderId = "order_id"
        case status
        case reason
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case amount
        case currency
    }
}

struct KlarnaDisputePagination: Codable {
    let continuationToken: String?
    
    enum CodingKeys: String, CodingKey {
        case continuationToken = "continuation_token"
    }
}

struct KlarnaDistributionStatus: Codable {
    let status: String?
    let qr: String?
    let expiresAt: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case qr
        case expiresAt = "expires_at"
    }
}

struct KlarnaDistributionAsset {
    let payload: Data
    let contentType: String
    let sourceURL: URL
    let distribution: KlarnaDistributionStatus?
    let qrImageData: Data?
    
    /// Convenience helper that produces a data URL for preview/debugging.
    func dataURL(preferQR: Bool = true) -> String? {
        let targetData: Data?
        if preferQR, let qrImageData {
            targetData = qrImageData
        } else {
            targetData = payload
        }
        guard let data = targetData else { return nil }
        let base64 = data.base64EncodedString()
        return "data:\(contentType);base64,\(base64)"
    }
}

struct KlarnaHPPSessionRequest: Codable {
    let paymentSessionURL: String
    let merchantURLs: KlarnaHPPMerchantURLs
    let options: KlarnaHPPSessionOptions?
    
    enum CodingKeys: String, CodingKey {
        case paymentSessionURL = "payment_session_url"
        case merchantURLs = "merchant_urls"
        case options
    }
}

struct KlarnaHPPMerchantURLs: Codable {
    let success: String
    let cancel: String
    let back: String
    let failure: String
    let error: String
    let statusUpdate: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case cancel
        case back
        case failure
        case error
        case statusUpdate = "status_update"
    }
}

struct KlarnaHPPSessionOptions: Codable {
    enum PlaceOrderMode: String, Codable {
        case placeOrder = "PLACE_ORDER"
        case captureOrder = "CAPTURE_ORDER"
        case none = "NONE"
    }
    
    let placeOrderMode: PlaceOrderMode?
    
    enum CodingKeys: String, CodingKey {
        case placeOrderMode = "place_order_mode"
    }
}

struct KlarnaHPPSessionResponse: Codable {
    let sessionId: String?
    let sessionUrl: String?
    let paymentSessionUrl: String?
    let authorizationToken: String?
    let orderId: String?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case sessionUrl = "session_url"
        case paymentSessionUrl = "payment_session_url"
        case authorizationToken = "authorization_token"
        case orderId = "order_id"
        case status
    }
}

