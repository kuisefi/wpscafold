# WPScafold - WordPress Scafold Container

A Docker-based scaffold for rapid WordPress development with Composer, WP-CLI, and optional frontend tooling.  
This project provides a reproducible, containerized environment for WordPress, including utilities for code quality, backups, and automated testing.

---

## Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Environment Configuration](#environment-configuration)
  - [Build and Start Containers](#build-and-start-containers)
- [Makefile Commands](#makefile-commands)
- [Development Workflow](#development-workflow)
- [Testing & Validation](#testing--validation)
- [Backups](#backups)
- [Frontend Workflow](#frontend-workflow)
- [Troubleshooting](#troubleshooting)
- [References](#references)
- [License](#license)

---

## Features

- **WordPress** installed and managed via Composer
- **Docker Compose** for PHP, MariaDB, and optional frontend containers
- **WP-CLI** for WordPress automation
- **Code quality** checks (PHP CodeSniffer with WordPress Coding Standards, config validation, etc.)
- **Automated tests** and validation scripts
- **Backup and restore** utilities
- **Frontend tooling** (Yarn, Storybook, linting) via Node.js container
- **Customizable via `.env`**

---

## Project Structure

```
.
├── backend/                # WordPress codebase and Composer config
├── docker/                 # Dockerfiles and container configs
├── scripts/                # Utility scripts and Makefile includes
│   ├── composer/
│   ├── git_hooks/
│   └── makefile/
├── .env                    # Project environment variables (copy from .env.default)
├── Makefile                # Main entry for all automation
└── README.md               # This documentation
```

---

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)
- [GNU Make](https://www.gnu.org/software/make/)

### Environment Configuration

1. **Copy the default environment file:**

   ```sh
   cp .env.default .env
   ```

2. **Edit `.env`** to customize project name, database, and other settings as needed.

### Build and Start Containers

To build and start all containers, run:

```sh
make all
```

This will:
- Build and start Docker containers
- Install backend dependencies
- Install WordPress and create admin/test users
- Set up git hooks and display access info

To stop and remove all containers:

```sh
make down
```

---

## Makefile Commands

Run `make help` to see all available targets.

| Target         | Description                                                                 |
|----------------|-----------------------------------------------------------------------------|
| `all`          | Full site install from scratch (provision, install, info, restart)          |
| `provision`    | Build and start containers, install extra PHP packages                      |
| `back`         | Install backend dependencies (Composer)                                     |
| `si`           | Install WordPress and create users                                          |
| `info`         | Show container and credential info                                          |
| `exec`         | Open shell in PHP container as regular user                                 |
| `exec0`        | Open shell in PHP container as root                                         |
| `down`         | Stop and remove containers, volumes, and browser driver                     |
| `clean`        | Remove build folders, containers, network, DB data, and Composer cache      |
| `dev`          | Enable development mode (Composer install, set permissions)                 |
| `wp`           | Run WP-CLI command in PHP container (pass args after `--`)                  |
| `restart`      | Restart all Docker Compose services                                         |

### Code Quality & Validation

| Target           | Description                                         |
|------------------|-----------------------------------------------------|
| `phpcs-wp`       | Run PHP CodeSniffer with WordPress Coding Standards |
| `phpcbf-wp`      | Auto-fix code style issues for WordPress standard   |
| `clang`          | Validate langcode of base config files              |
| `cinsp`          | Validate configuration schema                       |
| `compval`        | Validate `composer.json`                            |
| `hookupdateval`  | Validate `hook_update_N()` for field storage changes|
| `watchdogval`    | Validate watchdog logs for high-severity messages   |
| `upgradestatusval`| Validate upgrade status                            |
| `newlineeof`     | Check for newline at end of files                   |
| `sniffers`       | Run all code sniffers and basic validations         |
| `tests`          | Run all tests and validations                       |

---

### Backups

| Target   | Description                      |
|----------|----------------------------------|
| `backup` | Create a backup of DB and files  |

### Frontend Workflow

| Target             | Description                                 |
|--------------------|---------------------------------------------|
| `front`            | Install frontend dependencies & build assets|
| `front-install`    | Install frontend dependencies (Yarn)        |
| `front-build`      | Build frontend assets                       |
| `lintval`          | Run theme linters                           |
| `lint`             | Run theme linters with auto-fix             |
| `storybook`        | Run dynamic Storybook server                |
| `build-storybook`  | Export static Storybook                     |
| `create-component` | Start CLI dialog to create a new component  |
| `clear-front`      | Clean node_modules and dist in theme        |

---

## Development Workflow

1. **Start containers:**  
   `make all`

2. **Access WordPress:**  
   Open [http://localhost](http://localhost) (or your configured domain).

3. **Run WP-CLI commands:**  
   `make wp -- <command>`  
   Example: `make wp -- plugin list`

4. **Install plugins:**  
   Set `PLUGINS` in `.env` or run WP-CLI via `make wp`.

5. **Frontend development:**  
   - Place your theme in `backend/web/themes/custom/<THEME_NAME>`
   - Use `make front`, `make storybook`, etc.

---

## Testing & Validation

- Run all code quality checks:  
  `make tests`

- Run only code sniffers:  
  `make sniffers`

- Validate WordPress code style:  
  `make phpcs-wp`

- Auto-fix WordPress code style:  
  `make phpcbf-wp`

---

## Backups

To create a backup of the database and files:

```sh
make backup
```

Backup files will be created in the project root.

---

## Frontend Workflow

- **Install dependencies & build:**  
  `make front`

- **Run Storybook:**  
  `make storybook`

- **Lint and fix:**  
  `make lintval` or `make lint`

- **Create new component:**  
  `make create-component`

---

## Troubleshooting

- **Containers not starting:**  
  Check Docker logs: `docker compose logs`

- **Permission issues:**  
  Ensure `CUID` and `CGID` in `.env` match your host user/group.

- **Database connection errors:**  
  Confirm DB settings in `.env` and that the `db` service is running.

- **Composer or WP-CLI errors:**  
  Run `make dev` to reinstall dependencies and fix permissions.

---

## References

- [WordPress + Composer](https://www.liquidweb.com/wordpress/build/composer/)
- [WP-CLI](https://wp-cli.org/)
- [Docker Compose](https://docs.docker.com/compose/)
- [PHP CodeSniffer for WordPress](https://github.com/WordPress/WordPress-Coding-Standards)
- [Storybook](https://storybook.js.org/)


---
### Additional information:  
https://gridpane.com/kb/useful-wp-cli-commands/
https://gist.github.com/gemmadlou/6fc40583318430f77eda54ebea91c2a1

---

## License

MIT License  
Copyright (c) 2025 Ivan F

See [LICENSE](LICENSE) for details.