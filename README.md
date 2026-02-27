# UzWiki — O'zbek MediaWiki Platform

MediaWiki platform running on Docker with PostgreSQL.

## Requirements

- Docker
- Docker Compose

## Project Structure

```
uzwiki/
├── mediawiki/                # MediaWiki 1.45.1 source code
├── volumes/                  # Local data (gitignored)
│   ├── postgres/             # PostgreSQL database files
│   ├── images/               # Uploaded media files
│   ├── cache/                # MediaWiki cache
│   └── LocalSettings.php     # MediaWiki config (generated after setup)
├── docker-compose.yml        # Production compose
├── docker-compose.setup.yml  # First-time setup compose
├── Dockerfile
├── .env                      # Database credentials (gitignored)
└── .gitignore
```

## Default Database Credentials

| Key      | Value          |
|----------|----------------|
| Host     | `db`           |
| Database | `uzwiki`       |
| User     | `uzwiki`       |
| Password | `uzwiki_secret`|

Change these in `.env` before deploying to production.

## First-Time Setup

### 1. Build and start the setup containers

```bash
docker compose -f docker-compose.setup.yml up -d --build
```

### 2. Run the MediaWiki installer

Open your browser and go to:

```
http://localhost:8080
```

In the installer wizard:

- **Database type:** PostgreSQL
- **Database host:** `db`
- **Database port:** `5432`
- **Database name:** `uzwiki`
- **Database user:** `uzwiki`
- **Database password:** `uzwiki_secret`

Complete the rest of the wizard (site name, admin account, etc).

### 3. Save the generated LocalSettings.php

At the end of the installer, download `LocalSettings.php` and move it to the volumes folder:

```bash
mv ~/Downloads/LocalSettings.php ./volumes/LocalSettings.php
```

### 4. Stop setup and start production

```bash
docker compose -f docker-compose.setup.yml down
docker compose up -d
```

Your wiki is now running at `http://localhost:8080`.

## Daily Usage

### Start

```bash
docker compose up -d
```

### Stop

```bash
docker compose down
```

### Rebuild after code changes

```bash
docker compose up -d --build
```

### View logs

```bash
docker compose logs -f mediawiki
docker compose logs -f db
```

## Data & Backups

All persistent data is stored in `./volumes/`:

| Path                       | Data                  |
|----------------------------|-----------------------|
| `./volumes/postgres/`      | PostgreSQL database   |
| `./volumes/images/`        | Uploaded media files  |
| `./volumes/cache/`         | MediaWiki cache       |
| `./volumes/LocalSettings.php` | MediaWiki config   |

This folder is **gitignored** — data stays local and is never pushed to the repository.

To backup, simply copy the `./volumes/` folder.
