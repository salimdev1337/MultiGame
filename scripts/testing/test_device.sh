#!/bin/bash
# test_device.sh - Automated device testing helper for MultiGame
# Usage: ./test_device.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Package name (update after changing from com.example.multigame)
PACKAGE_NAME="com.example.multigame"

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}  MultiGame Device Testing Script${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if device is connected
check_device() {
    echo "Checking for connected devices..."
    if ! adb devices | grep -q "device$"; then
        print_error "No device connected!"
        print_info "Please connect a device via USB and enable USB debugging"
        exit 1
    fi

    local device_count=$(adb devices | grep "device$" | wc -l)
    if [ $device_count -gt 1 ]; then
        print_warning "Multiple devices connected. Using first device."
    fi

    print_success "Device connected"

    # Get device info
    local device_model=$(adb shell getprop ro.product.model)
    local android_version=$(adb shell getprop ro.build.version.release)
    local api_level=$(adb shell getprop ro.build.version.sdk)

    echo ""
    print_info "Device: $device_model"
    print_info "Android: $android_version (API $api_level)"
    echo ""
}

# Build release APK
build_apk() {
    echo "Building release APK..."
    echo ""

    # Clean build
    flutter clean > /dev/null 2>&1
    flutter pub get > /dev/null 2>&1

    # Build
    if flutter build apk --release; then
        print_success "Build successful"

        # Check APK size
        local apk_path="build/app/outputs/flutter-apk/app-release.apk"
        if [ -f "$apk_path" ]; then
            local apk_size=$(du -h "$apk_path" | cut -f1)
            print_info "APK size: $apk_size"
        fi
    else
        print_error "Build failed!"
        exit 1
    fi
    echo ""
}

# Install APK on device
install_apk() {
    echo "Installing APK on device..."

    local apk_path="build/app/outputs/flutter-apk/app-release.apk"

    if [ ! -f "$apk_path" ]; then
        print_error "APK not found at $apk_path"
        exit 1
    fi

    # Check if app already installed
    if adb shell pm list packages | grep -q "$PACKAGE_NAME"; then
        print_warning "App already installed. Reinstalling..."
        if adb install -r "$apk_path" > /dev/null 2>&1; then
            print_success "App reinstalled successfully"
        else
            print_error "Reinstallation failed"
            exit 1
        fi
    else
        if adb install "$apk_path" > /dev/null 2>&1; then
            print_success "App installed successfully"
        else
            print_error "Installation failed"
            exit 1
        fi
    fi
    echo ""
}

# Launch app
launch_app() {
    echo "Launching app..."

    if adb shell am start -n "$PACKAGE_NAME/.MainActivity" > /dev/null 2>&1; then
        print_success "App launched"
    else
        print_error "Failed to launch app"
        exit 1
    fi

    sleep 2
    echo ""
}

# Run quick smoke tests
smoke_tests() {
    echo "Running quick smoke tests..."
    echo ""

    # Check if app is running
    if adb shell pidof $PACKAGE_NAME > /dev/null 2>&1; then
        print_success "App is running"
    else
        print_error "App is not running"
        return 1
    fi

    # Check memory usage
    local mem_usage=$(adb shell dumpsys meminfo $PACKAGE_NAME | grep "TOTAL" | awk '{print $2}')
    if [ ! -z "$mem_usage" ]; then
        local mem_mb=$((mem_usage / 1024))
        print_info "Memory usage: ${mem_mb}MB"

        if [ $mem_mb -gt 300 ]; then
            print_warning "High memory usage detected!"
        fi
    fi

    echo ""
}

# Monitor logs
monitor_logs() {
    echo "Monitoring app logs (press Ctrl+C to stop)..."
    echo ""

    adb logcat -c  # Clear old logs
    adb logcat | grep -i --color=auto "flutter\|firebase\|multigame\|crash\|exception\|error"
}

# Main execution
main() {
    check_device

    # Ask if should build
    read -p "Build new APK? (y/n, default: y): " build_choice
    build_choice=${build_choice:-y}

    if [ "$build_choice" = "y" ] || [ "$build_choice" = "Y" ]; then
        build_apk
    else
        print_info "Skipping build"
        echo ""
    fi

    install_apk
    launch_app
    smoke_tests

    # Ask if should monitor logs
    read -p "Monitor logs? (y/n, default: n): " log_choice
    log_choice=${log_choice:-n}

    if [ "$log_choice" = "y" ] || [ "$log_choice" = "Y" ]; then
        monitor_logs
    else
        print_success "Testing complete!"
        echo ""
        print_info "Next steps:"
        echo "  1. Manually test all game modes"
        echo "  2. Test network conditions (Wi-Fi, mobile, offline)"
        echo "  3. Check performance (FPS, memory, battery)"
        echo "  4. Record results in test report"
        echo ""
        print_info "See docs/DEVICE_TESTING_GUIDE.md for full test checklist"
    fi
}

# Run main function
main
