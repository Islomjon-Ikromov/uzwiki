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

    # Append comprehensive configuration
    cat >> "$SETTINGS_FILE" <<'SETTINGS'

## --- Auto-configured settings ---

#######################################################################
# Cache (Redis)
#######################################################################

$wgObjectCaches['redis'] = [
    'class' => 'RedisBagOStuff',
    'servers' => [ 'redis:6379' ],
];
$wgMainCacheType = 'redis';
$wgSessionCacheType = 'redis';
$wgParserCacheType = 'redis';
$wgMessageCacheType = 'redis';
$wgLanguageConverterCacheType = 'redis';
$wgMainStash = 'redis';

# File cache
$wgCacheDirectory = "$IP/cache";
$wgParserCacheExpireTime = 86400;
$wgEnableSidebarCache = true;
$wgSidebarCacheExpiry = 86400;
$wgCachePages = true;
$wgUseGzip = true;

# Localisation cache
$wgLocalisationCacheConf = [
    'class' => LocalisationCache::class,
    'store' => 'detect',
    'storeDirectory' => "$IP/cache/l10n",
    'manualRecache' => false,
];

#######################################################################
# General settings
#######################################################################

$wgCanonicalServer = "https://ziyosfera.uz";
$wgEnableCanonicalServerLink = true;
$wgForceHTTPS = false;
$wgReferrerPolicy = [ 'origin-when-cross-origin' ];

#######################################################################
# File uploads
#######################################################################

$wgEnableUploads = true;
$wgUseInstantCommons = true;
$wgMaxUploadSize = 104857600;
$wgFileExtensions = [
    'png', 'gif', 'jpg', 'jpeg', 'webp', 'svg',
    'pdf', 'djvu',
    'ogg', 'ogv', 'oga', 'flac', 'opus', 'wav', 'mp3',
    'webm', 'mp4',
    'zip', 'gz', 'bz2', 'xz', '7z',
    'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', 'odp',
];
$wgHashedUploadDirectory = true;
$wgResponsiveImages = true;
$wgNativeImageLazyLoading = true;
$wgShowEXIF = true;
$wgSVGNativeRendering = true;
$wgImagePreconnect = true;

#######################################################################
# Logo
#######################################################################

$wgLogos = [ '1x' => "$wgResourceBasePath/resources/assets/mediawiki.png" ];

#######################################################################
# Short URLs
#######################################################################

$wgArticlePath = "/articles/$1";
$wgUsePathInfo = true;

#######################################################################
# Language & Timezone
#######################################################################

$wgLocaltimezone = "Asia/Tashkent";
$wgLocalTZoffset = 300;
$wgAllUnicodeFixes = true;
$wgInterwikiMagic = true;
$wgHideInterlanguageLinks = true;
$wgExtraInterlanguageLinkPrefixes = [
    'simple', 'ar', 'id', 'ms', 'bs', 'bg', 'ca', 'cs', 'da', 'de',
    'en', 'et', 'el', 'es', 'eo', 'eu', 'fa', 'fr', 'gl', 'ko',
    'he', 'hr', 'it', 'ka', 'lv', 'lt', 'hu', 'nl', 'ja', 'no',
    'nn', 'pl', 'pt', 'ro', 'ru', 'sk', 'sl', 'sr', 'sh', 'fi',
    'sv', 'th', 'vi', 'tr', 'uk', 'zh', 'az', 'kk', 'ky', 'tk',
    'tt', 'ba', 'cv', 'sah', 'crh', 'gag', 'krc', 'alt', 'azb',
    'tyv', 'ug', 'kaa',
];

#######################################################################
# Skins
#######################################################################

$wgDefaultSkin = "vector-2022";
$wgFallbackSkin = "vector";
$wgVectorUseSimpleSearch = true;
$wgVectorUseIconWatch = true;
$wgVectorResponsive = true;

# Hide "Ziyosferadan olingan" tagline
$wgHooks['BeforePageDisplay'][] = function ( $out ) {
    $out->addInlineStyle('#siteSub { display: none !important; }');
};

