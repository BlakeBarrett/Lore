# Lore Console Application

A command-line interface for Lore - the shared, single source of truth for everything. This console app allows you to manage artifacts and remarks from the terminal without needing the Flutter GUI.

## 🚀 Quick Start

### Prerequisites

- [Dart SDK](https://dart.dev/get-dart) (version 3.0 or higher)
- [Flutter SDK](https://flutter.dev) (for integrated development)
- Access to the Lore project files

### Flutter Integration (New!)

The console app now appears as a device target in Flutter:

```bash
# Enable Flutter custom devices (one-time setup)
flutter config --enable-custom-devices

# List all devices (including console)
flutter devices
# Output includes: Lore Console (mobile) • lore-console • linux-x64

# VS Code Integration
# - Open Command Palette (Ctrl+Shift+P)
# - Run "Tasks: Run Task"
# - Choose from console tasks like "Console: Help", "Console: Login", etc.
```

### Build the Console App

1. Navigate to the Lore project directory:
   ```bash
   cd /path/to/Lore
   ```

2. Build the console executable:
   ```bash
   dart tool/build_console.dart
   ```

3. The executable will be created at `bin/lore` and made executable automatically.

### First Run

```bash
# Show help and available commands
./bin/lore help

# Check remarks for any file
./bin/lore ./README.md

# Get artifact information by MD5 hash
./bin/lore get abc123def456...

# Or use Flutter integration tools
dart tool/flutter_console.dart run help
```

## 🛠️ Development Integration

### VS Code Tasks
Access these through Command Palette → "Tasks: Run Task":
- **Build Lore Console**: Compile the executable
- **Console: Help**: Show help message
- **Console: Login**: Open web browser for authentication
- **Console: Claim File**: Claim ownership of a file (with prompt)
- **Console: Show File Remarks**: Show remarks for a file (with prompt)
- **Flutter: List Devices**: Show all Flutter devices including console

### Flutter Device Target
The console now appears in `flutter devices` as "Lore Console (mobile)":
```bash
flutter devices
# Shows: Lore Console (mobile) • lore-console • linux-x64 • Lore Console App 1.0.0
```

You can select it as a target in VS Code's device picker!

## 📋 Commands

### File Path Mode (Enhanced)
```bash
# Display remarks for any file path
./bin/lore <file_path>

# Examples:
./bin/lore ./README.md
./bin/lore src/main.dart
./bin/lore /absolute/path/to/file.txt
```

### File Claiming (New Feature)
```bash
# Claim ownership of a file with automatic "First seen by" remark
lore claim <file_path>

# This creates a remark like: "First seen by user@example.com. Created 2025-05-23"
# Examples:
lore claim ./README.md
lore claim src/important_file.dart
```

### Artifact Management
```bash
# Get artifact by MD5 hash or text content
lore get <md5|text>

# Examples:
lore get abc123def456789...
lore get "some text content"
```

### Remarks Management
```bash
# Add a remark to an artifact (requires authentication)
lore add-remark <md5> <text>

# Print top remarks for a file or MD5 hash
lore print-remarks <file|md5>

# Examples:
lore add-remark abc123def456 "This file needs refactoring"
lore print-remarks ./src/main.dart
lore print-remarks abc123def456789
```

### Authentication (Enhanced)
```bash
# Login via web browser (new - recommended method)
lore login

# Login with JWT token from Supabase (existing method)
lore login <jwt_token>

# List your favorite artifacts (requires authentication)
lore list-favorites
```

### File Claiming (New Feature)
```bash
# Claim a file as "First seen by user" with creation date
lore claim <file_path>

# Examples:
lore claim ./README.md
lore claim src/main.dart
lore claim /absolute/path/to/file.txt
```

### Help
```bash
# Show help message
lore help
```

## 🔧 Configuration

The console app uses environment variables for Supabase authentication. These are configured in the `supabase.env` file in the project root.

### Environment Variables

The `supabase.env` file should contain:
```env
SUPABASE_URL='your_supabase_project_url'
SUPABASE_ANON_KEY='your_supabase_anonymous_key'
```

**Note:** The current configuration file is already set up for the Lore project's Supabase instance.

## 🏗️ Build Process

The build process is automated through the `tool/build_console.dart` script, which:

1. Creates a `bin/` directory if it doesn't exist
2. Compiles `lib/console_main.dart` into a native executable
3. Places the executable at `bin/lore`
4. Makes the file executable on Linux/macOS systems

### Manual Build
```bash
# Alternative manual build command
dart compile exe lib/console_main.dart -o bin/lore
chmod +x bin/lore  # On Linux/macOS
```

## 🏷️ File Claiming Feature

The console app now supports "claiming" files - adding an initial remark that indicates who first documented the file and when it was created.

### How It Works

When you run `lore claim <file>`, the app will:

1. **Check Authentication**: Ensure you're logged in
2. **Verify File Exists**: Confirm the file path is valid
3. **Calculate MD5**: Generate a hash of the file contents
4. **Check Existing Remarks**: Prevent claiming already documented files
5. **Create Claim Remark**: Add a remark like: `"First seen by user@example.com. Created 2025-05-23"`

### Example Usage

```bash
# Claim a new file
lore claim ./src/new_feature.dart
# Output: ✅ File claimed successfully!

# Try to claim an already documented file
lore claim ./README.md
# Output: ⚠️ File already has remarks. Cannot claim already documented files.
```

### Benefits

- **Ownership Tracking**: Know who first documented each file
- **Timeline**: See when files were first added to the knowledge base
- **Prevents Duplicates**: Won't override existing documentation
- **Historical Context**: Provides valuable project timeline information

## 🌐 Web Authentication

The new web-based authentication makes it easier to get started without manually extracting JWT tokens.

The console app supports JWT-based authentication with Supabase:

1. **Anonymous Access**: You can read artifacts and remarks without authentication
2. **Authenticated Access**: Required for adding remarks, managing favorites, and other write operations
3. **JWT Token**: Obtain from the Supabase dashboard or through the Flutter app's authentication flow

### Getting a JWT Token

#### Option 1: Web Browser Authentication (New - Recommended)
```bash
# Open web browser for authentication
lore login

# This will:
# 1. Open your default browser to Supabase auth page
# 2. Allow you to authenticate with GitHub
# 3. Provide instructions to copy the JWT token
# 4. Use: lore login <copied_jwt_token>
```

#### Option 2: Manual Token Extraction
1. Use the Flutter app to authenticate
2. Extract the JWT token from the session
3. Use `lore login <jwt_token>` to authenticate the console app

## 📁 File Structure

```
lib/
├── console_main.dart        # Entry point for console app
├── lore_console.dart        # Main console logic and command handling
├── supabase_service.dart    # Singleton service for Supabase client management
├── lore_api.dart           # API layer for Lore operations
├── md5_utils.dart          # MD5 calculation utilities
└── artifact.dart          # Data models

tool/
└── build_console.dart      # Build script for console executable

bin/
└── lore                    # Compiled executable (created after build)
```

## 🧩 Architecture

The console app uses a clean architecture with these key components:

1. **SupabaseService**: Singleton pattern for managing Supabase client initialization
   - `initializeForConsole()`: Uses dotenv for environment variables
   - `initializeForFlutter()`: Uses externally provided client
   - `dispose()`: Cleanup method to prevent hanging processes

2. **LoreConsole**: Main console application logic
   - Async factory pattern (`LoreConsole.create()`) for proper initialization
   - Command routing and argument parsing
   - File path detection and MD5 calculation

3. **LoreAPI**: Abstraction layer for all Lore operations
   - Artifact loading and saving
   - Remarks management
   - User authentication state

## 🐛 Troubleshooting

### Build Errors

If you encounter build errors:

1. **Dependency Issues**: Run `dart pub get` to ensure all dependencies are installed
2. **Flutter Dependencies**: The console app is built to avoid Flutter dependencies
3. **Permission Issues**: Ensure you have write permissions to the `bin/` directory

### Runtime Errors

1. **Supabase Connection**: Verify the `supabase.env` file exists and contains valid credentials
2. **File Not Found**: When using file paths, ensure the file exists and is readable
3. **Authentication**: Some commands require JWT authentication - use `lore login <jwt>` first

### Common Issues

```bash
# Error: SupabaseService not initialized
# Solution: The app should auto-initialize, but check supabase.env file

# Error: File not found
# Solution: Use absolute paths or ensure you're in the correct directory
./bin/lore /absolute/path/to/file.txt

# Error: Permission denied
# Solution: Make sure the executable has proper permissions
chmod +x bin/lore
```

## 🔄 Development

### Adding New Commands

1. Add the command case to the switch statement in `LoreConsole._handleArgs()`
2. Implement the command logic as a private method
3. Update the help text in `_printUsage()`
4. Add command-specific usage in `_printCommandUsage()`

### Testing

```bash
# Test the build process
dart tool/build_console.dart

# Test basic functionality
./bin/lore help
./bin/lore ./README.md

# Test with different file types
./bin/lore pubspec.yaml
./bin/lore lib/main.dart
```

## 📝 Examples

### Basic Usage
```bash
# Build the app
dart tool/build_console.dart

# Check remarks for project files
./bin/lore ./pubspec.yaml
./bin/lore ./lib/main.dart
./bin/lore ./README.md

# Get help
./bin/lore help
```

### Advanced Usage
```bash
# Add a remark (requires authentication)
./bin/lore login eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
./bin/lore add-remark abc123def "This needs optimization"

# Check remarks for a specific hash
./bin/lore print-remarks abc123def456789

# List your favorites
./bin/lore list-favorites
```

## 🔗 Related

- [Main Lore Flutter App](./README.md)
- [Supabase Documentation](https://supabase.io/docs)
- [Dart CLI Documentation](https://dart.dev/tools/dart-tool)

---

**Note**: This console app provides a lightweight interface to Lore's core functionality without requiring the full Flutter environment, making it perfect for CI/CD pipelines, server environments, or quick command-line access to your artifacts and remarks.
