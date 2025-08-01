#!/bin/bash

# PHP Environment Check Script
# Prüft PHP-Version, Extensions und ImageMagick-Status

echo "========================================="
echo "🔍 PHP Environment Check"
echo "========================================="
echo

# PHP Version prüfen
echo "📋 PHP Version Information:"
echo "----------------------------------------"
php --version
echo
echo "PHP CLI Path: $(which php)"
echo "PHP-FPM Status:"
systemctl status php8.4-fpm --no-pager -l 2>/dev/null || echo "  ❌ php8.4-fpm not running or not installed"
echo

# Alle geladenen PHP-Module anzeigen
echo "📦 Currently Loaded PHP Extensions:"
echo "----------------------------------------"
php -m | sort
echo
echo "Total extensions loaded: $(php -m | wc -l)"
echo

# ImageMagick spezifische Prüfungen
echo "🖼️  ImageMagick Extension Check:"
echo "----------------------------------------"

# Prüfung 1: Extension in der Liste?
if php -m | grep -q "imagick"; then
    echo "✅ imagick extension is listed in php -m"
else
    echo "❌ imagick extension NOT found in php -m"
fi

# Prüfung 2: Imagick-Klasse verfügbar?
if php -r "if (!class_exists('Imagick')) exit(1);" 2>/dev/null; then
    echo "✅ Imagick class is available"

    # ImageMagick Version anzeigen
    IMAGICK_VERSION=$(php -r "echo (new Imagick())->getVersion()['versionString'];" 2>/dev/null || echo "Unknown")
    echo "   ImageMagick Version: $IMAGICK_VERSION"

    # Unterstützte Formate anzeigen
    echo "   Supported formats: $(php -r "echo implode(', ', array_slice((new Imagick())->queryFormats(), 0, 10));" 2>/dev/null || echo "Unable to query")..."
else
    echo "❌ Imagick class NOT available"
fi

# Prüfung 3: Praktischer ImageMagick-Test
echo
echo "🧪 Practical ImageMagick Test:"
echo "----------------------------------------"
php -r "
try {
    if (!class_exists('Imagick')) {
        echo '❌ Imagick class does not exist' . PHP_EOL;
        exit(1);
    }

    echo '✅ Imagick class exists' . PHP_EOL;

    // Test: Imagick-Objekt erstellen
    \$imagick = new Imagick();
    echo '✅ Imagick object created successfully' . PHP_EOL;

    // Test: Einfaches Bild erstellen
    \$imagick->newImage(100, 100, new ImagickPixel('red'));
    echo '✅ Simple image creation works' . PHP_EOL;

    // Test: Format setzen
    \$imagick->setImageFormat('png');
    echo '✅ Image format setting works' . PHP_EOL;

    // Test: Bildgröße abrufen
    \$geometry = \$imagick->getImageGeometry();
    echo '✅ Image geometry: ' . \$geometry['width'] . 'x' . \$geometry['height'] . PHP_EOL;

    // Test: Unterstützte Formate prüfen
    \$formats = \$imagick->queryFormats();
    echo '✅ Supported formats count: ' . count(\$formats) . PHP_EOL;

    // Test: Wichtige Formate prüfen
    \$important_formats = ['JPEG', 'PNG', 'GIF', 'WEBP', 'PDF'];
    \$supported = array_intersect(\$important_formats, \$formats);
    echo '✅ Important formats supported: ' . implode(', ', \$supported) . PHP_EOL;

    echo '🎉 All ImageMagick tests passed!' . PHP_EOL;

} catch (Exception \$e) {
    echo '❌ ImageMagick test failed: ' . \$e->getMessage() . PHP_EOL;
    exit(1);
}
" 2>/dev/null || echo "❌ PHP ImageMagick test script failed to execute"

# Prüfung 3: Extension-Info
echo
echo "📄 ImageMagick Extension Details:"
if php -m | grep -q "imagick"; then
    php -r "
    if (extension_loaded('imagick')) {
        echo 'Extension Version: ' . phpversion('imagick') . PHP_EOL;
        echo 'Extension loaded from: ' . (new ReflectionExtension('imagick'))->getFileName() . PHP_EOL;
    }
    " 2>/dev/null || echo "Unable to get extension details"
