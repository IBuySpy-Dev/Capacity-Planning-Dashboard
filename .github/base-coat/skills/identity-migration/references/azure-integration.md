# Azure Entra ID Integration

Patterns for integrating ASP.NET Core Identity with Azure Entra ID (formerly Azure AD).

## Configuring OpenID Connect (OIDC)

```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
        .AddMicrosoftIdentityWebApp(Configuration.GetSection("AzureAd"));

    services.AddAuthorization(options =>
        options.AddPolicy("AdminOnly", p => p.RequireRole("admin")));
}

public void Configure(IApplicationBuilder app)
{
    app.UseAuthentication();
    app.UseAuthorization();
}
```

## appsettings.json

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "common",
    "ClientId": "<your-app-id>",
    "Audience": "api://<your-api-app-id>",
    "CallbackPath": "/signin-oidc"
  }
}
```

## Hybrid Auth (Local + Entra ID)

```csharp
services.AddAuthentication(options =>
{
    options.DefaultScheme = "MultiScheme";
    options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
})
.AddCookie("LocalIdentity")
.AddMicrosoftIdentityWebApp(Configuration.GetSection("AzureAd"),
    cookieScheme: "MicrosoftCookie");
```

## OAuth2 Providers

```csharp
services.AddAuthentication()
    .AddMicrosoftAccount(options =>
    {
        options.ClientId = Configuration["Authentication:Microsoft:ClientId"];
        options.ClientSecret = Configuration["Authentication:Microsoft:ClientSecret"]; // from Key Vault
    })
    .AddGoogle(options =>
    {
        options.ClientId = Configuration["Authentication:Google:ClientId"];
        options.ClientSecret = Configuration["Authentication:Google:ClientSecret"]; // from Key Vault
    });
```

## OIDC Token Refresh

```csharp
public async Task<string> RefreshTokenAsync(string refreshToken)
{
    var discovery = await GetDiscoveryDocumentAsync();
    var response = await _httpClient.RequestRefreshTokenAsync(new RefreshTokenRequest
    {
        Address = discovery.TokenEndpoint,
        ClientId = "your-app-id",
        ClientSecret = Environment.GetEnvironmentVariable("OIDC_CLIENT_SECRET"), // never hardcode
        RefreshToken = refreshToken
    });
    return response.AccessToken;
}
```

> **Security note:** Always load client secrets from Key Vault or environment variables.
> Never store secrets in `appsettings.json` or source control.
