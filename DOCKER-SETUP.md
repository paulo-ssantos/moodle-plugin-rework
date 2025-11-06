# 🐳 Setup Docker Completo - Moodle + TimescaleDB

Este guia explica como rodar **toda a stack** do projeto usando Docker Compose.

## 📦 O Que Está Incluído

O `docker-compose.yml` sobe 4 containers:

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| **postgres** | 5432 | PostgreSQL 14 - Banco principal do Moodle |
| **timescaledb** | 5436 | TimescaleDB - Banco de logs de alta performance |
| **moodle** | 8080 | Moodle 5.2dev com PHP 8.2 + Apache |
| **adminer** | 8081 | Interface web para gerenciar bancos |

## 🚀 Quick Start (Instalação Rápida)

```bash
# 1. Subir todos os containers
docker-compose up -d

# 2. Aguardar containers ficarem saudáveis (1-2 minutos)
docker-compose ps

# 3. Instalar o Moodle
docker exec -it moodle_app php admin/cli/install.php \
    --lang=pt_br \
    --wwwroot=http://localhost:8080 \
    --dataroot=/var/moodledata \
    --dbtype=pgsql \
    --dbhost=postgres \
    --dbname=moodle \
    --dbuser=moodleuser \
    --dbpass='Moodle@2025!Strong' \
    --fullname="Moodle TCC" \
    --shortname="tcc" \
    --adminuser=admin \
    --adminpass='Admin@2025!TCC' \
    --adminemail=admin@example.com \
    --agree-license \
    --allow-unstable \
    --non-interactive

# 4. Acessar o Moodle
# Abra http://localhost:8080
# Login: admin / Admin@2025!TCC
```

## 📋 Passo a Passo Detalhado

### 1️⃣ Preparar o Ambiente

```bash
cd ~/Documentos/Estudos/moodle-plugin-rework

# Verificar se Docker está rodando
docker --version
docker-compose --version
```

### 2️⃣ Subir os Containers

```bash
# Subir em background (-d = detached)
docker-compose up -d

# Ou ver logs em tempo real
docker-compose up
```

**O que acontece:**
- ✅ Cria network `moodle_dev_network`
- ✅ Cria volumes para persistência de dados
- ✅ Sobe PostgreSQL (porta 5432)
- ✅ Sobe TimescaleDB (porta 5436)
- ✅ Sobe Moodle (porta 8080)
- ✅ Sobe Adminer (porta 8081)

### 3️⃣ Verificar Status

```bash
# Ver status dos containers
docker-compose ps

# Deve mostrar algo como:
# NAME                STATUS        PORTS
# moodle_postgres     Up (healthy)  0.0.0.0:5432->5432/tcp
# moodle_timescaledb  Up (healthy)  0.0.0.0:5436->5432/tcp
# moodle_app          Up (healthy)  0.0.0.0:8080->80/tcp
# moodle_adminer      Up            0.0.0.0:8081->8080/tcp
```

### 4️⃣ Instalar o Moodle

```bash
# Entrar no container do Moodle
docker exec -it moodle_app bash

# Dentro do container, instalar o Moodle
php admin/cli/install.php \
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

# Sair do container
exit
```

### 5️⃣ Acessar os Serviços

#### Moodle
- **URL**: http://localhost:8080
- **Usuário**: `admin`
- **Senha**: `Admin@2025!TCC`

#### Adminer (Gerenciador de Banco)
- **URL**: http://localhost:8081
- **Servidor**: `postgres` (ou `timescaledb`)
- **Usuário**: `moodleuser`
- **Senha**: `Moodle@2025!Strong`
- **Banco**: `moodle`

#### Conectar nos Bancos via CLI

```bash
# PostgreSQL (Moodle)
docker exec -it moodle_postgres psql -U moodleuser -d moodle

# TimescaleDB (Logs)
docker exec -it moodle_timescaledb psql -U postgres -d moodle_logs_tsdb
```

## 🔧 Comandos Úteis

### Gerenciar Containers

```bash
# Ver logs
docker-compose logs -f moodle
docker-compose logs -f postgres
docker-compose logs -f timescaledb

# Parar todos os containers
docker-compose stop

# Iniciar containers parados
docker-compose start

# Reiniciar
docker-compose restart

# Parar e remover containers (mantém volumes)
docker-compose down

# Remover TUDO incluindo volumes (⚠️ APAGA DADOS!)
docker-compose down -v
```

### Executar Comandos no Moodle

```bash
# Entrar no container
docker exec -it moodle_app bash

# Limpar cache
docker exec -it moodle_app php admin/cli/purge_caches.php

# Atualizar banco de dados
docker exec -it moodle_app php admin/cli/upgrade.php --non-interactive

# Executar cron
docker exec -it moodle_app php admin/cli/cron.php
```

### Verificar Bancos de Dados

```bash
# PostgreSQL - Ver tabelas
docker exec -it moodle_postgres psql -U moodleuser -d moodle -c "\dt"

# PostgreSQL - Contar usuários
docker exec -it moodle_postgres psql -U moodleuser -d moodle -c "SELECT count(*) FROM mdl_user;"

# TimescaleDB - Ver hypertables
docker exec -it moodle_timescaledb psql -U postgres -d moodle_logs_tsdb -c "SELECT * FROM timescaledb_information.hypertables;"

# TimescaleDB - Contar eventos
docker exec -it moodle_timescaledb psql -U postgres -d moodle_logs_tsdb -c "SELECT count(*) FROM moodle_events;"
```

