FROM alpine:latest

# Defining arguments
ARG COMPOSER_HASH
ARG DRUSH_VERSION
ARG PHPV
ARG BUILD_DATE
ARG VCS_REF

# Metadata
LABEL org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.schema-version="1.0" \
  org.label-schema.name="docker-php-prod" \
  org.label-schema.description="Production-ready PHP 8.4 with Nginx Unit, Composer, and WordPress" \
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
  # First, install ca-certificates insecurely to fix the SSL issue
  apk add --no-cache ca-certificates --no-check-certificate; \
  apk add --no-cache \
  unit unit-php${PHPV} \
  php${PHPV} \
  php${PHPV}-brotli \
  php${PHPV}-pecl-memcache \
  php${PHPV}-pecl-apcu \
  php${PHPV}-pecl-igbinary \
  php${PHPV}-pecl-uploadprogress \
  php${PHPV}-pecl-xdebug \
  php${PHPV}-bcmath php${PHPV}-ctype php${PHPV}-curl php${PHPV}-dom php${PHPV}-fileinfo \
  php${PHPV}-gd php${PHPV}-gmp php${PHPV}-iconv php${PHPV}-mbstring php${PHPV}-opcache \
  php${PHPV}-openssl php${PHPV}-pcntl php${PHPV}-pdo_mysql php${PHPV}-pdo_sqlite \
  php${PHPV}-phar php${PHPV}-session php${PHPV}-simplexml php${PHPV}-sqlite3 \
  php${PHPV}-tokenizer php${PHPV}-xml php${PHPV}-xmlreader php${PHPV}-xmlwriter php${PHPV}-zip \
  php${PHPV}-mysqli \
  mariadb-client \
  openssh-client \
  curl git make rsync patch openldap-clients unzip bash sqlite \
  && ln -fs php${PHPV} /usr/bin/php

# Add the Xdebug configuration file for Nginx Unit
RUN echo "zend_extension=xdebug.so" > /etc/php${PHPV}/conf.d/50-xdebug.ini && \
    echo "xdebug.mode=debug" >> /etc/php${PHPV}/conf.d/50-xdebug.ini && \
    echo "xdebug.start_with_request=yes" >> /etc/php${PHPV}/conf.d/50-xdebug.ini && \
    echo "xdebug.client_host=host.docker.internal" >> /etc/php${PHPV}/conf.d/50-xdebug.ini && \
    echo "xdebug.log=/var/www/html/xdebug.log" >> /etc/php${PHPV}/conf.d/50-xdebug.ini

# Add configuration to display errors
RUN echo "display_errors = On" > /etc/php${PHPV}/conf.d/50-errors.ini && \
    echo "error_reporting = E_ALL" >> /etc/php${PHPV}/conf.d/50-errors.ini


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
