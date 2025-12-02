# iOS Klarna Mobile SDK Demo

A lightweight iOS demo application showcasing Klarna Mobile SDK (MSDK) integration with direct Klarna Playground API calls from native Swift.

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐        ┌─────────────────────┐
│         iOS SwiftUI App                 │  HTTP  │  Klarna Playground  │
│   (Klarna MSDK + Direct API Calls)      │───────▶│  API                │
│                                         │◀───────│                     │
└─────────────────────────────────────────┘        └─────────────────────┘
```

**Monolithic Design**: The iOS app communicates directly with the Klarna Playground API - no backend server required.

## 📁 Project Structure

```
msdk-demo/
├── msdk-demo/                           # iOS Swift app
│   ├── Views/
│   │   ├── ProductDetailView.swift      # Mock product page
│   │   ├── KlarnaPaymentViewController.swift  # UIKit SDK wrapper
│   │   └── KlarnaPaymentContainerView.swift   # SwiftUI container
│   ├── Services/
│   │   ├── KlarnaService.swift          # Core Klarna client (sessions/orders)
│   │   └── KlarnaNativeServices.swift   # Native replacements for former backend routes
│   ├── Models/
│   │   └── KlarnaModels.swift           # Klarna API data models
│   ├── ContentView.swift                # App entry point
│   ├── msdk_demoApp.swift
│   └── Info.plist                       # URL scheme configuration
│
├── SETUP.md                             # Detailed setup instructions
├── XCODE_SETUP.md                       # Xcode configuration guide
└── README.md                            # This file
```

## 🚀 Quick Start

### Prerequisites

- **macOS** with Xcode 15.0+
- **iOS 14.0+** deployment target
- **Klarna Playground credentials** (get from [Klarna Merchant Portal](https://portal.playground.klarna.com/))

### Step 1: Configure Klarna Credentials

Edit `msdk-demo/Services/KlarnaService.swift` in the `makeDefaultService()` method:

```swift
static func makeDefaultService() -> KlarnaService {
    return KlarnaService(
        username: "YOUR_KLARNA_USERNAME",
        password: "YOUR_KLARNA_API_KEY"
    )
}
```

### Step 2: Configure iOS App

**⚠️ IMPORTANT: Follow the detailed guide in [`XCODE_SETUP.md`](XCODE_SETUP.md)**

Quick summary:
1. Open `msdk-demo.xcodeproj` in Xcode
2. Add Swift Package: `https://github.com/klarna/klarna-mobile-sdk-spm` (v2.0.0)
3. Configure URL scheme `msdk-demo` in Info tab
4. Clean build folder (⇧⌘K)

See [`XCODE_SETUP.md`](XCODE_SETUP.md) for detailed step-by-step instructions.

### Step 3: Build and Run

1. Select iPhone simulator in Xcode (iPhone 15 Pro recommended)
2. Press **⌘+R** to build and run
3. Tap **"Buy with Klarna"** button on the product detail page
4. Complete the Klarna test payment flow

## 🎯 Features

### iOS App
- ✅ Native SwiftUI product detail page
- ✅ Mock e-commerce product ($259.00 T-Shirt)
- ✅ Klarna Mobile SDK integration with `KlarnaPaymentView`
- ✅ **Direct API calls** to Klarna Playground (no backend required)
- ✅ Complete payment event handling
- ✅ Modern iOS design with SF Symbols
- ✅ Error handling and loading states
- ✅ Custom URL scheme for app returns (`msdk-demo://`)

### Klarna API Integration
- ✅ Direct HTTPS calls to `https://api.playground.klarna.com`
- ✅ `POST /payments/v1/sessions` - Create payment session
- ✅ `POST /payments/v1/authorizations/{token}/order` - Finalize order
- ✅ Full replacement for the deprecated `/reference` backend via native `KlarnaNativeServices`
- ✅ Basic Auth authentication
- ✅ Clean Swift async/await implementation

## 🧩 Native Klarna Service Catalog

`Services/KlarnaNativeServices.swift` fans out the legacy backend routes into native, type-safe service objects:

- **Payments:** Sessions, authorizations, and customer-token creation.
- **Customer Tokens:** Read token metadata or place orders via `/customer-token/v1/tokens/{token}/order`.
- **Order Management:** Cancel, capture, refund, release remaining authorization, and fetch captures/orders.
- **Disputes:** `GET /disputes/v3/disputes` via `KlarnaDisputesService`.
- **Distribution Assets:** Download QR codes / payout assets using `KlarnaDistributionService`.
- **Hosted Payment Pages (HPP):** Create and poll HPP sessions without a proxy server.

Usage example:

```swift
let services = KlarnaNativeServices()
let disputes = try await services.disputes.listDisputes()
let orderResponse = try await services.orderManagement
    .captureOrder(orderId: orderId, request: KlarnaCaptureRequest(capturedAmount: 1000, description: "Deposit"))
```

