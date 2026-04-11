-- Script para verificar todas as tabelas do banco
-- Execute este script primeiro para descobrir o nome correto da tabela

-- Listar todas as tabelas do esquema public
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Listar todas as tabelas (incluindo views)
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Procurar tabelas que possam ser relacionadas a "laudos"
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public'
AND (table_name ILIKE '%laudo%' OR table_name ILIKE '%audit%' OR table_name ILIKE '%relatorio%')
ORDER BY table_name;
