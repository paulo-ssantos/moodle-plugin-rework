#!/bin/bash

# ==============================================================================
# Script de Setup Docker - Moodle + TimescaleDB
# ==============================================================================
# Facilita o uso do Docker Compose para este projeto
# ==============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                                ║${NC}"
echo -e "${CYAN}║  ${BLUE}Moodle + TimescaleDB - Docker Setup${NC}${CYAN}                            ║${NC}"
echo -e "${CYAN}║                                                                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se está na pasta docker/
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}✗ Erro: Execute este script de dentro da pasta docker/${NC}"
    echo "  cd docker && ./setup.sh"
    exit 1
fi

# ==============================================================================
# Menu de opções
# ==============================================================================

show_menu() {
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    echo ""
    echo "  1) Subir todos os containers"
    echo "  2) Parar todos os containers"
    echo "  3) Ver status dos containers"
    echo "  4) Ver logs"
    echo "  5) Instalar Moodle"
    echo "  6) Acessar shell do Moodle"
    echo "  7) Resetar tudo (⚠️  APAGA DADOS!)"
    echo "  8) Rebuild containers"
    echo "  9) Sair"
    echo ""
}

# ==============================================================================
# Funções
# ==============================================================================

start_containers() {
    echo -e "${YELLOW}Subindo containers...${NC}"
    docker-compose up -d
    echo ""
    echo -e "${GREEN}✓ Containers iniciados!${NC}"
    echo ""
    echo "Acesse:"
    echo "  Moodle:  http://localhost:8080"
    echo "  Adminer: http://localhost:8081"
}

stop_containers() {
    echo -e "${YELLOW}Parando containers...${NC}"
    docker-compose stop
    echo -e "${GREEN}✓ Containers parados${NC}"
}

show_status() {
    echo -e "${YELLOW}Status dos containers:${NC}"
    echo ""
    docker-compose ps
}

show_logs() {
    echo -e "${YELLOW}Escolha o serviço:${NC}"
    echo "  1) moodle"
    echo "  2) postgres"
    echo "  3) timescaledb"
    echo "  4) todos"
    echo ""
    read -p "Opção: " -n 1 -r
    echo ""
    echo ""

    case $REPLY in
        1) docker-compose logs -f moodle ;;
        2) docker-compose logs -f postgres ;;
        3) docker-compose logs -f timescaledb ;;
        4) docker-compose logs -f ;;
        *) echo "Opção inválida" ;;
    esac
}

install_moodle() {
    echo -e "${YELLOW}Instalando Moodle...${NC}"
    echo ""

    # Verificar se containers estão rodando
    if ! docker-compose ps | grep -q "Up"; then
        echo -e "${RED}✗ Containers não estão rodando!${NC}"
        echo "Execute a opção 1 primeiro."
        return 1
    fi

    docker exec -it moodle_app php admin/cli/install.php \
        --lang=pt_br \
        --wwwroot=http://localhost:8080 \
        --dataroot=/var/moodledata \
        --dbtype=pgsql \
        --dbhost=postgres \
        --dbname=moodle \
        --dbuser=moodleuser \
        --dbpass='Moodle@2025!Strong' \
        --fullname="Moodle TCC - TimescaleDB" \
        --shortname="tcc" \
        --adminuser=admin \
        --adminpass='Admin@2025!TCC' \
        --adminemail=admin@example.com \
        --agree-license \
        --allow-unstable \
        --non-interactive

    echo ""
    echo -e "${GREEN}✓ Moodle instalado!${NC}"
    echo ""
    echo "Acesse: http://localhost:8080"
    echo "Login: admin / Admin@2025!TCC"
}

shell_moodle() {
    echo -e "${YELLOW}Abrindo shell no container do Moodle...${NC}"
    docker exec -it moodle_app bash
}

reset_all() {
    echo -e "${RED}⚠️  ATENÇÃO: Isso vai APAGAR TODOS OS DADOS!${NC}"
    read -p "Tem certeza? Digite 'sim' para confirmar: " CONFIRM

    if [ "$CONFIRM" = "sim" ]; then
        echo -e "${YELLOW}Removendo containers e volumes...${NC}"
        docker-compose down -v
        echo -e "${GREEN}✓ Tudo removido!${NC}"
        echo "Execute a opção 1 para começar do zero."
    else
        echo "Cancelado."
    fi
}

rebuild_containers() {
    echo -e "${YELLOW}Reconstruindo containers...${NC}"
    docker-compose up -d --build
    echo -e "${GREEN}✓ Containers reconstruídos!${NC}"
}

# ==============================================================================
# Loop do menu
# ==============================================================================

while true; do
    show_menu
    read -p "Opção: " -n 1 -r
    echo ""
    echo ""

    case $REPLY in
        1) start_containers ;;
        2) stop_containers ;;
        3) show_status ;;
        4) show_logs ;;
        5) install_moodle ;;
        6) shell_moodle ;;
        7) reset_all ;;
        8) rebuild_containers ;;
        9)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida${NC}"
            ;;
    esac

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
done
