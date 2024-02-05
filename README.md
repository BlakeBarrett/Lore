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
- [Deploy the Web App to Firebase](#deploy-the-web-app-to-firebase).
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
Firebase will deploy the web artifacts to: [https://lore-5b6b8.web.app/](https://lore-5b6b8.web.app/)

## Contributing

Contributions are welcome! Please read the [Contribution Guidelines](CONTRIBUTING.md) before making a contribution.

## License

This project is licensed under the [BSD 3-Clause License](LICENSE).
