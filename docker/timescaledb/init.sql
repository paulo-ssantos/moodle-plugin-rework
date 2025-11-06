-- ============================================================================
-- Script de Inicialização do TimescaleDB
-- ============================================================================
-- Este script é executado automaticamente quando o container sobe pela
-- primeira vez. Ele configura o banco de dados de logs com TimescaleDB.
-- ============================================================================

\echo '=========================================='
\echo 'Inicializando TimescaleDB para Moodle Logs'
\echo '=========================================='

-- Garantir que a extensão TimescaleDB está instalada
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

\echo '✓ Extensão TimescaleDB criada'

-- Criar schema se não existir
CREATE SCHEMA IF NOT EXISTS public;

-- ============================================================================
-- Criar tabela de eventos do Moodle
-- ============================================================================

CREATE TABLE IF NOT EXISTS moodle_events (
    time            TIMESTAMPTZ NOT NULL,
    event_name      VARCHAR(255) NOT NULL,
    component       VARCHAR(100),
    action          VARCHAR(50),
    target          VARCHAR(50),
    object_table    VARCHAR(50),
    object_id       BIGINT,
    crud            CHAR(1),
    edu_level       SMALLINT,
    context_id      BIGINT,
    context_level   SMALLINT,
    context_instance_id BIGINT,
    user_id         BIGINT,
    course_id       BIGINT,
    related_user_id BIGINT,
    anonymous       SMALLINT DEFAULT 0,
    ip              VARCHAR(45),
    realuser_id     BIGINT,
    origin          VARCHAR(10),
    other_data      JSONB
);

\echo '✓ Tabela moodle_events criada'

-- ============================================================================
-- Converter para hypertable (TimescaleDB)
-- ============================================================================

SELECT create_hypertable(
    'moodle_events',
    'time',
    if_not_exists => TRUE,
    chunk_time_interval => INTERVAL '1 day'
);

\echo '✓ Hypertable configurada (chunks de 1 dia)'

-- ============================================================================
-- Criar índices para performance
-- ============================================================================

-- Índice por usuário e tempo
CREATE INDEX IF NOT EXISTS idx_events_user_time
    ON moodle_events (user_id, time DESC);

-- Índice por curso e tempo
CREATE INDEX IF NOT EXISTS idx_events_course_time
    ON moodle_events (course_id, time DESC);

-- Índice por tipo de evento
CREATE INDEX IF NOT EXISTS idx_events_eventname
    ON moodle_events (event_name);

-- Índice por componente
CREATE INDEX IF NOT EXISTS idx_events_component
    ON moodle_events (component);

-- Índice por ação
CREATE INDEX IF NOT EXISTS idx_events_action
    ON moodle_events (action);

-- Índice composto para queries comuns
CREATE INDEX IF NOT EXISTS idx_events_component_action_time
    ON moodle_events (component, action, time DESC);

-- Índice GIN para JSONB (busca em other_data)
CREATE INDEX IF NOT EXISTS idx_events_other_data
    ON moodle_events USING GIN (other_data);

\echo '✓ Índices criados'

-- ============================================================================
-- Configurar política de compressão
-- ============================================================================

-- Comprimir dados com mais de 7 dias
ALTER TABLE moodle_events SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'event_name, component',
    timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('moodle_events', INTERVAL '7 days', if_not_exists => TRUE);

\echo '✓ Política de compressão configurada (7 dias)'

-- ============================================================================
-- Configurar política de retenção (opcional)
-- ============================================================================

-- Manter apenas últimos 365 dias (1 ano)
-- Descomente a linha abaixo se quiser ativar
-- SELECT add_retention_policy('moodle_events', INTERVAL '365 days', if_not_exists => TRUE);

-- \echo '✓ Política de retenção configurada (365 dias)'

-- ============================================================================
-- Criar view de estatísticas
-- ============================================================================

CREATE OR REPLACE VIEW events_stats AS
SELECT
    time_bucket('1 hour', time) AS hour,
    count(*) AS event_count,
    count(DISTINCT user_id) AS unique_users,
    count(DISTINCT course_id) AS unique_courses
FROM moodle_events
GROUP BY hour
ORDER BY hour DESC;

\echo '✓ View de estatísticas criada'

-- ============================================================================
-- Criar função auxiliar para busca de eventos
-- ============================================================================

CREATE OR REPLACE FUNCTION get_recent_events(
    p_limit INTEGER DEFAULT 100,
    p_user_id BIGINT DEFAULT NULL,
    p_course_id BIGINT DEFAULT NULL
)
RETURNS TABLE (
    time TIMESTAMPTZ,
    event_name VARCHAR,
    user_id BIGINT,
    course_id BIGINT,
    action VARCHAR,
    component VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.time,
        e.event_name,
        e.user_id,
        e.course_id,
        e.action,
        e.component
    FROM moodle_events e
    WHERE
        (p_user_id IS NULL OR e.user_id = p_user_id)
        AND (p_course_id IS NULL OR e.course_id = p_course_id)
    ORDER BY e.time DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

\echo '✓ Função get_recent_events() criada'

-- ============================================================================
-- Estatísticas iniciais
-- ============================================================================

\echo ''
\echo '=========================================='
\echo 'Configuração Concluída!'
\echo '=========================================='
\echo ''
\echo 'Informações do banco:'

SELECT
    hypertable_schema,
    hypertable_name,
    num_dimensions,
    num_chunks,
    compression_enabled
FROM timescaledb_information.hypertables
WHERE hypertable_name = 'moodle_events';

\echo ''
\echo 'Queries úteis:'
\echo '  SELECT * FROM events_stats LIMIT 10;'
\echo '  SELECT * FROM get_recent_events(50);'
\echo '  SELECT count(*) FROM moodle_events;'
\echo ''
\echo '=========================================='