#######################################################################
# Copyright
#######################################################################

$wgRightsUrl = "https://creativecommons.org/licenses/by-sa/4.0/";
$wgRightsText = "Creative Commons Attribution-ShareAlike 4.0";
$wgRightsIcon = "$wgResourceBasePath/resources/assets/licenses/cc-by-sa.png";

#######################################################################
# Output
#######################################################################

$wgEditSubmitButtonLabelPublish = true;
$wgShowRollbackEditCount = 10;
$wgFixDoubleRedirects = true;
$wgEnableEditRecovery = true;
$wgEnableProtectionIndicators = true;

#######################################################################
# Namespaces
#######################################################################

$wgNamespacesWithSubpages = [
    NS_MAIN => true, NS_TALK => true,
    NS_USER => true, NS_USER_TALK => true,
    NS_PROJECT => true, NS_PROJECT_TALK => true,
    NS_FILE_TALK => true, NS_HELP => true,
    NS_HELP_TALK => true, NS_CATEGORY_TALK => true,
    NS_TEMPLATE => true, NS_TEMPLATE_TALK => true,
    NS_MEDIAWIKI => true, NS_MEDIAWIKI_TALK => true,
];

#######################################################################
# Parser
#######################################################################

$wgAllowDisplayTitle = true;
$wgExpensiveParserFunctionLimit = 500;
$wgMaxTemplateDepth = 100;
$wgNoFollowLinks = true;
$wgNoFollowDomainExceptions = [ 'ziyosfera.uz' ];
$wgEnableMagicLinks = [ 'ISBN' => true, 'PMID' => true, 'RFC' => true ];

#######################################################################
# Statistics
#######################################################################

$wgActiveUserDays = 30;
$wgArticleCountMethod = 'link';

#######################################################################
# User accounts
#######################################################################

$wgAutoConfirmAge = 345600;
$wgAutoConfirmCount = 10;
$wgBlockAllowsUTEdit = true;

#######################################################################
# Security
#######################################################################

$wgAllowUserJs = true;
$wgAllowUserCss = true;
$wgCookieHttpOnly = true;
$wgCookieSecure = 'detect';
$wgCookieSameSite = 'Lax';
$wgPingback = false;

#######################################################################
# Performance
#######################################################################

$wgMaxArticleSize = 2048;
$wgJobRunRate = 1;
$wgRunJobsAsync = true;
$wgMemoryLimit = "256M";

#######################################################################
# Recent changes, watchlist
#######################################################################

$wgRCMaxAge = 7776000;
$wgRCShowWatchingUsers = true;
$wgRCShowChangedSize = true;
$wgRCWatchCategoryMembership = true;
$wgShowUpdatedMarker = true;
$wgUseRCPatrol = true;
$wgUseNPPatrol = true;
$wgUseFilePatrol = true;
$wgWatchlistExpiry = true;
$wgFeed = true;
$wgAdvertisedFeedTypes = [ 'atom', 'rss' ];

#######################################################################
# Search
#######################################################################

$wgAdvancedSearchHighlighting = true;
$wgSearchRunSuggestedQuery = true;

#######################################################################
# Robot policies
#######################################################################

$wgDefaultRobotPolicy = 'noindex,nofollow';
$wgNamespaceRobotPolicies = [
    NS_MAIN => 'index,follow',
];

#######################################################################
# Logging
#######################################################################

$wgNewUserLog = true;
$wgPageCreationLog = true;

#######################################################################
# Email (disabled)
#######################################################################

$wgEnableEmail = false;
$wgEnableUserEmail = false;

#######################################################################
# Debug (off)
#######################################################################

$wgShowDebug = false;
$wgShowExceptionDetails = false;

#######################################################################
# Extensions
#######################################################################

# Core content
wfLoadExtension( 'Scribunto' );
$wgScribuntoDefaultEngine = 'luastandalone';
$wgScribuntoEngineConf['luastandalone']['luaPath'] = '/usr/bin/lua5.1';

