#!/bin/bash

# Exit if any command fails
set -e

# Check if argument was provided
if [ -z "$1" ]; then
  echo "Usage: ./jewelbuild.sh [build_target]"
  echo "Example: ./jewelbuild.sh apk"
  exit 1
fi

VALUE=$1
LOCK_FILE="./pubspec.lock"

# Delete pubspec.lock if it exists
if [ -f "$LOCK_FILE" ]; then
  rm "$LOCK_FILE"
  echo "File '$LOCK_FILE' deleted successfully."
else
  echo "File '$LOCK_FILE' does not exist."
fi

# Run 'flutter clean'
echo "Running 'flutter clean'..."
flutter clean

# Run 'flutter build <value>'
echo "Running 'flutter build $VALUE'..."
flutter build "$VALUE"
