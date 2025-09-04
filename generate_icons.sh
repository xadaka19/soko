#!/bin/bash

# Script to generate Android app icons from SokoFiti logo
echo "🎨 Generating SokoFiti app icons..."

# Check if ImageMagick is available
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick not found. Installing..."
    # Try to install ImageMagick
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y imagemagick
    elif command -v brew &> /dev/null; then
        brew install imagemagick
    else
        echo "❌ Cannot install ImageMagick automatically. Please install it manually."
        echo "   Ubuntu/Debian: sudo apt-get install imagemagick"
        echo "   macOS: brew install imagemagick"
        exit 1
    fi
fi

# Source logo
SOURCE_LOGO="assets/images/sokofiti_logo.png"

if [ ! -f "$SOURCE_LOGO" ]; then
    echo "❌ Source logo not found: $SOURCE_LOGO"
    exit 1
fi

echo "📱 Creating Android app icons..."

# Android icon sizes and directories
declare -A ANDROID_SIZES=(
    ["mipmap-mdpi"]=48
    ["mipmap-hdpi"]=72
    ["mipmap-xhdpi"]=96
    ["mipmap-xxhdpi"]=144
    ["mipmap-xxxhdpi"]=192
)

# Create Android icons
for dir in "${!ANDROID_SIZES[@]}"; do
    size=${ANDROID_SIZES[$dir]}
    output_dir="android/app/src/main/res/$dir"
    output_file="$output_dir/ic_launcher.png"
    
    echo "  📦 Creating ${size}x${size} icon for $dir"
    
    # Create directory if it doesn't exist
    mkdir -p "$output_dir"
    
    # Generate icon with proper sizing and background
    convert "$SOURCE_LOGO" \
        -resize "${size}x${size}" \
        -background white \
        -gravity center \
        -extent "${size}x${size}" \
        "$output_file"
    
    if [ $? -eq 0 ]; then
        echo "  ✅ Created: $output_file"
    else
        echo "  ❌ Failed to create: $output_file"
    fi
done

echo ""
echo "🎉 Icon generation complete!"
echo ""
echo "📋 Generated icons:"
find android/app/src/main/res -name "ic_launcher.png" -exec ls -la {} \;

echo ""
echo "🔧 Next steps:"
echo "1. Clean and rebuild the app: flutter clean && flutter build apk --debug"
echo "2. Install the new APK on your device"
echo "3. The SokoFiti logo should now appear as the app icon"
