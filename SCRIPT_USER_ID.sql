-- COLE E EXECUTE ESTE SCRIPT INTEIRO NO PAINEL SQL DO SUPABASE

-- 1. Adicionar coluna user_id na tabela laudos
ALTER TABLE laudos 
ADD COLUMN IF NOT EXISTS user_id TEXT;

-- 2. Criar índice para melhor performance
CREATE INDEX IF NOT EXISTS idx_laudos_user_id ON laudos(user_id);

-- 3. Adicionar coluna user_id na tabela auditorias (se necessário)
ALTER TABLE auditorias 
ADD COLUMN IF NOT EXISTS user_id TEXT;

-- 4. Criar índice para auditorias
CREATE INDEX IF NOT EXISTS idx_auditorias_user_id ON auditorias(user_id);

-- 5. Verificar se as colunas foram criadas
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('laudos', 'auditorias') 
AND column_name = 'user_id';

-- 6. Mostrar contagem de registros
SELECT 
    'laudos' as tabela,
    COUNT(*) as total_registros,
    COUNT(user_id) as registros_com_user_id
FROM laudos
UNION ALL
SELECT 
    'auditorias' as tabela,
    COUNT(*) as total_registros,
    COUNT(user_id) as registros_com_user_id
FROM auditorias;

-- 7. Mensagem de conclusão
DO $$
BEGIN
    RAISE NOTICE '=== SCRIPT CONCLUÍDO COM SUCESSO! ===';
    RAISE NOTICE 'Coluna user_id adicionada às tabelas laudos e auditorias';
    RAISE NOTICE 'Índices criados para performance';
    RAISE NOTICE 'Verifique os resultados acima';
END $$;