wfLoadExtension( 'ParserFunctions' );
$wgPFEnableStringFunctions = true;

wfLoadExtension( 'Cite' );
wfLoadExtension( 'CiteThisPage' );
wfLoadExtension( 'TemplateData' );
wfLoadExtension( 'TemplateStyles' );

# Visual editing
wfLoadExtension( 'VisualEditor' );
$wgVisualEditorAvailableNamespaces = [
    NS_MAIN => true, NS_USER => true, NS_PROJECT => true,
    NS_HELP => true, NS_CATEGORY => true, NS_TEMPLATE => true,
];
$wgDefaultUserOptions['visualeditor-enable'] = 1;
$wgVisualEditorEnableWikitext = true;
$wgVirtualRestConfig['modules']['parsoid'] = [
    'url' => 'http://localhost/rest.php',
];

wfLoadExtension( 'WikiEditor' );
$wgDefaultUserOptions['usebetatoolbar'] = 1;

wfLoadExtension( 'CodeEditor' );
wfLoadExtension( 'DiscussionTools' );

# UI / user interaction
wfLoadExtension( 'Gadgets' );
wfLoadExtension( 'CharInsert' );
wfLoadExtension( 'InputBox' );
wfLoadExtension( 'ImageMap' );
wfLoadExtension( 'Poem' );

# Page features
wfLoadExtension( 'CategoryTree' );
wfLoadExtension( 'MultimediaViewer' );
wfLoadExtension( 'PageImages' );
wfLoadExtension( 'TextExtracts' );

# Notifications
wfLoadExtension( 'Echo' );
wfLoadExtension( 'Thanks' );

# Anti-abuse / moderation
wfLoadExtension( 'AbuseFilter' );
wfLoadExtension( 'SpamBlacklist' );
wfLoadExtension( 'TitleBlacklist' );
wfLoadExtension( 'ConfirmEdit' );
wfLoadExtension( 'ConfirmEdit/QuestyCaptcha' );
$wgCaptchaClass = 'QuestyCaptcha';
$wgCaptchaQuestions = [
    "What is the capital of Uzbekistan?" => [ 'Tashkent', 'Toshkent' ],
];
$wgCaptchaTriggers['createaccount'] = true;
$wgCaptchaTriggers['badlogin'] = true;
$wgCaptchaTriggers['addurl'] = true;
wfLoadExtension( 'Nuke' );

# Security and auditing
wfLoadExtension( 'CheckUser' );
wfLoadExtension( 'OATHAuth' );
wfLoadExtension( 'LoginNotify' );
wfLoadExtension( 'SecureLinkFixer' );

# Code and syntax
wfLoadExtension( 'SyntaxHighlight_GeSHi' );
wfLoadExtension( 'Math' );
$wgMathValidModes = [ 'mathml' ];
$wgDefaultUserOptions['math'] = 'mathml';

wfLoadExtension( 'PdfHandler' );
$wgPdfProcessor = '/usr/bin/gs';
$wgPdfPostProcessor = '/usr/bin/convert';
$wgPdfInfo = '/usr/bin/pdfinfo';
$wgPdftoText = '/usr/bin/pdftotext';

# SEO (only for main namespace articles)
wfLoadExtension( 'WikiSEO' );
$wgWikiSeoDefaultImage = "$wgResourceBasePath/resources/assets/mediawiki.png";
$wgWikiSeoEnableAutoDescription = true;
$wgWikiSeoTryCleanAutoDescription = true;
$wgWikiSeoDisableLogoFallbackImage = false;
$wgWikiSeoEnabledNamespaces = [
    NS_MAIN => true,
];

# Content management
wfLoadExtension( 'ReplaceText' );
wfLoadExtension( 'Linter' );
SETTINGS

    echo "=== MediaWiki installation complete! ==="

    # Save config for persistence
    cp "$SETTINGS_FILE" "$CONFIG_BACKUP"
fi

# Ensure cache directories exist
mkdir -p /var/www/html/cache/l10n
chown -R www-data:www-data /var/www/html/cache

exec apache2-foreground
