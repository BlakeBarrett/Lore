![Lore-AppIcon.png](./web/icons/Icon-512.png)

# Lore

The shared, single source of truth for everything.

## Table of Contents

- [What is Lore](#what-is-lore)
- [Where is the data stored](#where-is-the-data-stored)
- [Setup Flutter](#setup-flutter)
- [Clone the Repository](#clone-the-repository)
- [Install dependencies](#install-dependencies)
- [Set up Supabase credentials](#set-up-supabase-credentials)
- [Run the App](#run-the-app)
  - [Linux Desktop](#linux-desktop)
  - [Chrome Web App](#chrome-web-app)
- [Deploy the Web App to Firebase](#deploy-the-web-app-to-firebase)
- [Add localizations](#add-localizations)
- [Console Application](#console-application)
- [Contributing](#contributing)
- [License](#license)
- [Screen Shots](#screen-shots)

## What is Lore?

Lore is a repository of knowledge. It is a shared, single source of truth for anything based on the md5sum of the file. It is a place for people to leave comments or notes on any file.

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

## Set up Supabase credentials

Lore connects to a Supabase backend. Create a `supabase.env` file in the project root with:

```
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
```

Obtain both values from your Supabase dashboard: **Settings → API**. The file is ignored by git (listed in `.gitignore`).

## Run the App

Navigate to the Lore project directory and run the app for your target platform:

### Linux Desktop

```bash
flutter run -d linux
```

> **Note:** The Supabase credentials in `supabase.env` must be valid for the app to launch successfully.

### Chrome Web App

```bash
flutter run -d chrome
```

Or build for production and serve locally:

```bash
flutter build web --release
cd build/web
python3 -m http.server 8085
# Open http://localhost:8085 in Chrome
```

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

## Console Application

Lore includes a command-line interface that provides access to core functionality without requiring the graphical interface.

### Building the Console App

Navigate to the Lore project directory and build the console app:

```bash
dart tool/build_console.dart
```

This will create an executable in `bin/lore` that you can run directly.

### Installing the Console App System-wide

Copy the executable to a directory in your PATH:

```bash
sudo cp bin/lore /usr/local/bin/
```

### Using the Console App

Here are some examples of how to use the console application:

```bash
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
```

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
