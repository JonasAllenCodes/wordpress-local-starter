# WordPress Local Starter

A robust, Docker Compose-powered WordPress development environment using the official [WordPress Docker image](https://hub.docker.com/_/wordpress) and MySQL. This project comes with ready-to-use scripts for syncing files and databases between local, staging, and production environments.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Setup](#setup)
- [Environment Variables](#environment-variables)
- [Running the Project](#running-the-project)
- [Deployment Scripts](#deployment-scripts)
- [Testing](#testing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

---

## Prerequisites

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/)
- `bash` (for running sync scripts)
- SSH access to your staging/production servers (for remote syncs)

---

## Project Structure

```
.
├── docker-compose.yml
├── .env.example
├── scripts/
│   ├── sync-db-local-to-prod.sh
│   ├── sync-db-local-to-stage.sh
│   ├── sync-db-prod-to-local.sh
│   ├── sync-db-prod-to-stage.sh
│   ├── sync-db-stage-to-local.sh
│   ├── sync-db-stage-to-prod.sh
│   ├── sync-files-local-to-prod.sh
│   ├── sync-files-local-to-stage.sh
│   ├── sync-files-prod-to-local.sh
│   ├── sync-files-prod-to-stage.sh
│   ├── sync-files-stage-to-local.sh
│   ├── sync-files-stage-to-prod.sh
│   ├── sync-local-to-prod.sh
│   ├── sync-local-to-stage.sh
│   ├── sync-prod-to-local.sh
│   ├── sync-prod-to-stage.sh
│   ├── sync-stage-to-local.sh
│   └── sync-stage-to-prod.sh
├── ... (WordPress and project files)
```

> **Note:** Only a portion of the scripts are shown above. [View the full script listing here.](https://github.com/JonasAllenCodes/wordpress-local-starter/tree/main/scripts)

---

## Setup

1. **Clone the repository:**

   ```sh
   git clone https://github.com/JonasAllenCodes/wordpress-local-starter.git
   cd wordpress-local-starter
   ```

2. **Copy the example environment file and configure it:**

   ```sh
   cp .env.example .env
   # Edit .env with your preferred settings
   ```

3. **(Optional) Prepare SSH keys** for remote environments if you plan to use sync scripts.

---

## Environment Variables

All environment variables are configured in `.env`. Refer to `.env.example` for a full list. Key variables include:

- `LOCAL_PROJECT_NAME` — Name of your local project (used for containers, etc.)
- `LOCAL_DB_NAME`, `LOCAL_DB_USER`, `LOCAL_DB_PASSWORD`, `LOCAL_DB_ROOT_PASSWORD` — Local MySQL settings
- `LOCAL_DB_VERSION`, `LOCAL_WP_VERSION` — MySQL and WordPress versions (default to latest if unset)
- `LOCAL_WP_PORT` — Port for local WordPress (default: 8000)
- `LOCAL_WP_URL` — Local WordPress site URL
- `LOCAL_DB_CONTAINER` — Name of the local DB container
- **Production Variables:** `PROD_SSH`, `PROD_DB_NAME`, `PROD_DB_USER`, `PROD_DB_PASSWORD`, `PROD_DB_ROOT_PASSWORD`, `PROD_WP_CONTAINER`, `PROD_WP_PATH`, `PROD_WP_URL`
- **Staging Variables:** `STAGE_SSH`, `STAGE_DB_NAME`, `STAGE_DB_USER`, `STAGE_DB_PASSWORD`, `STAGE_DB_ROOT_PASSWORD`, `STAGE_WP_PATH`, `STAGE_DB_CONTAINER`, `STAGE_WP_URL`

> See comments in `.env.example` for details on each variable.

---

## Running the Project

1. **Start Docker Compose:**

   ```sh
   docker-compose up -d
   ```

2. **Access your local WordPress site:**
   Visit `http://localhost:${LOCAL_WP_PORT}` (default: `http://localhost:8000`).

3. **Stop and remove containers and networks:**
   ```sh
   docker-compose down
   ```
   This will stop and remove all containers, networks, and volumes created by `up`. Use this command when you want to shut everything down safely.

---

## Deployment Scripts

Sync your files and database between environments using the scripts in the `scripts/` directory. Some commonly used scripts:

- **Database Sync:**

  - Local → Prod: [`sync-db-local-to-prod.sh`](scripts/sync-db-local-to-prod.sh)
  - Local → Stage: [`sync-db-local-to-stage.sh`](scripts/sync-db-local-to-stage.sh)
  - Prod → Local: [`sync-db-prod-to-local.sh`](scripts/sync-db-prod-to-local.sh)
  - Stage → Local: [`sync-db-stage-to-local.sh`](scripts/sync-db-stage-to-local.sh)
  - ...and more

- **File Sync:**

  - Local → Prod: [`sync-files-local-to-prod.sh`](scripts/sync-files-local-to-prod.sh)
  - Local → Stage: [`sync-files-local-to-stage.sh`](scripts/sync-files-local-to-stage.sh)
  - Prod → Local: [`sync-files-prod-to-local.sh`](scripts/sync-files-prod-to-local.sh)
  - Stage → Local: [`sync-files-stage-to-local.sh`](scripts/sync-files-stage-to-local.sh)
  - ...and more

- **Full Environment Sync:**
  - Local → Prod: [`sync-local-to-prod.sh`](scripts/sync-local-to-prod.sh)
  - Local → Stage: [`sync-local-to-stage.sh`](scripts/sync-local-to-stage.sh)
  - Prod → Local: [`sync-prod-to-local.sh`](scripts/sync-prod-to-local.sh)
  - Stage → Local: [`sync-stage-to-local.sh`](scripts/sync-stage-to-local.sh)

> Ensure you have configured the relevant environment variables in `.env` before running any scripts.

> **More scripts may exist. [Browse all scripts here.](https://github.com/JonasAllenCodes/wordpress-local-starter/tree/main/scripts)**

---

## Testing

- **Manual:** After setup, visit your local site and verify WordPress loads and you can log in.
- **Automated:** Add your own tests or use [WordPress test plugins](https://wordpress.org/plugins/tags/test/) as needed.
- **Docker Healthchecks:** Optionally add [healthcheck configuration](https://docs.docker.com/compose/compose-file/05-services/#healthcheck) to your `docker-compose.yml` for CI/CD integration.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [WordPress Docker Image](https://hub.docker.com/_/wordpress)
- [Docker](https://www.docker.com/)
- [MySQL Docker Image](https://hub.docker.com/_/mysql)
- [JonasAllenCodes/wordpress-local-starter](https://github.com/JonasAllenCodes/wordpress-local-starter)

---
