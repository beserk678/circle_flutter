#!/bin/bash

# Circle App Deployment Script
# This script handles deployment to various platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="circle-app"
FIREBASE_PROJECT_ID="your-firebase-project-id"
VERSION=$(grep 'version:' pubspec.yaml | cut -d ' ' -f 2)

echo -e "${BLUE}🚀 Circle App Deployment Script${NC}"
echo -e "${BLUE}Version: $VERSION${NC}"
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check Firebase CLI
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI is not installed"
        print_info "Install with: npm install -g firebase-tools"
        exit 1
    fi
    
    # Check if logged into Firebase
    if ! firebase projects:list &> /dev/null; then
        print_error "Not logged into Firebase CLI"
        print_info "Login with: firebase login"
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Clean and get dependencies
prepare_build() {
    print_info "Preparing build..."
    
    flutter clean
    flutter pub get
    
    print_status "Build preparation completed"
}

# Run tests
run_tests() {
    print_info "Running tests..."
    
    # Run unit tests
    if flutter test; then
        print_status "All tests passed"
    else
        print_error "Tests failed"
        exit 1
    fi
}

# Build for web
build_web() {
    print_info "Building for web..."
    
    flutter build web --release --web-renderer html
    
    # Optimize web build
    print_info "Optimizing web build..."
    
    # Add service worker for PWA
    cp web/sw.js build/web/
    
    print_status "Web build completed"
}

# Build for Android
build_android() {
    print_info "Building for Android..."
    
    # Build APK
    flutter build apk --release --split-per-abi
    
    # Build App Bundle
    flutter build appbundle --release
    
    print_status "Android build completed"
}

# Build for iOS
build_ios() {
    print_info "Building for iOS..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        flutter build ios --release --no-codesign
        print_status "iOS build completed"
    else
        print_warning "iOS build skipped (requires macOS)"
    fi
}

# Deploy to Firebase Hosting
deploy_web() {
    print_info "Deploying to Firebase Hosting..."
    
    # Deploy Firestore rules
    firebase deploy --only firestore:rules --project $FIREBASE_PROJECT_ID
    
    # Deploy Storage rules
    firebase deploy --only storage --project $FIREBASE_PROJECT_ID
    
    # Deploy web app
    firebase deploy --only hosting --project $FIREBASE_PROJECT_ID
    
    print_status "Web deployment completed"
}

# Deploy to Google Play Store (requires manual upload)
deploy_android() {
    print_info "Android deployment preparation..."
    
    APK_PATH="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
    BUNDLE_PATH="build/app/outputs/bundle/release/app-release.aab"
    
    if [ -f "$BUNDLE_PATH" ]; then
        print_status "App Bundle ready for Google Play Store upload:"
        print_info "Path: $BUNDLE_PATH"
        print_info "Upload manually to Google Play Console"
    else
        print_error "App Bundle not found"
    fi
}

# Deploy to App Store (requires manual upload)
deploy_ios() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "iOS deployment preparation..."
        
        IPA_PATH="build/ios/ipa/circle_app.ipa"
        
        if [ -f "$IPA_PATH" ]; then
            print_status "IPA ready for App Store upload:"
            print_info "Path: $IPA_PATH"
            print_info "Upload using Xcode or Transporter app"
        else
            print_warning "IPA not found. Build with Xcode for App Store submission"
        fi
    else
        print_warning "iOS deployment skipped (requires macOS)"
    fi
}

# Update version
update_version() {
    print_info "Updating version..."
    
    # This would typically increment version numbers
    # For now, just display current version
    print_info "Current version: $VERSION"
    print_info "Update version in pubspec.yaml before deployment"
}

# Main deployment function
deploy() {
    local platform=$1
    
    case $platform in
        "web")
            check_prerequisites
            prepare_build
            run_tests
            build_web
            deploy_web
            ;;
        "android")
            check_prerequisites
            prepare_build
            run_tests
            build_android
            deploy_android
            ;;
        "ios")
            check_prerequisites
            prepare_build
            run_tests
            build_ios
            deploy_ios
            ;;
        "all")
            check_prerequisites
            prepare_build
            run_tests
            build_web
            build_android
            build_ios
            deploy_web
            deploy_android
            deploy_ios
            ;;
        *)
            print_error "Invalid platform. Use: web, android, ios, or all"
            exit 1
            ;;
    esac
}

# Show usage
show_usage() {
    echo "Usage: $0 [platform]"
    echo ""
    echo "Platforms:"
    echo "  web      - Deploy to Firebase Hosting"
    echo "  android  - Build for Google Play Store"
    echo "  ios      - Build for App Store"
    echo "  all      - Build for all platforms"
    echo ""
    echo "Examples:"
    echo "  $0 web"
    echo "  $0 android"
    echo "  $0 all"
}

# Main script
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

PLATFORM=$1

print_info "Starting deployment for: $PLATFORM"
deploy $PLATFORM
print_status "Deployment completed successfully! 🎉"