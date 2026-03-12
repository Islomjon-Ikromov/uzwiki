# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UzWiki (Ziyosfera) — an Uzbek-language MediaWiki 1.45.1 deployment running on Docker with PostgreSQL 16, Redis 7, and Nginx reverse proxy. Production domain: `https://ziyosfera.uz`.

## Architecture

```
Port 8080 → nginx:alpine (reverse proxy)
               → php:8.2-apache (MediaWiki + 38 extensions)
                    → postgres:16 (database)
                    → redis:7 (object/session/parser cache)
```

- **LocalSettings.php** is not in the repo — it's generated at runtime by `entrypoint.sh` and backed up to `volumes/config/`
- All persistent data lives in `volumes/` (gitignored): postgres data, uploaded images, cache, redis data, config backups
- The entrypoint script handles first-time install (via `maintenance/install.php`) and appends ~350 lines of configuration to LocalSettings.php on every container start

## Build & Run Commands

```bash
# First-time setup (simplified compose: no nginx/redis, no entrypoint auto-install)
docker compose -f docker-compose.setup.yml up -d --build

# Production start (full stack with nginx, redis, auto-install via entrypoint.sh)
docker compose up -d

# Rebuild after code changes (Dockerfile, entrypoint.sh, nginx.conf, extensions)
docker compose up -d --build

# Stop / full cleanup
docker compose down
docker compose down -v   # removes volumes too

# View logs
docker compose logs -f mediawiki
docker compose logs -f db
docker compose logs -f nginx

# Shell into running containers
docker compose exec mediawiki bash
docker compose exec db psql -U uzwiki -d uzwiki
docker compose exec redis redis-cli

# Run MediaWiki maintenance scripts
docker compose exec mediawiki php maintenance/run.php update
docker compose exec mediawiki php maintenance/run.php importDump < /tmp/uzwiki_export.xml
docker compose exec mediawiki php maintenance/run.php rebuildrecentchanges
```

## Key Configuration Flow

`.env` → `docker-compose.yml` → `Dockerfile` (image build) → `entrypoint.sh` (runtime config generation) → `apache2-foreground`

The `.env` file contains database credentials, admin user/password, site name, server URL, and language. These are passed as environment variables to the mediawiki container.

**Two compose files serve different purposes:**
- `docker-compose.setup.yml` — minimal (mediawiki + postgres only), exposes port 8080 directly from Apache, no entrypoint auto-install. Used for manual web-based setup.
- `docker-compose.yml` — full stack (nginx + mediawiki + postgres + redis), uses `entrypoint.sh` for automatic install and config generation.

## Important Files

| File | Purpose |
|------|---------|
| `entrypoint.sh` | Core config — generates LocalSettings.php with all extensions, caching, uploads, short URLs, security settings. Idempotent: restores from backup on restart, only runs install on first run. |
| `Dockerfile` | PHP 8.2 + Apache image with system deps (ImageMagick, Lua, PostgreSQL, ICU, Redis PECL), `.htaccess` for `/ziyo/$1` rewrite |
| `nginx/nginx.conf` | Reverse proxy with gzip, security headers, 30-day static asset caching, blocked config files |
| `import_article.py` | Imports articles from uz.wikipedia.org with recursive template/module dependency resolution |

## Extension Management

Extensions live in `mediawiki/extensions/`. Loading and configuration happens in `entrypoint.sh` (not in a separate LocalSettings.php). When adding a new extension:
1. Add the extension directory to `mediawiki/extensions/`
2. Add `wfLoadExtension('...')` and any config to the appropriate section in `entrypoint.sh`
3. Rebuild: `docker compose up -d --build`

Note: since `entrypoint.sh` appends config on first install only (guarded by `[ ! -f "$SETTINGS_FILE" ]`), adding extensions to an existing deployment requires either removing the config backup (`volumes/config/LocalSettings.php`) to trigger reinstall, or manually appending the extension config to the running `LocalSettings.php`.

## Article Import

```bash
# Step 1: Export article with all template/module dependencies from uz.wikipedia.org
python3 import_article.py "Article Title"
# Outputs: /tmp/uzwiki_export.xml

# Step 2: Import the XML dump into the local wiki
docker compose exec -T mediawiki php maintenance/run.php importDump < /tmp/uzwiki_export.xml

# Step 3: Rebuild recent changes after import
docker compose exec mediawiki php maintenance/run.php rebuildrecentchanges
```

The import script uses Uzbek namespace prefixes: `Andoza:` (templates), `Modul:` (modules).

## Conventions

- Language: Uzbek (`uz`), timezone: `Asia/Tashkent`
- Short URLs: `/ziyo/$1` pattern (rewrite in both `.htaccess` and nginx)
- CAPTCHA: QuestyCaptcha with Uzbekistan-related questions
- License: CC-BY-SA 4.0
- File uploads: enabled, 100MB max
- Email: disabled
- Skin: vector-2022 (fallback: vector)
- Main page: `Bosh_sahifa` (title hidden via CSS hook in entrypoint.sh)
