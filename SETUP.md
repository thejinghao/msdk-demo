# iOS MSDK Demo Setup Guide

## Prerequisites

- Xcode 15.0 or later
- iOS 14.0+ deployment target
- Klarna Playground credentials (get from [Klarna Merchant Portal](https://portal.playground.klarna.com/))

## Step 1: Add Klarna Mobile SDK via Swift Package Manager

1. Open `msdk-demo.xcodeproj` in Xcode
2. Select the project in the Project Navigator
3. Select the `msdk-demo` target
4. Go to the **"Package Dependencies"** tab
5. Click the **"+"** button
6. Enter the package URL: `https://github.com/klarna/klarna-mobile-sdk-spm`
7. Click **"Add Package"**
8. Select **"Up to Next Major Version"** with version `2.0.0`
9. Click **"Add Package"** again
10. Ensure **KlarnaMobileSDK** is checked and click **"Add Package"**

## Step 2: Configure Info.plist and URL Scheme

**⚠️ See [`XCODE_SETUP.md`](XCODE_SETUP.md) for detailed instructions.**

Configure via Xcode's Info tab:
1. Add URL Type with scheme: `msdk-demo`

## Step 3: Configure Klarna Credentials

Edit `msdk-demo/Services/KlarnaService.swift` and update the `makeDefaultService()` method with your Klarna Playground credentials:

```swift
static func makeDefaultService() -> KlarnaService {
    return KlarnaService(
        username: "YOUR_KLARNA_USERNAME",    // e.g., "14848c6f-9aec-4175-b5bd-39dfd31dfb38"
        password: "YOUR_KLARNA_API_KEY"      // e.g., "klarna_test_api_..."
    )
}
```

**Where to get credentials:**
1. Go to [Klarna Merchant Portal](https://portal.playground.klarna.com/)
2. Navigate to Settings → API Keys
3. Copy your Username (UID) and API Key

## Step 4: Build and Run

1. In Xcode, select a simulator (iPhone 15 Pro or later recommended)
2. Press **Cmd+R** to build and run
3. The app will open with the product detail page
4. Tap **"Buy with Klarna"** to test the payment flow

## Architecture

This app uses a **monolithic architecture** with direct API calls:

```
iOS App → Klarna Playground API (https://api.playground.klarna.com)
```

No backend server is required. The app communicates directly with Klarna's API.

## Troubleshooting

### "Module 'KlarnaMobileSDK' not found"
- Verify the Swift Package was added correctly
- Try cleaning the build folder: **Product** → **Clean Build Folder** (Cmd+Shift+K)
- Restart Xcode

### Klarna session creation fails (401 Unauthorized)
- Verify your Klarna credentials in `KlarnaService.swift`
- Ensure you're using Klarna **Playground** credentials, not production
- Check that credentials are correctly formatted

### "Payment view not initialized"
- Wait for SDK to fully initialize before authorize
- Check client token is valid (not expired)
- Verify session creation succeeded

## Testing with Klarna Playground

Use these test credentials when prompted in the Klarna flow:
- Email: `test@example.com`
- Phone: Any valid format for your country
- Follow the Klarna UI prompts to complete the test payment

For more test data, visit: https://docs.klarna.com/resources/test-environment/sample-customer-data/

## API Endpoints Used

The app directly calls these Klarna Playground API endpoints:

1. **Create Session**: `POST https://api.playground.klarna.com/payments/v1/sessions`
   - Creates a payment session and returns `client_token`

2. **Create Order**: `POST https://api.playground.klarna.com/payments/v1/authorizations/{token}/order`
   - Finalizes the order after authorization and returns `order_id`

## Security Note

⚠️ **For demo purposes only.** In production:
- Never hardcode API credentials in the app
- Use a backend server to handle Klarna API authentication
- Store credentials securely using iOS Keychain
