//
//  KlarnaService.swift
//  msdk-demo
//
//  Direct Klarna Playground API integration
//

import Foundation

// MARK: - HTTP Utilities

/// Lightweight wrapper around an HTTP response from Klarna's APIs.
struct KlarnaHTTPResponse {
    let data: Data
    let response: HTTPURLResponse
    
    var statusCode: Int { response.statusCode }
    var headers: [AnyHashable: Any] { response.allHeaderFields }
    var contentType: String? { response.headerValue(for: "Content-Type") }
    
    /// Decode the body into a strongly typed model.
    func decode<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
    
    /// Decode body and wrap any failure in a KlarnaServiceError for consistency.
    func decodeOrThrowServiceError<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        do {
            return try decode(T.self, decoder: decoder)
        } catch {
            throw KlarnaServiceError.decodingError(error)
        }
    }
    
    /// Attempt to convert the body into a UTF-8 string (useful for debugging).
    func text(encoding: String.Encoding = .utf8) -> String? {
        String(data: data, encoding: encoding)
    }
}

private extension HTTPURLResponse {
    func headerValue(for field: String) -> String? {
        for (key, value) in allHeaderFields {
            guard let keyString = key as? String else { continue }
            if keyString.caseInsensitiveCompare(field) == .orderedSame {
                return value as? String
            }
        }
        return nil
    }
}

/// Supported HTTP verbs for Klarna API calls.
enum KlarnaHTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE
}

/// Type eraser that lets us accept any Encodable payload.
struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void
    
    init(_ value: any Encodable) {
        self.encodeClosure = { encoder in
            try value.encode(to: encoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

// MARK: - Klarna Service Errors

enum KlarnaServiceError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(statusCode: Int, message: String)
    case missingCredentials
    case invalidResponse
    case invalidBody
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "Klarna API error (\(statusCode)): \(message)"
        case .missingCredentials:
            return "Missing Klarna API credentials"
        case .invalidResponse:
            return "Invalid response from Klarna API"
        case .invalidBody:
            return "Unable to encode request body"
        }
    }
}

// MARK: - Klarna Service

/// A service that communicates directly with the Klarna Playground API
class KlarnaService {
    
    /// Klarna Playground API base URL
    static let playgroundBaseURL = "https://api.playground.klarna.com"
    
    private let username: String
    private let password: String
    private let baseURL: String
    
    /// Initialize with Klarna API credentials
    /// - Parameters:
    ///   - username: Klarna API username (UID)
    ///   - password: Klarna API password (API key)
    ///   - baseURL: Base URL for Klarna API (defaults to playground)
    init(username: String, password: String, baseURL: String = KlarnaService.playgroundBaseURL) {
        self.username = username
        self.password = password
        self.baseURL = baseURL
    }
    
    /// Exposes the configured base URL (useful for building absolute URLs elsewhere)
    var apiBaseURL: String {
        baseURL
    }
    
    // MARK: - Request Helpers
    
    /// Creates Basic Auth header value from credentials
    private func createAuthorizationHeader() throws -> String {
        guard !username.isEmpty, !password.isEmpty else {
            throw KlarnaServiceError.missingCredentials
        }
        
        let credentials = "\(username):\(password)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            throw KlarnaServiceError.missingCredentials
        }
        
