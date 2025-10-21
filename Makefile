# Add utility functions and scripts to the container
include scripts/makefile/*.mk

.PHONY: all provision si exec exec0 down clean dev wp info phpcs phpcbf hooksymlink clang cinsp compval sniffers tests lintval lint back browser_driver browser_driver_stop
.DEFAULT_GOAL := help

# https://stackoverflow.com/a/6273809/1826109
%:
	@:

# Prepare enviroment variables from defaults
$(shell false | cp -i \.env.default \.env 2>/dev/null)
$(shell false | cp -i \.\/docker\/docker-compose\.override\.yml\.default \.\/docker\/docker-compose\.override\.yml 2>/dev/null)
include .env

# Get user/group id to manage permissions between host and containers
LOCAL_UID := $(shell id -u)
LOCAL_GID := $(shell id -g)

# Evaluate recursively
CUID ?= $(LOCAL_UID)
CGID ?= $(LOCAL_GID)

# Define network name.
COMPOSE_NET_NAME := $(COMPOSE_PROJECT_NAME)_front

# Determine mysql data directory if defined
ifeq ($(shell docker-compose config --services | grep mysql),mysql)
    DB_DATA_DIR=$(CURDIR)/docker/$(COMPOSE_PROJECT_NAME)_mysql
endif

# Define current directory only once
CURDIR=$(shell pwd)

# Execute php container as regular user
php = docker compose exec -T --user $(CUID):$(CGID) php ${1}
# Execute php container as root user
php-0 = docker compose exec -T --user 0:0 php ${1}

## Full site install from the scratch
all: | provision back si hooksymlink info restart

## Provision enviroment
provision:
# Check if enviroment variables has been defined
ifeq ($(strip $(COMPOSE_PROJECT_NAME)),projectname)
	$(eval COMPOSE_PROJECT_NAME = $(strip $(shell read -p "- Please customize project name: " REPLY;echo -n $$REPLY)))
	$(shell sed -i -e '/COMPOSE_PROJECT_NAME=/ s/=.*/=$(shell echo "$(COMPOSE_PROJECT_NAME)" | tr -cd '[a-zA-Z0-9]' | tr '[:upper:]' '[:lower:]')/' .env)
	$(info - Run `make all` again.)
	@echo
	exit 1
endif
ifdef DB_MOUNT_DIR
	$(shell [ ! -d $(DB_MOUNT_DIR) ] && mkdir -p $(DB_MOUNT_DIR) && chmod 777 $(DB_MOUNT_DIR))
endif
	make -s down
	@echo "Build and run containers..."
	docker compose up -d --remove-orphans
ifneq ($(strip $(ADDITIONAL_PHP_PACKAGES)),)
	@echo "line 70: Install additional PHP packages..."
	$(call php-0, apk add --no-cache $(ADDITIONAL_PHP_PACKAGES))
endif
	# Set up timezone
	# $(call php-0, cp /usr/share/zoneinfo/Europe/Kyiv /etc/localtime)
	# Install newrelic PHP extension if NEW_RELIC_LICENSE_KEY defined
	# make -s newrelic
	# $(call php-0, /bin/sh ./scripts/makefile/reload.sh)

## Install backend dependencies
back:
	@if [ -n "$(strip $(ADDITIONAL_PHP_PACKAGES))" ]; then \
		echo "line 82: Install additional PHP packages..."; \
		$(call php-0, apk add --no-cache ca-certificates $(ADDITIONAL_PHP_PACKAGES)); \
	fi
	@echo "Installing WordPress..."
ifeq ($(strip $(COMPOSER)),yes)
	@if [ -d "./vendor" ]; then \
		echo "Vendor directory already exists, skipping composer install."; \
	else \
		echo "Run composer install..."; \
		$(MAKE) composer_install; \
	fi
	$(call php, composer install --no-interaction --prefer-dist -o --no-dev)
else ifeq ($(strip $(COMPOSER)),no)
	$(call php, php -d memory_limit=512M /usr/local/bin/wp core download --path='./web' --force --version=$(WP_VERSION))
endif

## Install WordPress
si:
	@echo "Generate a config file:"
	$(call php, sh -c 'cd web && [ -f wp-config.php ] || wp config create --dbhost=db --dbname=$(COMPOSE_PROJECT_NAME) --dbuser=$(COMPOSE_PROJECT_NAME) --dbpass=$(COMPOSE_PROJECT_NAME)')
	$(call php, sh -c 'cd web && wp core install --url=$(MAIN_DOMAIN_NAME) --title=$(SITE_NAME) --admin_user=$(ADMIN_NAME) --admin_password=$(ADMIN_PW) --admin_email=$(ADMIN_MAIL)')
	@echo "Success: WordPress installed successfully."
	$(call php, sh -c 'cd web && wp user create $(TESTER_NAME) $(TESTER_MAIL) --user_pass=$(TESTER_PW)')

