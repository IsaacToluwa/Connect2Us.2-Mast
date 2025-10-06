Register-PackageSource -Name "nuget.org" -Location "https://api.nuget.org/v3/index.json" -ProviderName NuGet -Force
Install-Package Stripe.net -Source nuget.org