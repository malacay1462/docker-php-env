#!/bin/bash

# PHP Environment Check Script for Laravel Forge Servers
# Auto-detects available PHP versions and checks ImageMagick status

echo "========================================="
echo "🔍 PHP Environment Check (Forge Server)"
echo "========================================="
echo

# Auto-detect current PHP version
CURRENT_PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null || echo "unknown")
echo "🔍 Auto-detected PHP version: $CURRENT_PHP_VERSION"

# Available PHP versions on server
echo "📋 Available PHP versions on server:"
echo "----------------------------------------"
ls -1 /etc/php/ 2>/dev/null | sort -V || echo "Unable to detect PHP versions"
echo

# PHP Version Information
echo "📋 Current PHP Version Information:"
echo "----------------------------------------"
php --version
echo
echo "PHP CLI Path: $(which php)"

# Check all available PHP-FPM services
echo "PHP-FPM Services:"
for version in $(ls /etc/php/ 2>/dev/null | sort -V); do
    if systemctl is-active php${version}-fpm >/dev/null 2>&1; then
        echo "  ✅ php${version}-fpm is running"
    elif systemctl list-unit-files | grep -q "php${version}-fpm.service"; then
        echo "  ❌ php${version}-fpm is installed but not running"
    fi
done
echo

# Currently loaded PHP extensions
echo "📦 Currently Loaded PHP Extensions:"
echo "----------------------------------------"
php -m | sort
echo
echo "Total extensions loaded: $(php -m | wc -l)"
echo

# ImageMagick specific checks
echo "🖼️  ImageMagick Extension Check:"
echo "----------------------------------------"

# Check 1: Extension in list?
if php -m | grep -q "imagick"; then
    echo "✅ imagick extension is listed in php -m"
else
    echo "❌ imagick extension NOT found in php -m"
fi

# Check 2: Imagick class available?
if php -r "if (!class_exists('Imagick')) exit(1);" 2>/dev/null; then
    echo "✅ Imagick class is available"
    
    # ImageMagick version
    IMAGICK_VERSION=$(php -r "echo (new Imagick())->getVersion()['versionString'];" 2>/dev/null || echo "Unknown")
    echo "   ImageMagick Version: $IMAGICK_VERSION"
    
    # Supported formats
    echo "   Supported formats: $(php -r "echo implode(', ', array_slice((new Imagick())->queryFormats(), 0, 10));" 2>/dev/null || echo "Unable to query")..."
else
    echo "❌ Imagick class NOT available"
fi

# Practical ImageMagick test
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
    
    \$imagick = new Imagick();
    echo '✅ Imagick object created successfully' . PHP_EOL;
    
    \$imagick->newImage(100, 100, new ImagickPixel('red'));
    echo '✅ Simple image creation works' . PHP_EOL;
    
    \$imagick->setImageFormat('png');
    echo '✅ Image format setting works' . PHP_EOL;
    
    \$geometry = \$imagick->getImageGeometry();
    echo '✅ Image geometry: ' . \$geometry['width'] . 'x' . \$geometry['height'] . PHP_EOL;
    
    \$formats = \$imagick->queryFormats();
    echo '✅ Supported formats count: ' . count(\$formats) . PHP_EOL;
    
    \$important_formats = ['JPEG', 'PNG', 'GIF', 'WEBP', 'PDF'];
    \$supported = array_intersect(\$important_formats, \$formats);
    echo '✅ Important formats supported: ' . implode(', ', \$supported) . PHP_EOL;
    
    echo '🎉 All ImageMagick tests passed!' . PHP_EOL;
    
} catch (Exception \$e) {
    echo '❌ ImageMagick test failed: ' . \$e->getMessage() . PHP_EOL;
    exit(1);
}
" 2>/dev/null || echo "❌ PHP ImageMagick test script failed to execute"

# Extension details (fixed version)
echo
echo "📄 ImageMagick Extension Details:"
if php -m | grep -q "imagick"; then
    php -r "
    if (extension_loaded('imagick')) {
        echo 'Extension Version: ' . phpversion('imagick') . PHP_EOL;
        try {
            \$reflection = new ReflectionExtension('imagick');
            if (method_exists(\$reflection, 'getFileName')) {
                echo 'Extension loaded from: ' . \$reflection->getFileName() . PHP_EOL;
            } else {
                echo 'Extension file path: Not available in this PHP version' . PHP_EOL;
            }
        } catch (Exception \$e) {
            echo 'Extension details: Unable to get reflection info' . PHP_EOL;
        }
    }
    " 2>/dev/null || echo "Unable to get extension details"
