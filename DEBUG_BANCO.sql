-- Script de diagnóstico do banco
-- Execute este para entender o que está acontecendo

-- 1. Verificar schema atual
SELECT current_schema();

-- 2. Listar TODAS as tabelas de TODOS os schemas
SELECT table_schema, table_name, table_type
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;

-- 3. Verificar se estamos no schema correto
SELECT schemaname, tablename 
FROM pg_tables 
WHERE tablename ILIKE '%laudo%';

-- 4. Tentar acesso direto à tabela
SELECT COUNT(*) 
FROM information_schema.columns 
WHERE table_name = 'laudos';

-- 5. Verificar permissões
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name = 'laudos';
