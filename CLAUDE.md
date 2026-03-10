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
# First-time setup (uses simplified compose without nginx/redis)
docker compose -f docker-compose.setup.yml up -d --build

# Production start
docker compose up -d

# Rebuild after code changes (Dockerfile, entrypoint.sh, nginx.conf, extensions)
docker compose up -d --build

# Stop
docker compose down

# Full cleanup (removes volumes)
docker compose down -v

# View logs
docker compose logs -f mediawiki
docker compose logs -f db
docker compose logs -f nginx
```

## Key Configuration Flow

`.env` → `docker-compose.yml` → `Dockerfile` (image build) → `entrypoint.sh` (runtime config generation) → `apache2-foreground`

The `.env` file contains database credentials, admin user/password, site name, server URL, and language. These are passed as environment variables to the mediawiki container.

## Important Files

| File | Purpose |
|------|---------|
| `entrypoint.sh` | Core config — generates LocalSettings.php with all extensions, caching, uploads, short URLs, security settings |
| `Dockerfile` | PHP 8.2 + Apache image with system deps (ImageMagick, Lua, PostgreSQL, ICU, Redis PECL) |
| `nginx/nginx.conf` | Reverse proxy with gzip, security headers, 30-day static asset caching, blocked config files |
| `import_article.py` | Imports articles from uz.wikipedia.org with recursive template/module dependency resolution |

## Extension Management

Extensions live in `mediawiki/extensions/`. Loading and configuration happens in `entrypoint.sh` (not in a separate LocalSettings.php). When adding a new extension:
1. Add the extension directory to `mediawiki/extensions/`
2. Add `wfLoadExtension('...')` and any config to the appropriate section in `entrypoint.sh`
3. Rebuild: `docker compose up -d --build`

## Article Import

```bash
python3 import_article.py "Article Title"
# Exports to /tmp/uzwiki_export.xml with all template/module dependencies
# Default article: Oʻzbekiston
# Source: uz.wikipedia.org
```

## Conventions

- Language: Uzbek (`uz`), timezone: `Asia/Tashkent`
- Short URLs: `/ziyo/$1` pattern
- CAPTCHA: QuestyCaptcha with Uzbekistan-related questions
- License: CC-BY-SA 4.0
- File uploads: enabled, 100MB max
- Email: disabled
- Skin: vector-2022 (fallback: vector)
