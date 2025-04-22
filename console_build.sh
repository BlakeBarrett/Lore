#!/bin/bash
# filepath: /media/ntfs/Users/Blake/Src/blakebarrett/Lore/console_build.sh
echo "Building Lore console app..."

# Create bin directory if it doesn't exist
mkdir -p bin

# Run the build
fvm flutter pub run tool/build_console.dart

exit_code=$?
if [ $exit_code -ne 0 ]; then
  echo "❌ Build failed"
  exit $exit_code
fi

echo "✅ Build completed successfully"
exit 0