# WordPress Local Starter

A robust, Docker Compose-powered WordPress development environment designed for a seamless workflow between local, staging, and production environments. This starter kit leverages the official WordPress and MySQL Docker images to create a consistent and reliable development environment, while providing a powerful suite of scripts to simplify database and file synchronization.

## Features

- **Dockerized Environment:** Run a complete WordPress stack locally without installing PHP, MySQL, or Apache on your machine.
- **Environment-Based Configuration:** Easily configure your local, staging, and production settings in a single `.env` file.
- **Effortless Syncing:** A comprehensive set of scripts to push and pull your database and files between environments.
- **Automated Backups:** Create timestamped backups of your database and files for any environment.

## Prerequisites

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/)
- `bash` (for running sync and backup scripts)
- SSH access to your staging and production servers

## Project Structure

```
.
├── docker-compose.yml
├── .env.example
├── backups/
├── scripts/
│   ├── backup-local-db.sh
│   ├── backup-local-files.sh
│   ├── backup-local.sh
│   ├── backup-prod-db.sh
│   ├── backup-prod-files.sh
│   ├── backup-prod.sh
│   ├── backup-staging-db.sh
│   ├── backup-staging-files.sh
│   ├── backup-staging.sh
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
└── wp-content/
```

## Getting Started

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/JonasAllenCodes/wordpress-local-starter.git
    cd wordpress-local-starter
    ```

2.  **Configure your environment:**
    Copy the example environment file and customize it with your settings.
    ```sh
    cp .env.example .env
    ```
    Open the `.env` file and fill in the required variables for your local, staging, and production environments.

3.  **Start the project:**
    ```sh
    docker-compose up -d
    ```
    This will build and start the WordPress and MySQL containers in the background.

4.  **Access your local site:**
    Open your web browser and navigate to `http://localhost:${LOCAL_WP_PORT}` (the default port is `8080`).

## Managing `wp-content/`

The `wp-content/` directory is intentionally ignored by this starter project's Git repository. This allows you to manage your themes, plugins, and uploads as a completely separate Git repository for each individual project you create using this starter. This ensures that you can pull updates to the starter's environment and scripts without affecting your project-specific WordPress content.

When you clone this starter, the `wp-content/` directory will be empty. You have two main options:

### Option 1: Start a New `wp-content/` Repository

If you are starting a brand new WordPress project, you can initialize a new Git repository within the `wp-content/` directory:

```sh
cd wp-content
git init
git add .
git commit -m "Initial commit for wp-content"
# Link to your remote repository (e.g., GitHub, GitLab, Bitbucket)
git remote add origin <your-wp-content-repo-url>
git push -u origin master
```

### Option 2: Clone an Existing `wp-content/` Repository

If you have an existing WordPress project with its `wp-content/` directory already under Git version control, you can clone it directly into the `wp-content/` directory after cloning this starter:

```sh
cd wp-content
git clone <your-existing-wp-content-repo-url> .
```

Remember to configure your `.env` file and start your Docker containers as described in the "Getting Started" section.

## Running the Project

-   **Start the containers:**
    ```sh
    docker-compose up -d
    ```

-   **Stop the containers:**
    ```sh
    docker-compose down
    ```

## Scripts

All scripts are located in the `scripts/` directory and are designed to be run from the project root.

### Sync Scripts

The sync scripts allow you to move your database and files between your local, staging, and production environments.

| Script                         | Description                                             |
| ------------------------------ | ------------------------------------------------------- |
| `sync-db-[source]-to-[dest].sh`  | Syncs the database from the source to the destination.  |
| `sync-files-[source]-to-[dest].sh` | Syncs the `wp-content` directory to the destination.    |
| `sync-[source]-to-[dest].sh`     | Syncs both the database and files to the destination. |

**Example:** To sync the production database to your local environment, run:
```sh
./scripts/sync-db-prod-to-local.sh
```

### Backup Scripts

The backup scripts create timestamped backups of your database and files, storing them in the `backups/` directory.

| Script                      | Description                                       |
| --------------------------- | ------------------------------------------------- |
| `backup-[env]-db.sh`        | Backs up the database for the specified environment. |
| `backup-[env]-files.sh`     | Backs up the files for the specified environment.   |
| `backup-[env].sh`           | Backs up both the database and files.             |

**Example:** To back up the local database, run:
```sh
./scripts/backup-local-db.sh
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- [WordPress Docker Image](https://hub.docker.com/_/wordpress)
- [MySQL Docker Image](https://hub.docker.com/_/mysql)