#!/bin/bash

# Script to locate the debug APK file
echo "🔍 Looking for debug APK files..."
echo ""

# Check if build directory exists
if [ ! -d "build" ]; then
    echo "❌ Build directory not found. Please run 'flutter build apk --debug' first."
    exit 1
fi

# Look for APK files
APK_DIR="build/app/outputs/flutter-apk"
if [ -d "$APK_DIR" ]; then
    echo "📁 APK directory found: $APK_DIR"
    echo ""
    
    # List all APK files
    APK_FILES=$(find "$APK_DIR" -name "*.apk" 2>/dev/null)
    
    if [ -n "$APK_FILES" ]; then
        echo "📱 Found APK files:"
        echo ""
        
        for apk in $APK_FILES; do
            # Get file info
            SIZE=$(du -h "$apk" | cut -f1)
            DATE=$(stat -c %y "$apk" 2>/dev/null || stat -f %Sm "$apk" 2>/dev/null)
            
            echo "  📦 $(basename "$apk")"
            echo "     📍 Location: $apk"
            echo "     📏 Size: $SIZE"
            echo "     📅 Modified: $DATE"
            echo ""
        done
        
        # Show the most recent debug APK
        DEBUG_APK=$(find "$APK_DIR" -name "*debug*.apk" | head -1)
        if [ -n "$DEBUG_APK" ]; then
            echo "🎯 Main debug APK:"
            echo "   $DEBUG_APK"
            echo ""
            echo "💡 To install on device:"
            echo "   adb install \"$DEBUG_APK\""
            echo ""
            echo "📋 To copy to Downloads folder:"
            echo "   cp \"$DEBUG_APK\" ~/Downloads/sokofiti-debug.apk"
        fi
    else
        echo "❌ No APK files found in $APK_DIR"
        echo "   Please run: flutter build apk --debug"
    fi
else
    echo "❌ APK output directory not found: $APK_DIR"
    echo "   Please run: flutter build apk --debug"
fi

echo ""
echo "🔧 Build commands:"
echo "   flutter clean"
echo "   flutter pub get"
echo "   flutter build apk --debug"
echo ""
