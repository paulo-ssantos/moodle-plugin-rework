#!/bin/bash
set -e

echo "=========================================="
echo "Moodle Docker - Entrypoint"
echo "=========================================="

# ==============================================================================
# Aguardar banco de dados estar pronto
# ==============================================================================
echo "Aguardando PostgreSQL..."
until pg_isready -h "$MOODLE_DATABASE_HOST" -p "$MOODLE_DATABASE_PORT" -U "$MOODLE_DATABASE_USER"; do
    echo "PostgreSQL não está pronto - aguardando..."
    sleep 2
done
echo "✓ PostgreSQL está pronto!"

# ==============================================================================
# Verificar se Moodle já está instalado
# ==============================================================================
if [ ! -f "/var/www/html/config.php" ]; then
    echo ""
    echo "=========================================="
    echo "Moodle não está configurado"
    echo "=========================================="
    echo ""
    echo "⚠  IMPORTANTE:"
    echo "   Para instalar o Moodle, execute dentro do container:"
    echo ""
    echo "   docker exec -it moodle_app bash"
    echo "   php admin/cli/install.php \\"
    echo "       --lang=pt_br \\"
    echo "       --wwwroot=\$MOODLE_URL \\"
    echo "       --dataroot=/var/moodledata \\"
    echo "       --dbtype=\$MOODLE_DATABASE_TYPE \\"
    echo "       --dbhost=\$MOODLE_DATABASE_HOST \\"
    echo "       --dbname=\$MOODLE_DATABASE_NAME \\"
    echo "       --dbuser=\$MOODLE_DATABASE_USER \\"
    echo "       --dbpass=\$MOODLE_DATABASE_PASSWORD \\"
    echo "       --fullname=\"\$MOODLE_FULLNAME\" \\"
    echo "       --shortname=\$MOODLE_SHORTNAME \\"
    echo "       --adminuser=\$MOODLE_ADMIN \\"
    echo "       --adminpass=\$MOODLE_ADMIN_PASSWORD \\"
    echo "       --adminemail=\$MOODLE_ADMIN_EMAIL \\"
    echo "       --agree-license \\"
    echo "       --allow-unstable \\"
    echo "       --non-interactive"
    echo ""
    echo "=========================================="
    echo ""
else
    echo "✓ Moodle já está configurado"
fi

# ==============================================================================
# Ajustar permissões
# ==============================================================================
echo "Ajustando permissões..."
chown -R www-data:www-data /var/moodledata
chmod -R 0777 /var/moodledata

if [ -d "/var/www/html" ]; then
    chown -R www-data:www-data /var/www/html
fi

echo "✓ Permissões ajustadas"

# ==============================================================================
# Executar comando
# ==============================================================================
echo ""
echo "Iniciando Apache..."
exec "$@"
