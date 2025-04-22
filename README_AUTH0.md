# Auth0 Setup Guide for Lore Chrome Extension

This document provides step-by-step instructions for setting up Auth0 to work with the Lore Chrome Extension. Following these steps will enable automatic authentication for Chrome users and ensure a seamless experience.

## Table of Contents

1. [Create an Auth0 Account](#1-create-an-auth0-account)
2. [Set Up an Auth0 Application](#2-set-up-an-auth0-application)
3. [Configure Auth0 API (Optional)](#3-configure-auth0-api-optional)
4. [Configure Auth0 Rules for Supabase Integration](#4-configure-auth0-rules-for-supabase-integration)
5. [Configure the Chrome Extension Build](#5-configure-the-chrome-extension-build)
6. [Test the Authentication Flow](#6-test-the-authentication-flow)
7. [Production Deployment Considerations](#7-production-deployment-considerations)
8. [Troubleshooting](#8-troubleshooting)

## 1. Create an Auth0 Account

If you don't already have an Auth0 account:

1. Go to [Auth0's website](https://auth0.com/) and sign up for an account
2. Verify your email address
3. Create a new tenant (organization) during the sign-up process
4. Select your region (US, EU, AU, or JP)

## 2. Set Up an Auth0 Application

1. Log in to your Auth0 Dashboard
2. Navigate to "Applications" > "Applications" in the left sidebar
3. Click the "+ Create Application" button
4. Name your application (e.g., "Lore Chrome Extension")
5. Select "Single Page Application" as the application type
6. Click "Create"
7. Go to the "Settings" tab of your new application and configure:

   a. **Application URIs**:
   
      To find your Chrome extension's redirect URL:
      - Load your unpacked extension in Chrome
      - Open the Chrome console and run: `chrome.identity.getRedirectURL()`
      - The output will look something like: `https://abcdefghijklmnopqrstuvwxyzabcdef.chromiumapp.org/`
   
      Add this URL to the following fields:
      - **Allowed Callback URLs**: `https://<YOUR_EXTENSION_ID>.chromiumapp.org/`
      - **Allowed Logout URLs**: `https://<YOUR_EXTENSION_ID>.chromiumapp.org/`
      - **Allowed Web Origins**: `chrome-extension://<YOUR_EXTENSION_ID>`
      - **Allowed Origins (CORS)**: `chrome-extension://<YOUR_EXTENSION_ID>`

   b. **Advanced Settings**:
      - Under "Advanced Settings" > "Grant Types", ensure that "Implicit", "Authorization Code", and "Refresh Token" are checked

8. Save the changes

9. Make note of the following values from your application settings:
   - **Domain** (e.g., `your-tenant.auth0.com`)
   - **Client ID**

## 3. Configure Auth0 API (Optional)

If your Lore application requires API access:

1. Navigate to "Applications" > "APIs" in the left sidebar
2. Click the "+ Create API" button
3. Configure your API:
   - **Name**: "Lore API"
   - **Identifier**: A URI that represents your API (e.g., `https://api.lore.app`)
   - **Signing Algorithm**: RS256 (default)
4. Click "Create"
5. Make note of your API's Identifier (audience value)

## 4. Configure Auth0 Rules for Supabase Integration

To enable Auth0 users to authenticate with your Supabase backend:

1. Navigate to "Actions" > "Library" in the left sidebar
2. Click "Create" and select "Action"
3. Name the action (e.g., "Supabase JWT Custom Claims")
4. Select the "Login / Post Login" trigger
5. Replace the code in the editor with the following:

```javascript
/**
 * Add custom claims to the JWT that Supabase can use to authenticate users
 * @param {Event} event - Auth0 event
 */
exports.onExecutePostLogin = async (event, api) => {
  // Add custom claims that Supabase needs
  if (event.authorization) {
    api.idToken.setCustomClaim('sub', event.user.user_id);
    api.idToken.setCustomClaim('email', event.user.email);
    api.idToken.setCustomClaim('role', 'authenticated');
    
    // Add any additional custom claims your application needs
    api.idToken.setCustomClaim('app_metadata', event.user.app_metadata);
    api.idToken.setCustomClaim('user_metadata', event.user.user_metadata);
  }
};
```

6. Click "Deploy" to save and activate the action
7. Navigate to "Actions" > "Flows" in the left sidebar
8. Select the "Login" flow
9. Drag your new action into the flow and save changes

## 5. Configure the Chrome Extension Build

When building the Lore Chrome extension, provide your Auth0 credentials as environment variables:

```bash
AUTH0_DOMAIN=your-tenant.auth0.com \
AUTH0_CLIENT_ID=your-client-id \
AUTH0_AUDIENCE=https://your-api-identifier/ \
./build_extension.sh
```

Where:
- `AUTH0_DOMAIN` is your Auth0 domain (e.g., `your-tenant.auth0.com`)
- `AUTH0_CLIENT_ID` is the Client ID from your Auth0 application
- `AUTH0_AUDIENCE` is your API identifier (optional - only if you created an API in step 3)

## 6. Test the Authentication Flow

1. Load your Chrome extension in development mode
2. Open the extension popup
3. The extension should try to authenticate silently on startup
4. If silent authentication fails, click the login button
5. You should be redirected to the Auth0 login screen
6. After successful login, you should be redirected back to the extension
7. The extension should now show you as authenticated and allow you to post remarks

## 7. Production Deployment Considerations

When deploying to production:

1. **Chrome Web Store Requirements**:
   - You may need to verify your domain with Auth0
   - Ensure your privacy policy covers the authentication methods used
   - Get your extension approved by Auth0 if required

2. **Extension ID**:
   - In development, Chrome assigns a random ID to your extension
   - When publishing to the Chrome Web Store, you'll get a permanent ID
   - Update your Auth0 application settings with the production extension ID

3. **Callback URLs**:
   - Update the allowed callback URLs in Auth0 with your production extension ID

4. **Rate Limiting**:
   - Be aware of Auth0's rate limits for authentication operations
   - Implement appropriate error handling and retry logic

## 8. Troubleshooting

### Common Issues

1. **Auth0 returns an error "invalid_request" or "unauthorized_client"**:
   - Check that your redirect URI exactly matches what's in your Auth0 application settings
   - Verify your Client ID is correct

2. **Silent authentication always fails**:
   - This is expected behavior if the user hasn't previously authenticated
   - Users will need to explicitly log in at least once

3. **"Cross-origin authentication is not supported"**:
   - Ensure the "Allowed Origins (CORS)" includes `chrome-extension://<YOUR_EXTENSION_ID>`

4. **Token validation fails with Supabase**:
   - Check that your Auth0 rule correctly sets the claims Supabase expects
   - Verify your Supabase JWT settings match Auth0's JWT configuration

### Debugging Tools

1. **Auth0 Logs**:
   - Check "Auth0 Dashboard" > "Monitoring" > "Logs" for authentication errors

2. **Chrome Developer Tools**:
   - Use the Network tab to monitor the authentication requests
   - Check the Console for any JavaScript errors

3. **JWT Decoder**:
   - Use [jwt.io](https://jwt.io/) to decode and inspect tokens for correct claims

For further assistance, contact Auth0 support or refer to the [Auth0 documentation](https://auth0.com/docs).