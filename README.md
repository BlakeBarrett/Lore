![Lore-AppIcon.png](./web/icons/Icon-512.png)

# Lore

The shared, single source of truth for everything.

## Table of Contents

- [What is Lore](#what-is-lore)
- [Where is the data stored](#where-is-the-data-stored)
- [Setup Flutter](#setup-flutter)
- [Clone the Repository](#clone-the-repository)
- [Install dependencies](#install-dependencies)
- [Run the App](#run-the-app)
- [Deploy the Web App to Firebase](#deploy-the-web-app-to-firebase)
- [Add localizations](#add-localizations)
- [Chrome Extension](#chrome-extension)
- [Console Application](#console-application)
- [Contributing](#contributing)
- [License](#license)

## What is Lore?

 Lore is a repository of knowledge. It is a shared, single source of truth for anything based on the md5sum of the file.
 It is a place for people to leave comments or notes on any file.

## Where is the data stored?

At present, the plan is to store the data in Supabase. In the future data could be hosted in a managed or on-prem db.

## Setup Flutter

Make sure you have Flutter installed on your machine. If not, follow the Flutter installation guide: [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)

## Clone the Repository

Use the following command to clone the Lore repository:

```bash
git clone https://github.com/BlakeBarrett/Lore.git
```

## Install dependencies

After cloning the repository you will need to install the dependencies used by Lore.
To do so, run:

```bash
flutter pub get
```

## Run the App

Navigate to the Lore project directory and run the app:

```bash
cd Lore
flutter run
```

This command will build and run the app on your default device or emulator.

## Deploy the Web App to Firebase

```bash
flutter build web --release --no-tree-shake-icons
firebase deploy
```

#### Live Web app (nightly builds)
Firebase will deploy the web artifacts to the following URL, also where the latest build can be evaluated: [https://lore-5b6b8.web.app/](https://lore-5b6b8.web.app/)

## Add localizations

To add a new localization, follow the instructions in the [flutter_localizations](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization) package documentation.  
Then generate the `AppLocalizations` file by executing the command below in the terminal:

```bash
flutter gen-l10n
```

## Chrome Extension

Lore includes a Chrome extension that allows you to access Lore comments for any webpage you visit.

### Setting up Auth0 for the Chrome Extension

1. Create an Auth0 account at [auth0.com](https://auth0.com/) if you don't have one already
2. Create a new Application of type "Single Page Application"
3. In the Application settings:
   - Add your Chrome extension's redirect URI (you can get this by running `chrome.identity.getRedirectURL()` in your Chrome console)
   - Under Allowed Callback URLs, add the redirect URI
   - Under Allowed Web Origins, add `chrome-extension://<YOUR_EXTENSION_ID>`
   - Under Allowed Origins (CORS), add `chrome-extension://<YOUR_EXTENSION_ID>`
4. If using an Auth0 API:
   - Create an API in Auth0 Dashboard with a suitable identifier
   - Enable RBAC if needed

### Building the Chrome Extension

Navigate to the Lore project directory and build the Chrome extension:

```bash
# Make the build script executable
chmod +x build_extension.sh

# Build the Chrome extension with Auth0 credentials
AUTH0_DOMAIN=your-tenant.auth0.com \
AUTH0_CLIENT_ID=your-client-id \
AUTH0_AUDIENCE=https://your-api-identifier/ \
./build_extension.sh
```

This will create a Chrome extension package at `build/lore_extension.zip` and a directory of unpacked extension files at `build/chrome_extension`.

### Installing the Chrome Extension in Chrome

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable "Developer mode" using the toggle in the top-right corner
3. Click "Load unpacked" and select the `build/chrome_extension` directory

### Using the Chrome Extension

1. Click on the Lore extension icon in your browser toolbar
2. The extension will show Lore comments for the current URL
3. If not logged in, click the login icon and authenticate with your account
4. View existing remarks or add your own remarks about the current webpage

### Features

- Automatic MD5 hashing of the current URL to create a unique artifact ID
- Authentication with your Lore account
- View all remarks associated with the current webpage
- Add new remarks directly from your browser

## Console Application

Lore includes a command-line interface that provides access to core functionality without requiring the graphical interface.

### Building the Console App

Navigate to the Lore project directory and build the console app:

    # Build the console app using the Dart command
    fvm flutter pub run tool/build_console.dart

This will create an executable at `bin/lore` that you can run directly.

### Installing the Console App System-wide

Copy the executable to a directory in your PATH:

    sudo cp bin/lore /usr/local/bin/

### Using the Console App

Here are some examples of how to use the console application:

    # Show help information
    lore help

    # Get artifact by MD5 hash or text content
    lore get d3486ae9136e7856bc42212385ea797e
    lore get "Hello, world!"

    # Log in with a JWT token
    lore login <your-jwt-token>

    # Add a remark to an artifact
    lore add-remark d3486ae9136e7856bc42212385ea797e "This is an important artifact"

    # List your favorite artifacts
    lore list-favorites

### Available Commands

- `help` - Show help information
- `get <md5|text>` - Get artifact by MD5 hash or text
- `add-remark <md5> <text>` - Add a remark to an artifact
- `login <jwt>` - Login with a JWT token
- `list-favorites` - List your favorite artifacts
## Contributing

Contributions are welcome! Please read the [Contribution Guidelines](CONTRIBUTING.md) before making a contribution.

## License

This project is licensed under the [BSD 3-Clause License](LICENSE).

## Screen Shots
<img width="2124" alt="Lore-web-desktop-app" src="https://github.com/BlakeBarrett/Lore/assets/578572/357cdfa2-380c-4933-8604-bdf0b4ebcbfa">
<img width="912" alt="Screenshot" src="https://github.com/BlakeBarrett/Lore/assets/578572/1b43b4ac-7492-42a2-bd29-305ed8aca42c">
<img width="912" alt="Screenshot" src="https://github.com/BlakeBarrett/Lore/assets/578572/7752e399-10f5-4e6b-ab54-930a8e7e2be7">
