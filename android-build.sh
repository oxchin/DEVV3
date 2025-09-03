#!/usr/bin/env bash
# Author: rezky nightky 2025
# ==============================================
# Enhanced Android Release Build Script (arm64-v8a)
# Features:
# - Interactive Java version selection
# - Automatic dependency checks and installation
# - Enhanced APK signing with validation
# - Build configuration options
# - Comprehensive error handling
# - Progress indicators and logging
# ==============================================

set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="2.0.0"
readonly CONFIG_FILE="$HOME/.android_build_config"
readonly LOG_FILE="build_$(date +%Y%m%d_%H%M%S).log"

# Removed apksigner usage due to EC algorithm incompatibility

# Default paths and settings
DEFAULT_KEYSTORE="$HOME/.android/keystore/rezky-cahya-sahputra-key.p12"
DEFAULT_ALIAS="rezky-cahya-sahputra-key"
JAVA_BASE_PATH="/usr/lib/jvm"

# Colors and formatting
readonly BLUE='\033[0;34m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Enhanced logging functions
log() { echo -e "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Removed resolve_apksigner function - no longer using apksigner due to EC algorithm issues
info() { log "${BLUE}[INFO]${NC} $*"; }
success() { log "${GREEN}[✓]${NC} $*"; }
warn() { log "${YELLOW}[⚠]${NC} $*"; }
error() { log "${RED}[✗]${NC} $*"; }
debug() { [[ "${DEBUG:-}" == "1" ]] && log "${PURPLE}[DEBUG]${NC} $*" || true; }
step() { log "\n${CYAN}${BOLD}▶ $*${NC}"; }

# Progress indicator
show_progress() {
    local duration=${1:-3}
    local message=${2:-"Processing"}
    local i=0
    
    echo -n "$message "
    while [ $i -lt $duration ]; do
        echo -n "."
        sleep 0.5
        ((i++))
    done
    echo " Done!"
}

# Error handling
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        error "Build failed with exit code $exit_code"
        error "Check log file: $LOG_FILE"
    fi
}
trap cleanup_on_exit EXIT

# Configuration management
load_config() {
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" || true
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
# Android Build Script Configuration
PREFERRED_JAVA_VERSION="$JAVA_VERSION"
DEFAULT_KEYSTORE_PATH="$KEYSTORE_PATH"
DEFAULT_KEY_ALIAS="$KEY_ALIAS"
ALWAYS_SIGN="${ALWAYS_SIGN:-false}"
ALWAYS_CLEAN="${ALWAYS_CLEAN:-false}"
EOF
    info "Configuration saved to $CONFIG_FILE"
}