ifneq ($(strip $(PLUGINS)),)
	$(call php, cd web && wp plugin install $(PLUGINS) --activate)
endif

## Display project's information
info:
	$(info Containers for "$(COMPOSE_PROJECT_NAME)" info:)
	$(eval CONTAINERS = $(shell docker ps -f name=$(COMPOSE_PROJECT_NAME) --format "{{ .ID }}" -f 'label=traefik.enable=true'))
	$(foreach CONTAINER, $(CONTAINERS),$(info http://$(shell printf '%-19s \n'  $(shell docker inspect --format='{{(index .NetworkSettings.Networks "$(COMPOSE_NET_NAME)").IPAddress}}:{{index .Config.Labels "traefik.port"}} {{range $$p, $$conf := .NetworkSettings.Ports}}{{$$p}}{{end}} {{.Name}}' $(CONTAINER) | rev | sed "s/pct\//,pct:/g" | sed "s/,//" | rev | awk '{ print $0}')) ))
	@echo "$(RESULT)"
	@echo "System admin role - Login : \"$(ADMIN_NAME)\" - Password : \"$(ADMIN_PW)\""
	@echo "Contributor role - Login : \"$(TESTER_NAME)\" - Password : \"$(TESTER_PW)\""

## Run shell in PHP container as regular user
exec:
	docker compose exec --user $(CUID):$(CGID) php ash

## Run shell in PHP container as root
exec0:
	docker compose exec --user 0:0 php ash

down:
	@echo "Removing network & containers for $(COMPOSE_PROJECT_NAME)"
	@docker compose down -v --remove-orphans --rmi local
	@if [ ! -z "$(shell docker ps -f 'name=$(COMPOSE_PROJECT_NAME)_chrome' --format '{{.Names}}')" ]; then \
		echo 'Stoping browser driver.' && make -s browser_driver_stop; fi

DIRS = $(CODE_BASE_DIR)/web/wp-admin $(CODE_BASE_DIR)/web/wp-includes $(CODE_BASE_DIR)/vendor

DFIlES = $(CODE_BASE_DIR)/web/index.php $(CODE_BASE_DIR)/web/composer.json $(CODE_BASE_DIR)/web/license.txt $(CODE_BASE_DIR)/web/readme.html $(CODE_BASE_DIR)/web/wp-activate.php $(CODE_BASE_DIR)/web/wp-blog-header.php $(CODE_BASE_DIR)/web/wp-comments-post.php $(CODE_BASE_DIR)/web/wp-config-sample.php $(CODE_BASE_DIR)/web/wp-config.php $(CODE_BASE_DIR)/web/wp-cron.php $(CODE_BASE_DIR)/web/wp-links-opml.php $(CODE_BASE_DIR)/web/wp-load.php $(CODE_BASE_DIR)/web/wp-login.php $(CODE_BASE_DIR)/web/wp-mail.php $(CODE_BASE_DIR)/web/wp-settings.php $(CODE_BASE_DIR)/web/wp-signup.php $(CODE_BASE_DIR)/web/wp-trackback.php $(CODE_BASE_DIR)/web/xmlrpc.php

## Totally remove project build folder, docker containers and network
clean: info
	make -s down
	rm -Rf $(SCAFFOLD) $(DFIlES) $(DIRS)
ifdef DB_DATA_DIR
	@echo "Removing mysql data from $(DB_DATA_DIR) ..."
	rm -rf $(DB_DATA_DIR)
endif
ifdef COMPOSER_HOME_CACHE
	@echo "Clean-up composer cache from $(COMPOSER_HOME_CACHE) ..."
	rm -rf $(COMPOSER_HOME_CACHE)
endif

## Enable development mode and disable caching
dev:
	@echo "Dev tasks..."
	$(call php, composer install --prefer-dist -o)
	@$(call php-0, chmod +w $(CODE_BASE_DIR)/web/wp-content)
## Run WP-CLI command in PHP container. To pass arguments use double dash: "make wp -- -y"
wp:
	$(call php, sh -c '$(filter-out "$@",$(MAKECMDGOALS))')
	$(info "To pass arguments use double dash: "make wp --" ")

## Restart all docker compose services
restart:
	@echo "Restarting containers for $(COMPOSE_PROJECT_NAME)"
	docker compose restart