### Reconstruir Containers

```bash
# Rebuild da imagem do Moodle
docker-compose build moodle

# Rebuild e restart
docker-compose up -d --build
```

## 📊 Estrutura de Volumes

Os dados são persistidos em volumes Docker:

```bash
# Listar volumes
docker volume ls | grep moodle

# Ver detalhes de um volume
docker volume inspect moodle_postgres_data

# Backup de volume (exemplo)
docker run --rm -v moodle_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz /data
```

## 🔐 Credenciais Padrão

### PostgreSQL (Moodle)
- Host: `postgres` (dentro do Docker) ou `localhost:5432` (externo)
- Banco: `moodle`
- Usuário: `moodleuser`
- Senha: `Moodle@2025!Strong`

### TimescaleDB (Logs)
- Host: `timescaledb` (dentro do Docker) ou `localhost:5436` (externo)
- Banco: `moodle_logs_tsdb`
- Usuário: `postgres`
- Senha: `Moodle@TSDB2025!`

### Moodle Admin
- Usuário: `admin`
- Senha: `Admin@2025!TCC`
- Email: `admin@example.com`

### Adminer
- URL: http://localhost:8081
- Sem autenticação específica (usa credenciais do banco)

## 🧪 Rodar Simulação com Docker

A simulação Python deve rodar **fora** do Docker, apontando para `localhost:8080`:

```bash
cd scripts/simulation
source venv/bin/activate

# Certifique-se que config.json tem:
# "base_url": "http://localhost:8080"
# "wstoken": "SEU_TOKEN_AQUI"

python generate_load.py --mode burst --duration 60
```

## 🐛 Troubleshooting

### Container não sobe

```bash
# Ver logs de erro
docker-compose logs

# Verificar portas em uso
sudo lsof -i :8080
sudo lsof -i :5432
```

### Erro de permissão no moodledata

```bash
# Ajustar permissões do volume
docker exec -it moodle_app chown -R www-data:www-data /var/moodledata
docker exec -it moodle_app chmod -R 0777 /var/moodledata
```

### Resetar tudo e começar do zero

```bash
# CUIDADO: Apaga TODOS os dados!
docker-compose down -v
docker volume prune -f
docker-compose up -d
```

### Container do Moodle reinicia constantemente

```bash
# Ver logs detalhados
docker-compose logs -f moodle

# Verificar se PostgreSQL está saudável
docker exec -it moodle_postgres pg_isready -U moodleuser
```

## 🎯 Workflow Recomendado

### Desenvolvimento
```bash
# 1. Subir stack
docker-compose up -d

# 2. Fazer alterações no código (diretório public/ está montado)
# Edite arquivos localmente

# 3. Limpar cache
docker exec -it moodle_app php admin/cli/purge_caches.php

# 4. Testar no navegador
# http://localhost:8080
```

### Testes
```bash
# Rodar testes PHPUnit
docker exec -it moodle_app vendor/bin/phpunit

# Rodar teste específico
docker exec -it moodle_app vendor/bin/phpunit public/admin/tool/log/store/tsdb/tests/
```

### Backup
```bash
# Backup do banco PostgreSQL
docker exec moodle_postgres pg_dump -U moodleuser moodle > backup_moodle_$(date +%Y%m%d).sql

# Backup do TimescaleDB
docker exec moodle_timescaledb pg_dump -U postgres moodle_logs_tsdb > backup_logs_$(date +%Y%m%d).sql
```

### Restore
```bash
# Restore PostgreSQL
cat backup_moodle_20251027.sql | docker exec -i moodle_postgres psql -U moodleuser -d moodle

# Restore TimescaleDB
cat backup_logs_20251027.sql | docker exec -i moodle_timescaledb psql -U postgres -d moodle_logs_tsdb
```

## 📈 Monitoramento

### Ver uso de recursos

```bash
# CPU e memória em tempo real
docker stats

# Apenas containers do projeto
docker stats moodle_app moodle_postgres moodle_timescaledb
```

### Logs estruturados

```bash
# Últimas 100 linhas
docker-compose logs --tail=100

# Seguir logs em tempo real
docker-compose logs -f

# Logs de um serviço específico
docker-compose logs -f moodle
```

## 🚀 Produção (Considerações)

**⚠️ Este setup é para DESENVOLVIMENTO!**

Para produção, considere:

- [ ] Usar variáveis de ambiente com secrets
- [ ] Configurar SSL/HTTPS (nginx reverse proxy)
- [ ] Ajustar limites de recursos (CPU, memória)
- [ ] Configurar backups automáticos
- [ ] Usar imagem otimizada (não código montado)
- [ ] Configurar health checks mais robustos
- [ ] Implementar logging centralizado
- [ ] Configurar monitoramento (Prometheus/Grafana)

## 📚 Referências

- [Docker Compose](https://docs.docker.com/compose/)
- [Moodle Docker](https://github.com/moodlehq/moodle-docker)
- [TimescaleDB Docker](https://docs.timescale.com/install/latest/installation-docker/)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)

---

**Criado para o TCC de análise de performance de logs em Moodle** 🎓