# Java version management
detect_java_versions() {
    info "Detecting available Java versions..."
    if [[ ! -d "$JAVA_BASE_PATH" ]]; then
        error "Java installation directory not found: $JAVA_BASE_PATH"
        exit 1
    fi
    
    # Find Java versions
    JAVA_VERSIONS=($(find "$JAVA_BASE_PATH" -maxdepth 1 -name "java-*" -type d | sort))
    
    if [[ ${#JAVA_VERSIONS[@]} -eq 0 ]]; then
        error "No Java versions found in $JAVA_BASE_PATH"
        exit 1
    fi
    
    success "Found ${#JAVA_VERSIONS[@]} Java version(s)"
}

select_java_version() {
    detect_java_versions
    
    # If preferred version is set and exists, use it
    if [[ -n "${PREFERRED_JAVA_VERSION:-}" ]] && [[ -d "$JAVA_BASE_PATH/$PREFERRED_JAVA_VERSION" ]]; then
        JAVA_VERSION="$PREFERRED_JAVA_VERSION"
        info "Using preferred Java version: $JAVA_VERSION"
        return
    fi
    
    echo -e "\n${BOLD}Available Java versions:${NC}"
    for i in "${!JAVA_VERSIONS[@]}"; do
        local version_name=$(basename "${JAVA_VERSIONS[i]}")
        printf "%2d) %s\n" $((i+1)) "$version_name"
    done
    
    while true; do
        read -p "Select Java version (1-${#JAVA_VERSIONS[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#JAVA_VERSIONS[@]} ]]; then
            JAVA_VERSION=$(basename "${JAVA_VERSIONS[$((choice-1))]}")
            break
        else
            warn "Invalid selection. Please enter a number between 1 and ${#JAVA_VERSIONS[@]}"
        fi
    done
    
    export JAVA_HOME="$JAVA_BASE_PATH/$JAVA_VERSION"
    success "Selected Java version: $JAVA_VERSION"
    success "JAVA_HOME set to: $JAVA_HOME"
}

# Dependency validation
validate_dependencies() {
    step "Validating dependencies"
    
    local deps=("node" "npm" "npx" "gradle")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing_deps[*]}"
        info "Please install the missing dependencies and try again"
        exit 1
    fi
    
    # Check Java tools
    if [[ -n "${JAVA_HOME:-}" ]]; then
        if ! command -v "$JAVA_HOME/bin/java" >/dev/null 2>&1; then
            error "Java not found at: $JAVA_HOME/bin/java"
            exit 1
        fi
        
        # APK signing will use jarsigner (supports EC algorithms)
    fi
    
    success "All dependencies validated"
}

# Enhanced package management
manage_svelte_adapter() {
    step "Managing Svelte adapter"
    
    if npm ls --depth=0 @sveltejs/adapter-static >/dev/null 2>&1; then
        success "Svelte adapter-static already installed"
    else
        info "Installing @sveltejs/adapter-static..."
        if npm install -D @sveltejs/adapter-static; then
            success "Svelte adapter-static installed"
        else
            error "Failed to install @sveltejs/adapter-static"
            exit 1
        fi
    fi
}

# Enhanced build process
build_web_app() {
    step "Building static SPA for Capacitor"
    
    # Clean previous build
    if [[ -d "build" ]]; then
        info "Cleaning previous web build..."
        rm -rf build
    fi
    
    # Build with progress indicator
    info "Starting web build (MOBILE_BUILD=true)..."
    if MOBILE_BUILD=true npm run build > >(tee -a "$LOG_FILE") 2>&1; then
        success "Web build completed successfully"
    else
        error "Web build failed"
        exit 1
    fi
}

# Android build process
build_android_app() {
    step "Building Android application"
    
    # Clean Android build directories
    info "Cleaning Android build directories..."
    rm -rf android/app/build
    mkdir -p apk_output
    
    # Copy web assets
    info "Copying web assets to Android..."
    if npx cap copy android; then
        success "Assets copied successfully"
    else
        error "Failed to copy assets to Android"
        exit 1
    fi
    
    # Build APK
    info "Building release APK..."
    if (cd android && ./gradlew --no-daemon clean :app:assembleRelease); then
        success "Android build completed"
    else
        error "Android build failed"
        exit 1
    fi
}

# Enhanced APK handling
handle_apk_output() {
    step "Processing APK output"
    
    local apk_search_paths=(
        "apk_output/*.apk"
        "android/app/build/outputs/apk/release/*.apk"
        "android/app/build/outputs/apk/**/release/*.apk"
    )
    
    APK_PATH=""
    for path_pattern in "${apk_search_paths[@]}"; do
        APK_PATH=$(find $path_pattern 2>/dev/null | head -n1 || true)
        [[ -n "$APK_PATH" ]] && break
    done
    
    if [[ -z "$APK_PATH" ]]; then
        error "No APK found in expected locations"
        exit 1
    fi
    
    # Copy to output directory if not already there
    if [[ ! "$APK_PATH" =~ apk_output/ ]]; then
        info "Copying APK to output directory..."
        cp "$APK_PATH" apk_output/
        APK_PATH="apk_output/$(basename "$APK_PATH")"
    fi
    
    success "APK located at: $APK_PATH"
    
    # Get APK info
    local apk_size=$(du -h "$APK_PATH" | cut -f1)
    info "APK size: $apk_size"
}

# Enhanced APK renaming
rename_apk() {
    if [[ -z "${APK_PATH:-}" ]]; then
        warn "No APK path available for renaming"
        return
    fi
    
    # Extract version from package.json if available
    local suggested_name="app"
    if [[ -f "package.json" ]] && command -v jq >/dev/null 2>&1; then
        local app_name=$(jq -r '.name // "app"' package.json)
        local app_version=$(jq -r '.version // "1.0.0"' package.json)
        suggested_name="${app_name}-v${app_version}"
    fi
    
    read -p "👉 Enter APK name (default: $suggested_name): " CUSTOM_NAME
    CUSTOM_NAME="${CUSTOM_NAME:-$suggested_name}"
    
    if [[ -n "$CUSTOM_NAME" ]]; then
        local new_apk="apk_output/${CUSTOM_NAME}.apk"
        if mv "$APK_PATH" "$new_apk"; then
            APK_PATH="$new_apk"
            success "APK renamed to: $APK_PATH"
        else
            error "Failed to rename APK"
        fi
    fi
}

# Enhanced APK signing using jarsigner (supports EC algorithms)
sign_apk() {
    if [[ "${ALWAYS_SIGN:-}" == "true" ]]; then
        local sign_choice="y"
    else
        read -p "🔑 Sign APK with keystore? (y/N): " sign_choice
    fi
    
    if [[ ! "$sign_choice" =~ ^[Yy]$ ]]; then
        return
    fi
    
    # Use saved configuration or prompt
    KEYSTORE_PATH="${KEYSTORE_PATH:-$DEFAULT_KEYSTORE}"
    KEY_ALIAS="${KEY_ALIAS:-$DEFAULT_ALIAS}"
    
    if [[ ! -f "$KEYSTORE_PATH" ]]; then
        read -p "Keystore path [$KEYSTORE_PATH]: " input_keystore
        KEYSTORE_PATH="${input_keystore:-$KEYSTORE_PATH}"
        
        # Expand tilde
        if [[ "$KEYSTORE_PATH" == ~* ]]; then
            KEYSTORE_PATH="${KEYSTORE_PATH/#\~/$HOME}"
        fi
        
        if [[ ! -f "$KEYSTORE_PATH" ]]; then
            error "Keystore not found: $KEYSTORE_PATH"
            return 1
        fi
    fi
    
    read -p "Key alias [$KEY_ALIAS]: " input_alias
    KEY_ALIAS="${input_alias:-$KEY_ALIAS}"
    
    # Secure password input
    echo -n "Keystore password: "
    read -rs keystore_pass
    echo
    
    echo -n "Key password (Enter if same as keystore): "
    read -rs key_pass
    echo
    [[ -z "$key_pass" ]] && key_pass="$keystore_pass"
    
    info "Signing APK using jarsigner (EC algorithm compatible)..."
    if jarsigner -verbose -sigalg SHA256withECDSA -digestalg SHA-256 \
        -keystore "$KEYSTORE_PATH" \
        -storepass "$keystore_pass" \
        -keypass "$key_pass" \
        "$APK_PATH" "$KEY_ALIAS" 2>&1 | tee -a "$LOG_FILE"; then
        success "APK signed successfully"
        
        # Verify signature
        info "Verifying APK signature..."
        if jarsigner -verify -verbose -certs "$APK_PATH" 2>&1 | tee -a "$LOG_FILE"; then
            success "APK signature verified"
        else
            warn "APK signature verification failed"
        fi
    else
        error "APK signing failed"
        return 1
    fi
}

# Cleanup function
cleanup_build() {
    if [[ "${ALWAYS_CLEAN:-}" == "true" ]]; then
        local clean_choice="y"
    else
        read -p "🧹 Clean build artifacts? (y/N): " clean_choice
    fi
    
    if [[ "$clean_choice" =~ ^[Yy]$ ]]; then
        info "Cleaning build artifacts..."
        rm -rf build android/app/build
        success "Build artifacts cleaned"
    fi
    
    # Keep APK but clean temporary files
    find . -name "*.tmp" -delete 2>/dev/null || true
}

# Main execution
main() {
    # Header
    echo -e "${BOLD}${CYAN}"
    echo "========================================"
    echo "  Android Release Build Script v$SCRIPT_VERSION"
    echo "  Author: rezky nightky 2025"
    echo "========================================"
    echo -e "${NC}"
    
    # Load configuration
    load_config
    
    # Change to script directory
    readonly ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
    cd "$ROOT_DIR"
    info "Working directory: $ROOT_DIR"
    
    # Main build process
    select_java_version
    validate_dependencies
    manage_svelte_adapter
    build_web_app
    build_android_app
    handle_apk_output
    rename_apk
    sign_apk
    cleanup_build
    
    # Save configuration for next time
    read -p "💾 Save current settings as default? (y/N): " save_choice
    if [[ "$save_choice" =~ ^[Yy]$ ]]; then
        save_config
    fi
    
    # Final summary
    echo -e "\n${GREEN}${BOLD}🎉 Build completed successfully!${NC}"
    [[ -n "${APK_PATH:-}" ]] && success "Final APK: $APK_PATH"
    success "Build log: $LOG_FILE"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi