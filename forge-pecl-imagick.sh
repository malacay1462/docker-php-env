#!/bin/bash

# ImageMagick Extension Check & Install Script
# Prüft ob ImageMagick funktioniert und installiert es via PECL falls nötig

echo "🔍 Checking ImageMagick extension..."

# Funktion: ImageMagick-Test
check_imagick() {
    # Test 1: Extension in php -m?
    if ! php -m | grep -q "imagick"; then
        return 1
    fi

    # Test 2: Imagick-Klasse funktionsfähig?
    if ! php -r "
        try {
            if (!class_exists('Imagick')) exit(1);
            \$imagick = new Imagick();
            \$imagick->newImage(10, 10, new ImagickPixel('white'));
            echo 'OK';
        } catch (Exception \$e) {
            exit(1);
        }
    " >/dev/null 2>&1; then
        return 1
    fi

    return 0
}

# Prüfung durchführen
if check_imagick; then
    echo "✅ ImageMagick extension is already working properly"
    echo "   Version: $(php -r "echo phpversion('imagick');" 2>/dev/null || echo 'Unknown')"
    exit 0
fi

echo "❌ ImageMagick extension not working, installing via PECL..."

# Abhängigkeiten installieren
echo "📦 Installing dependencies..."
apt-get update
apt-get install -y libmagickwand-dev imagemagick php8.4-dev

# Alte/defekte Installation entfernen (falls vorhanden)
echo "🧹 Cleaning up any existing installation..."
pecl uninstall imagick 2>/dev/null || true

# PECL-Extension installieren
echo "🔧 Installing ImageMagick via PECL..."
pecl install imagick

# Extension aktivieren
echo "⚙️  Enabling extension..."
echo "extension=imagick.so" > /etc/php/8.4/mods-available/imagick.ini
phpenmod -v 8.4 imagick

# PHP-FPM neustarten (falls läuft)
echo "🔄 Restarting PHP-FPM..."
systemctl restart php8.4-fpm 2>/dev/null || true

# Cleanup
echo "🧹 Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Finale Prüfung
echo "🧪 Testing installation..."
if check_imagick; then
    echo "✅ ImageMagick extension installed and working successfully!"
    echo "   Version: $(php -r "echo phpversion('imagick');" 2>/dev/null || echo 'Unknown')"

    # Zusätzliche Info
    FORMATS=$(php -r "echo count((new Imagick())->queryFormats());" 2>/dev/null || echo '0')
    echo "   Supported formats: $FORMATS"
else
    echo "❌ ImageMagick installation failed!"
    echo "🔧 Manual steps to try:"
    echo "   1. Check if ImageMagick is installed: convert -version"
    echo "   2. Check if development headers are available: pkg-config --exists MagickWand"
    echo "   3. Try manual installation: pecl install imagick"
    echo "   4. Check PHP error logs for details"
    exit 1
fi

echo "🎉 ImageMagick setup completed!"