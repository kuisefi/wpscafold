FROM alpine:latest

# Defining arguments
ARG COMPOSER_HASH
ARG DRUSH_VERSION
ARG PHPV=82
ARG BUILD_DATE
ARG VCS_REF

# Metadata
LABEL org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.schema-version="1.0" \
  org.label-schema.name="docker-php-prod" \
  org.label-schema.description="Production-ready PHP 8.2 with Nginx Unit, Composer, and WordPress" \
  org.label-schema.vcs-url="https://github.com/eneus" \
  maintainer="Ivan F <2290816+eneus@users.noreply.github.com>"

ENV PHPRUN_DEPS \
  curl \
  git \
  make \
  mariadb-client \
  openssh-client \
  patch \
  rsync \
  sqlite

# Update the system and install the necessary packages
RUN set -eux; \
  apk add --no-cache \
  unit unit-php${PHPV} \
  php82 \
  php82-brotli \
  php82-pecl-apcu \
  php82-pecl-igbinary \
  php82-pecl-uploadprogress \
  php82-bcmath php82-ctype php82-curl php82-dom php82-fileinfo \
  php82-gd php82-gmp php82-iconv php82-mbstring php82-opcache \
  php82-openssl php82-pcntl php82-pdo_mysql php82-pdo_sqlite \
  php82-phar php82-session php82-simplexml php82-sqlite3 \
  php82-tokenizer php82-xml php82-xmlreader php82-xmlwriter php82-zip \
  php82-mysqli \
  mariadb-client \
  openssh-client \
  curl git make rsync patch openldap-clients unzip bash sqlite \
  $PHPRUN_DEPS \
  && ln -fs php82 /usr/bin/php

# Create a user to run the server
RUN addgroup -g 1000 -S web-group && \
    adduser -u 1000 -D -S -G web-group web-user

# Specify the working directory
WORKDIR /var/www/html

# Installing Composer (latest stable version)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Installing WP-CLI (latest stable version)
ADD https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar /usr/local/bin/wp
RUN chmod 755 /usr/local/bin/wp && php /usr/local/bin/wp --info

# Switch to web-user for installing Composer & Drush
USER web-user

# Verify WP-CLI works for web-user
# This command will run during the build process and fail if wp is not accessible or executable by web-user
RUN wp --info

# Copy the application files (assuming the local directory ./app contains the code)
COPY backend /var/www/html

# Copying the Nginx Unit configuration
COPY docker/conf.json /var/lib/unit/conf.json

# Switch back to root user for final setup
USER root

# Change ownership to web-user & learing Alpine cache after installation
RUN chown -R web-user:web-group /var/www/html && \
    chmod -R 755 /var/www/html

# Opening the port
EXPOSE 80

# Launching Nginx Unit
CMD ["unitd", "--no-daemon", "--user", "web-user", "--group", "web-group", "--log", "/dev/stdout"]