        let base64Credentials = credentialsData.base64EncodedString()
        return "Basic \(base64Credentials)"
    }
    
    /// Perform a request against the configured Klarna base URL.
    func performRequest(
        path: String,
        method: KlarnaHTTPMethod,
        body: (any Encodable)? = nil,
        headers: [String: String] = [:],
        accept: String? = "application/json",
        includeAuthorization: Bool = true
    ) async throws -> KlarnaHTTPResponse {
        let url = try buildURL(fromPath: path)
        return try await sendRequest(
            url: url,
            method: method,
            body: body,
            headers: headers,
            accept: accept,
            includeAuthorization: includeAuthorization
        )
    }
    
    /// Perform a request against an absolute URL (used for helper flows like distribution assets).
    func performAbsoluteRequest(
        url: URL,
        method: KlarnaHTTPMethod = .GET,
        body: (any Encodable)? = nil,
        headers: [String: String] = [:],
        accept: String? = nil,
        includeAuthorization: Bool = true
    ) async throws -> KlarnaHTTPResponse {
        return try await sendRequest(
            url: url,
            method: method,
            body: body,
            headers: headers,
            accept: accept,
            includeAuthorization: includeAuthorization
        )
    }
    
    /// Convenience overload that accepts a raw URL string.
    func performAbsoluteRequest(
        urlString: String,
        method: KlarnaHTTPMethod = .GET,
        body: (any Encodable)? = nil,
        headers: [String: String] = [:],
        accept: String? = nil,
        includeAuthorization: Bool = true
    ) async throws -> KlarnaHTTPResponse {
        guard let url = URL(string: urlString) else {
            throw KlarnaServiceError.invalidURL
        }
        return try await performAbsoluteRequest(
            url: url,
            method: method,
            body: body,
            headers: headers,
            accept: accept,
            includeAuthorization: includeAuthorization
        )
    }
    
    private func buildURL(fromPath path: String) throws -> URL {
        if let absolute = URL(string: path), absolute.scheme != nil {
            return absolute
        }
        
        let trimmedBase = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        let trimmedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard let url = URL(string: "\(trimmedBase)/\(trimmedPath)") else {
            throw KlarnaServiceError.invalidURL
        }
        return url
    }
    
    private func sendRequest(
        url: URL,
        method: KlarnaHTTPMethod,
        body: (any Encodable)?,
        headers: [String: String],
        accept: String?,
        includeAuthorization: Bool
    ) async throws -> KlarnaHTTPResponse {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        var finalHeaders = headers
        finalHeaders["User-Agent"] = finalHeaders["User-Agent"] ?? "msdk-demo-ios/1.0"
        if let accept = accept {
            finalHeaders["Accept"] = accept
        }
        if includeAuthorization {
            if finalHeaders["Authorization"] == nil {
                finalHeaders["Authorization"] = try createAuthorizationHeader()
            }
        }
        
        if let body = body {
            finalHeaders["Content-Type"] = finalHeaders["Content-Type"] ?? "application/json"
            let encoder = JSONEncoder()
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw KlarnaServiceError.invalidBody
            }
        }
        
        for (key, value) in finalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw KlarnaServiceError.invalidResponse
            }
            
            if httpResponse.statusCode >= 400 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw KlarnaServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            return KlarnaHTTPResponse(data: data, response: httpResponse)
        } catch let error as KlarnaServiceError {
            throw error
        } catch {
            throw KlarnaServiceError.networkError(error)
        }
    }
    
    // MARK: - Public API Methods
    
    /// Creates a new Klarna payment session
    /// - Parameter request: Session request with order details
    /// - Returns: Session response containing client token
    /// - API: POST /payments/v1/sessions
    /// - Docs: https://docs.klarna.com/api/payments/#operation/createCreditSession
    func createSession(request: SessionRequest) async throws -> KlarnaSessionResponse {
        let response = try await performRequest(
            path: "/payments/v1/sessions",
            method: .POST,
            body: request
        )
        return try response.decodeOrThrowServiceError(KlarnaSessionResponse.self)
    }
    
    /// Creates an order after authorization
    /// - Parameters:
    ///   - authorizationToken: The authorization token from the MSDK authorize flow
    ///   - request: Order request with purchase details
    /// - Returns: Order response with order ID
    /// - API: POST /payments/v1/authorizations/{authorizationToken}/order
    /// - Docs: https://docs.klarna.com/api/payments/#operation/createOrder
    func createOrder(authorizationToken: String, request: OrderRequest) async throws -> KlarnaOrderResponse {
        let encodedToken = authorizationToken.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? authorizationToken
        let response = try await performRequest(
            path: "/payments/v1/authorizations/\(encodedToken)/order",
            method: .POST,
            body: request
        )
        return try response.decodeOrThrowServiceError(KlarnaOrderResponse.self)
    }
}

// MARK: - Convenience Factory

extension KlarnaService {
    
    /// Creates a KlarnaService with the default Playground credentials
    /// - Note: In production, credentials should come from secure storage
    static func makeDefaultService() -> KlarnaService {
        // Default Playground credentials - replace with your own
        return KlarnaService(
            username: "14848c6f-9aec-4175-b5bd-39dfd31dfb38",
            password: "klarna_test_api_bGozP1VTU3g5OWVXLS9kRCNodTR5WSUxeUUoSHdYJGUsMTQ4NDhjNmYtOWFlYy00MTc1LWI1YmQtMzlkZmQzMWRmYjM4LDEsRjlGMXhFMFJjYnBrTXo2OUNTQW5Qb0RIdE9GRU4vaUc0clRvdk9IN3NQOD0"
        )
    }
}
