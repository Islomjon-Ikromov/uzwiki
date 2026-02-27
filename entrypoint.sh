#!/bin/bash
set -e

SETTINGS_FILE="/var/www/html/LocalSettings.php"
CONFIG_BACKUP="/config/LocalSettings.php"

# If config exists from previous run, restore it
if [ -f "$CONFIG_BACKUP" ] && [ ! -f "$SETTINGS_FILE" ]; then
    echo "Restoring LocalSettings.php from previous run..."
    cp "$CONFIG_BACKUP" "$SETTINGS_FILE"
fi

# First-time install
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "=== First run: installing MediaWiki ==="

    php maintenance/install.php \
        --dbtype=postgres \
        --dbserver="$MEDIAWIKI_DB_HOST" \
        --dbport="$MEDIAWIKI_DB_PORT" \
        --dbname="$MEDIAWIKI_DB_NAME" \
        --dbuser="$MEDIAWIKI_DB_USER" \
        --dbpass="$MEDIAWIKI_DB_PASSWORD" \
        --server="$MEDIAWIKI_SERVER" \
        --scriptpath="" \
        --lang="${MEDIAWIKI_LANG:-uz}" \
        --pass="$MEDIAWIKI_ADMIN_PASSWORD" \
        "${MEDIAWIKI_SITE_NAME:-UzWiki}" \
        "$MEDIAWIKI_ADMIN_USER"

    # Append Redis + extra config
    cat >> "$SETTINGS_FILE" <<'EOF'

## --- Auto-configured settings ---

# Redis object caching
$wgObjectCaches['redis'] = [
    'class' => 'RedisBagOStuff',
    'servers' => [ 'redis:6379' ],
];
$wgMainCacheType = 'redis';
$wgSessionCacheType = 'redis';
$wgParserCacheType = 'redis';

# File uploads
$wgEnableUploads = true;

# Logo (default MediaWiki logo)
$wgLogos = [ '1x' => "$wgResourceBasePath/resources/assets/mediawiki.png" ];

# Short URLs
$wgArticlePath = "/wiki/$1";
$wgUsePathInfo = true;

# Extensions for Wikipedia content
wfLoadExtension( 'Scribunto' );
$wgScribuntoDefaultEngine = 'luastandalone';
wfLoadExtension( 'TemplateStyles' );
wfLoadExtension( 'ParserFunctions' );
$wgPFEnableStringFunctions = true;
wfLoadExtension( 'Cite' );
wfLoadExtension( 'TemplateData' );

# Use system Lua binary (ARM64 compatible)
$wgScribuntoEngineConf['luastandalone']['luaPath'] = '/usr/bin/lua5.1';

# Disable email (no mail server in container)
$wgEnableEmail = false;
$wgEnableUserEmail = false;
EOF

    echo "=== MediaWiki installation complete! ==="

    # Save config for persistence
    cp "$SETTINGS_FILE" "$CONFIG_BACKUP"
fi

exec apache2-foreground
