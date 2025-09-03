# SokoFiti Assets

This directory contains assets for the SokoFiti mobile application.

## Directory Structure

```
assets/
├── images/          # App images and graphics
├── icons/           # App icons and logos
└── README.md        # This file
```

## Logo Usage

The SokoFiti logo is implemented as a Flutter widget (`SokofitiLogo`) located in `lib/widgets/sokofiti_logo.dart` that uses your real logo images.

### Logo Files:
- **`sokofiti_logo.png`** - Main logo (dark/colored version)
- **`sokofiti_logo_white_logo.png`** - White version for dark backgrounds

### Features:
- **Real Logo Images**: Uses your actual SokoFiti logo files
- **Dual Versions**: Automatic switching between regular and white logo
- **Customizable**: Size, background color, border radius, and shadow can be adjusted
- **Animated Version**: `AnimatedSokofitiLogo` provides a subtle pulsing animation
- **Error Handling**: Fallback to icon if image fails to load
- **Optimized**: Proper image caching and performance

### Usage Examples:

```dart
// Basic logo (uses regular colored logo)
SokofitiLogo(
  size: 120,
  backgroundColor: Colors.white,
  useWhiteLogo: false,
)

// White logo for dark backgrounds
SokofitiLogo(
  size: 80,
  backgroundColor: Colors.green,
  useWhiteLogo: true,
  borderRadius: 20,
  showShadow: false,
)

// Animated logo for splash screen
AnimatedSokofitiLogo(
  size: 120,
  backgroundColor: Colors.white,
  useWhiteLogo: false,
)
```

## Web Assets

The web version uses the following assets:
- `web/favicon.png` - Browser favicon
- `web/icons/Icon-192.png` - PWA icon (192x192)
- `web/icons/Icon-512.png` - PWA icon (512x512)
- `web/icons/Icon-maskable-*.png` - Maskable icons for Android

## Branding Guidelines

- **Primary Color**: Green (#4CAF50)
- **Logo Style**: Shopping bag with custom SokoFiti styling
- **Typography**: Bold, modern fonts
- **Tagline**: "Buy • Sell • Connect"

## Adding New Assets

1. Place image files in the appropriate subdirectory
2. Update `pubspec.yaml` if needed
3. Run `flutter pub get` to refresh assets
4. Reference assets using `assets/path/to/file.ext`