else
    echo "❌ Extension not loaded"
fi

echo

# System ImageMagick check
echo "🔧 System ImageMagick Check:"
echo "----------------------------------------"
if command -v convert >/dev/null 2>&1; then
    echo "✅ ImageMagick convert command available"
    echo "   Version: $(convert -version | head -1)"
else
    echo "❌ ImageMagick convert command NOT found"
    echo "   Install with: apt-get install imagemagick"
fi

if command -v identify >/dev/null 2>&1; then
    echo "✅ ImageMagick identify command available"
else
    echo "❌ ImageMagick identify command NOT found"
    echo "   Install with: apt-get install imagemagick"
fi

echo

# Development headers check
echo "🛠️  Development Headers Check:"
echo "----------------------------------------"
if pkg-config --exists MagickWand; then
    echo "✅ MagickWand development headers available"
    echo "   Version: $(pkg-config --modversion MagickWand)"
else
    echo "❌ MagickWand development headers NOT found"
    echo "   (Needed for: pecl install imagick)"
fi

# Check phpize for current version
PHPIZE_CMD="phpize${CURRENT_PHP_VERSION}"
if command -v "$PHPIZE_CMD" >/dev/null 2>&1; then
    echo "✅ phpize${CURRENT_PHP_VERSION} available ($($PHPIZE_CMD --version | head -1))"
    echo "   (Required for: pecl install imagick)"
elif command -v phpize >/dev/null 2>&1; then
    echo "✅ phpize available ($(phpize --version | head -1))"
    echo "   (Required for: pecl install imagick)"
else
    echo "❌ phpize NOT found (install php${CURRENT_PHP_VERSION}-dev)"
    echo "   (Required for: pecl install imagick)"
fi

echo

# PHP-FPM configuration for current version
echo "⚙️  PHP-FPM Configuration:"
echo "----------------------------------------"
if [ -d "/etc/php/${CURRENT_PHP_VERSION}/fpm/pool.d/" ]; then
    echo "✅ PHP-FPM pool directory exists for PHP ${CURRENT_PHP_VERSION}"
    echo "   Active pools: $(ls /etc/php/${CURRENT_PHP_VERSION}/fpm/pool.d/*.conf 2>/dev/null | wc -l)"
    
    # Show all available FPM versions
    echo "   All FPM versions:"
    for version in $(ls /etc/php/ 2>/dev/null | sort -V); do
        if [ -d "/etc/php/${version}/fpm" ]; then
            if systemctl is-active php${version}-fpm >/dev/null 2>&1; then
                echo "     ✅ PHP ${version} FPM (running)"
            else
                echo "     ❌ PHP ${version} FPM (not running)"
            fi
        fi
    done
else
    echo "❌ PHP-FPM pool directory not found for PHP ${CURRENT_PHP_VERSION}"
fi

# PHP configuration files
echo
echo "📝 PHP Configuration Files:"
echo "----------------------------------------"
echo "Main php.ini (CLI): $(php --ini | grep "Loaded Configuration File" | cut -d: -f2 | xargs)"
echo "Additional ini files directory: $(php --ini | grep "Scan for additional" | cut -d: -f2 | xargs)"

# Memory and limits
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

# Summary and recommendations
if php -m | grep -q "imagick" && php -r "if (!class_exists('Imagick')) exit(1);" 2>/dev/null; then
    echo "✅ ImageMagick extension is working properly"
    
    # Check if CLI tools are missing
    if ! command -v convert >/dev/null 2>&1; then
        echo "⚠️  ImageMagick CLI tools missing - install with: apt-get install imagemagick"
    fi
else
    echo "❌ ImageMagick extension needs attention"
    echo
    echo "🔧 To fix ImageMagick issues, try:"
    echo "   1. Install dependencies: apt-get install libmagickwand-dev imagemagick php${CURRENT_PHP_VERSION}-dev"
    echo "   2. Install via PECL: pecl install imagick"
    echo "   3. Enable extension: echo 'extension=imagick.so' > /etc/php/${CURRENT_PHP_VERSION}/mods-available/imagick.ini"
    echo "   4. Activate: phpenmod -v ${CURRENT_PHP_VERSION} imagick"
    echo "   5. Restart: systemctl restart php${CURRENT_PHP_VERSION}-fpm"
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
echo "🏁 Check completed for PHP ${CURRENT_PHP_VERSION}!"
echo "========================================="