Each method returns either high-level models or a reusable `KlarnaHTTPResponse` that exposes helper decoders for custom payloads.

## 🔄 Payment Flow

1. **User Action**: Taps "Buy with Klarna" on product page
2. **Create Session**: iOS app → Klarna API (`/payments/v1/sessions`)
   - Returns `client_token`
3. **Initialize SDK**: iOS initializes `KlarnaPaymentView` with token
4. **Load Payment**: SDK loads Klarna payment options
5. **Authorize**: User completes Klarna flow, SDK returns `authorization_token`
6. **Create Order**: iOS app → Klarna API (`/payments/v1/authorizations/{token}/order`)
   - Returns `order_id`
7. **Success**: Show confirmation to user

## 🧪 Testing

### Test Data (Klarna Playground)

When completing the Klarna payment flow, use:
- **Country**: United States
- **Email**: Any valid email format
- **Phone**: Any valid US phone number

For detailed test data: [Klarna Test Environment](https://docs.klarna.com/resources/test-environment/sample-customer-data/)

### Common Test Scenarios

1. **Successful Payment**: Complete the flow normally
2. **Payment Rejection**: Use test data that triggers rejection
3. **Invalid Token**: Modify authorization token before create-order

## 📝 Code Highlights

### Direct Klarna API Client

```swift
// KlarnaService.swift - Direct API calls to Klarna
class KlarnaService {
    static let playgroundBaseURL = "https://api.playground.klarna.com"
    
    func createSession(request: SessionRequest) async throws -> KlarnaSessionResponse {
        return try await postToKlarna(path: "/payments/v1/sessions", body: request)
    }
    
    func createOrder(authorizationToken: String, request: OrderRequest) async throws -> KlarnaOrderResponse {
        return try await postToKlarna(
            path: "/payments/v1/authorizations/\(authorizationToken)/order",
            body: request
        )
    }
}
```

### Klarna Mobile SDK Integration

```swift
// Initialize payment view
paymentView = KlarnaPaymentView(category: "klarna", eventListener: self)
paymentView.initialize(clientToken: clientToken, returnUrl: returnURL)

// Authorize payment
paymentView.authorize(autoFinalize: true, jsonData: orderDataJSON)

// Handle authorization callback
func klarnaAuthorized(paymentView: KlarnaPaymentView, approved: Bool, 
                      authToken: String?, finalizeRequired: Bool?) {
    if approved, let token = authToken {
        // Create order with token
    }
}
```

## 🔧 Troubleshooting

### "Module 'KlarnaMobileSDK' not found"
- ✅ Add Swift Package via Xcode (see Step 2)
- ✅ Clean build folder: **Product → Clean Build Folder** (⇧⌘K)
- ✅ Restart Xcode

### Session creation fails (401 Unauthorized)
- ✅ Verify credentials in `KlarnaService.swift`
- ✅ Use Klarna **Playground** credentials, not production

### "Payment view not initialized"
- ✅ Wait for SDK to fully initialize before authorize
- ✅ Check client token is valid (not expired)
- ✅ Verify session creation succeeded

## 📚 Additional Resources

- [Klarna Mobile SDK - iOS Documentation](https://docs.klarna.com/payments/mobile-payments/integrate-with-mobile-sdk/ios/)
- [Klarna Payments API Reference](https://docs.klarna.com/api/payments/)
- [Klarna Playground Portal](https://portal.playground.klarna.com/)
- [Setup Guide](./SETUP.md) - Detailed setup instructions

## 🎨 Customization

### Change Product Details
Edit `ProductDetailView.swift`:
```swift
private let productName = "Your Product"
private let productPrice = 299.00  // In dollars
private let productSKU = "SKU-456"
```

### Change Purchase Country/Currency
Edit `KlarnaPaymentContainerView.swift` in `makeOrderRequest()`:
```swift
purchaseCountry: "SE",  // Sweden
purchaseCurrency: "SEK",
locale: "sv-SE"
```

### Add Multiple Products
Modify `orderLines` array in `makeOrderRequest()` to include multiple items.

## 🔐 Security Notes

⚠️ **This is a demo app**. In production:

1. **Never hardcode credentials** in the iOS app
2. **Use a backend server** to handle API credentials securely
3. **Store credentials** using Keychain on iOS
4. **Implement proper authentication** for production
5. **Use environment-specific configurations**

## 📄 License

This is a demo application for educational purposes.

## 🤝 Support

For Klarna integration questions:
- [Klarna Developer Portal](https://developers.klarna.com/)
- [Klarna Support](https://developers.klarna.com/support/)

---

**Built with ❤️ using Swift and SwiftUI**
