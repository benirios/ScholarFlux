#!/usr/bin/env bash
# Run this AFTER installing Xcode from the App Store.
# Makes the iOS simulator work for Flutter.

set -e

if [ ! -d /Applications/Xcode.app ]; then
  echo "Xcode is not installed."
  echo "Install it from the App Store: https://apps.apple.com/app/xcode/id497799835"
  echo "Then open Xcode once, accept the license, and run this script again."
  exit 1
fi

echo "Selecting Xcode (may ask for your password)..."
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

echo "Running Xcode first-launch setup..."
sudo xcodebuild -runFirstLaunch

if ! command -v pod &> /dev/null; then
  echo "Installing CocoaPods..."
  brew install cocoapods
else
  echo "CocoaPods already installed."
fi

echo ""
echo "Done. To run the app on the iOS simulator:"
echo "  1. Open Simulator:  open -a Simulator"
echo "  2. Run the app:     cd $(dirname "$0") && flutter run"
