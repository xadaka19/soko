# SokoFiti APK Build Guide

## 🔍 How to Locate the Debug APK

### Quick Answer
After running `flutter build apk --debug`, your APK will be located at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

### Step-by-Step Instructions

1. **Build the Debug APK**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

2. **Locate the APK File**
   - **Path**: `build/app/outputs/flutter-apk/app-debug.apk`
   - **Full Path**: `/mnt/chromeos/MyFiles/Downloads/soko/build/app/outputs/flutter-apk/app-debug.apk`

3. **Use the Helper Script**
   ```bash
   ./find_apk.sh
   ```
   This script will automatically locate and display information about your APK files.

### APK File Details

- **Debug APK**: `app-debug.apk` (for testing)
- **Release APK**: `app-release.apk` (for production)
- **Size**: Typically 20-50MB
- **Package Name**: `ke.sokofiti.app.debug` (debug version)

### Installation Options

#### Option 1: Install via ADB
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

#### Option 2: Copy to Downloads
```bash
cp build/app/outputs/flutter-apk/app-debug.apk ~/Downloads/sokofiti-debug.apk
```

#### Option 3: Direct Transfer
1. Navigate to the APK location in file manager
2. Copy `app-debug.apk` to your device
3. Enable "Install from Unknown Sources" on Android
4. Install the APK

## 🔧 Build Configuration

### Debug Build Features
- **Debugging Enabled**: Full debugging capabilities
- **Network Security**: Allows HTTP traffic for development
- **Package Suffix**: `.debug` added to package name
- **Signing**: Uses debug keystore (automatic)

### Build Variants
```bash
# Debug build (for development/testing)
flutter build apk --debug

# Release build (for production)
flutter build apk --release

# Profile build (for performance testing)
flutter build apk --profile
```

## 📱 Testing the APK

### Authentication Testing
The debug APK includes:
- ✅ Google Sign-In support
- ✅ Firebase authentication
- ✅ Network debugging enabled
- ✅ API connectivity to sokofiti.ke

### Features to Test
1. **User Registration/Login**
   - Email/password registration
   - Google Sign-In
   - Profile management

2. **Listings**
   - Browse listings
   - Search functionality
   - Category filtering

3. **Core Features**
   - Create listings
   - Contact sellers
   - Favorites
   - Messaging

## 🌐 Web vs APK Differences

### Web Limitations
- Google Sign-In popup may be blocked
- Limited file access
- Browser security restrictions

### APK Advantages
- Full native functionality
- Better performance
- Complete feature access
- Offline capabilities

## 🚨 Troubleshooting

### Build Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug --verbose

# Check for errors
flutter doctor
flutter analyze
```

### APK Not Found
1. Check if build completed successfully
2. Look for error messages in terminal
3. Ensure Android SDK is properly configured
4. Run `./find_apk.sh` to search for APK files

### Installation Issues
1. Enable "Install from Unknown Sources"
2. Check device storage space
3. Uninstall previous versions
4. Use ADB for installation

## 📋 Quick Commands

```bash
# Complete build process
flutter clean && flutter pub get && flutter build apk --debug

# Find APK location
./find_apk.sh

# Install on connected device
adb install build/app/outputs/flutter-apk/app-debug.apk

# Copy to Downloads
cp build/app/outputs/flutter-apk/app-debug.apk ~/Downloads/
```

## 🔗 Related Files

- `android/app/build.gradle.kts` - Android build configuration
- `android/app/src/main/AndroidManifest.xml` - App permissions and settings
- `find_apk.sh` - Helper script to locate APK files
- `lib/config/environment.dart` - Environment configuration

---

**Note**: The debug APK is for testing purposes only. For production deployment, use the release build with proper signing configuration.
