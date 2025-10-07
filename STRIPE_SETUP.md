# Stripe Payment Integration Setup

## Configuration

The Stripe payment integration has been configured with the following changes:

### 1. API Key Configuration
The Stripe API keys are configured in `Web.config`:
```xml
<add key="StripePublishableKey" value="pk_test_51H7qZKLkdIwHLdYJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJ" />
<add key="StripeSecretKey" value="sk_test_51H7qZKLkdIwHLdYJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJZJ" />
```

**Note**: These are test API keys. For production, replace with your actual Stripe API keys from the Stripe Dashboard.

### 2. Global Application Configuration
The Stripe configuration is now initialized globally in `Global.asax.cs`:
```csharp
protected void Application_Start()
{
    // Initialize Stripe configuration
    StripeConfiguration.ApiKey = ConfigurationManager.AppSettings["StripeSecretKey"];
    
    // ... other initialization code
}
```

This ensures the Stripe API key is set once when the application starts, making it available to all controllers and services.

### 3. Package References
The following packages are properly referenced:
- `Stripe.net` version 41.20.0
- `iTextSharp` version 5.5.13.4

## Usage

The Stripe payment flow is implemented in the `StripeController` with the following actions:

- `CreateCheckoutSession()` - Creates a Stripe checkout session
- `Success(string session_id)` - Handles successful payment verification
- `Error()` - Displays payment error messages

## Testing

To test the payment integration:

1. Use test credit card numbers provided by Stripe:
   - Success: `4242424242424242`
   - Decline: `4000000000000002`
   - Requires authentication: `4000002500003155`

2. Use any future expiry date and any 3-digit CVC

## Security Notes

- Never commit real API keys to version control
- Use Stripe's webhook signature verification for production
- Implement proper error handling and logging
- Consider using Stripe's client-side libraries for PCI compliance