else
    echo "❌ Extension not loaded"
fi

echo

# System ImageMagick prüfen
echo "🔧 System ImageMagick Check:"
echo "----------------------------------------"
if command -v convert >/dev/null 2>&1; then
    echo "✅ ImageMagick convert command available"
    echo "   Version: $(convert -version | head -1)"
else
    echo "❌ ImageMagick convert command NOT found"
fi

if command -v identify >/dev/null 2>&1; then
    echo "✅ ImageMagick identify command available"
else
    echo "❌ ImageMagick identify command NOT found"
fi

echo

# Entwicklungsheader prüfen
echo "🛠️  Development Headers Check:"
echo "----------------------------------------"
if pkg-config --exists MagickWand; then
    echo "✅ MagickWand development headers available"
    echo "   Version: $(pkg-config --modversion MagickWand)"
else
    echo "❌ MagickWand development headers NOT found"
    echo "   (Needed for: pecl install imagick)"
fi

if command -v phpize >/dev/null 2>&1; then
    echo "✅ phpize available ($(phpize --version | head -1))"
    echo "   (Required for: pecl install imagick)"
else
    echo "❌ phpize NOT found (install php8.4-dev)"
    echo "   (Required for: pecl install imagick)"
fi

echo

# PHP-FPM Pool-Konfiguration prüfen
echo "⚙️  PHP-FPM Configuration:"
echo "----------------------------------------"
if [ -d "/etc/php/8.4/fpm/pool.d/" ]; then
    echo "✅ PHP-FPM pool directory exists"
    echo "   Active pools: $(ls /etc/php/8.4/fpm/pool.d/*.conf 2>/dev/null | wc -l)"
else
    echo "❌ PHP-FPM pool directory not found"
fi

# PHP-INI Dateien
echo
echo "📝 PHP Configuration Files:"
echo "----------------------------------------"
echo "Main php.ini (CLI): $(php --ini | grep "Loaded Configuration File" | cut -d: -f2 | xargs)"
echo "Additional ini files directory: $(php --ini | grep "Scan for additional" | cut -d: -f2 | xargs)"

# Speicher und Limits
echo
echo "💾 PHP Memory & Limits:"
echo "----------------------------------------"
php -r "
echo 'Memory Limit: ' . ini_get('memory_limit') . PHP_EOL;
echo 'Max Execution Time: ' . ini_get('max_execution_time') . 's' . PHP_EOL;
echo 'Upload Max Filesize: ' . ini_get('upload_max_filesize') . PHP_EOL;
echo 'Post Max Size: ' . ini_get('post_max_size') . PHP_EOL;
"

echo
echo "========================================="
echo "🎯 Summary & Recommendations:"
echo "========================================="

# Zusammenfassung und Empfehlungen
if php -m | grep -q "imagick" && php -r "if (!class_exists('Imagick')) exit(1);" 2>/dev/null; then
    echo "✅ ImageMagick extension is working properly"
else
    echo "❌ ImageMagick extension needs attention"
    echo
    echo "🔧 To fix ImageMagick issues, try:"
    echo "   1. Install dependencies: apt-get install libmagickwand-dev imagemagick php8.4-dev"
    echo "   2. Install via PECL: pecl install imagick"
    echo "   3. Enable extension: echo 'extension=imagick.so' > /etc/php/8.4/mods-available/imagick.ini"
    echo "   4. Activate: phpenmod -v 8.4 imagick"
    echo "   5. Restart: systemctl restart php8.4-fpm"
fi

echo
echo "📊 PHP Extensions Status:"
TOTAL_EXTENSIONS=$(php -m | wc -l)
if [ $TOTAL_EXTENSIONS -gt 30 ]; then
    echo "✅ Good number of extensions loaded ($TOTAL_EXTENSIONS)"
else
    echo "⚠️  Relatively few extensions loaded ($TOTAL_EXTENSIONS)"
fi

echo
echo "🏁 Check completed!"
echo "========================================="
