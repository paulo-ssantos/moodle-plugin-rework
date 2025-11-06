FROM php:8.2-apache

LABEL maintainer="TCC Moodle + TimescaleDB"
LABEL description="Moodle LMS com suporte a TimescaleDB para logs"

# ==============================================================================
# Variáveis de ambiente
# ==============================================================================
ENV DEBIAN_FRONTEND=noninteractive \
    MOODLE_VERSION=5.2 \
    PHP_MEMORY_LIMIT=512M \
    PHP_MAX_INPUT_VARS=5000 \
    PHP_POST_MAX_SIZE=512M \
    PHP_UPLOAD_MAX_FILESIZE=512M

# ==============================================================================
# Instalar dependências do sistema
# ==============================================================================
RUN apt-get update && apt-get install -y \
    # Ferramentas básicas
    git \
    curl \
    wget \
    unzip \
    zip \
    libzip-dev \
    # Bibliotecas para PHP
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libxml2-dev \
    libpq-dev \
    libldap2-dev \
    libonig-dev \
    # Utilitários
    cron \
    vim \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Configurar extensões GD
# ==============================================================================
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg

# ==============================================================================
# Instalar extensões PHP necessárias para Moodle
# ==============================================================================
RUN docker-php-ext-install -j$(nproc) \
    gd \
    intl \
    pgsql \
    pdo_pgsql \
    opcache \
    soap \
    zip \
    exif \
    mbstring \
    xml \
    xmlrpc

# ==============================================================================
# Configurar PHP
# ==============================================================================
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.use_cwd=1'; \
    echo 'opcache.validate_timestamps=1'; \
    echo 'opcache.save_comments=1'; \
    echo 'opcache.enable_file_override=0'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
    echo 'max_input_vars = 5000'; \
    echo 'memory_limit = 512M'; \
    echo 'post_max_size = 512M'; \
    echo 'upload_max_filesize = 512M'; \
    echo 'max_execution_time = 300'; \
    echo 'max_input_time = 300'; \
    echo 'session.save_handler = files'; \
    echo 'session.save_path = /var/moodledata/sessions'; \
} > /usr/local/etc/php/conf.d/moodle.ini

# ==============================================================================
# Configurar Apache
# ==============================================================================
RUN a2enmod rewrite expires headers

# Configurar DocumentRoot para /var/www/html
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html|g' /etc/apache2/sites-available/000-default.conf

# Permitir .htaccess
RUN { \
    echo '<Directory /var/www/html>'; \
    echo '    Options Indexes FollowSymLinks'; \
    echo '    AllowOverride All'; \
    echo '    Require all granted'; \
    echo '</Directory>'; \
} >> /etc/apache2/sites-available/000-default.conf

# ==============================================================================
# Criar diretórios necessários
# ==============================================================================
RUN mkdir -p /var/moodledata \
    && mkdir -p /var/moodledata/sessions \
    && chown -R www-data:www-data /var/moodledata \
    && chmod -R 0777 /var/moodledata

# ==============================================================================
# Instalar Composer
# ==============================================================================
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ==============================================================================
# Instalar Node.js (para build de assets)
# ==============================================================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Configurar diretório de trabalho
# ==============================================================================
WORKDIR /var/www/html

# ==============================================================================
# Script de inicialização
# ==============================================================================
COPY docker/moodle/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# ==============================================================================
# Healthcheck
# ==============================================================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# ==============================================================================
# Expor porta
# ==============================================================================
EXPOSE 80

# ==============================================================================
# Entrypoint
# ==============================================================================
ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
