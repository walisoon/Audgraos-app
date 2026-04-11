-- VERIFICAR SE O CAMPO resultado EXISTE NA TABELA laudos
-- Execute este script no painel SQL do Supabase

-- 1. Verificar se a tabela existe
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'laudos';

-- 2. Listar todas as colunas da tabela laudos
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'laudos'
ORDER BY ordinal_position;

-- 3. Verificar especificamente se o campo resultado existe
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'laudos'
AND column_name = 'resultado';

-- 4. Verificar dados recentes para ver se resultado está sendo salvo
SELECT 
    id,
    numero_laudo,
    status,
    resultado,
    created_at,
    updated_at
FROM laudos 
WHERE user_id = 'audgraos_admin'
ORDER BY updated_at DESC 
LIMIT 5;

-- 5. Contar quantos laudos têm resultado preenchido
SELECT 
    COUNT(*) as total_laudos,
    COUNT(CASE WHEN resultado IS NOT NULL AND resultado != '' THEN 1 END) as com_resultado,
    COUNT(CASE WHEN resultado IS NULL OR resultado = '' THEN 1 END) as sem_resultado
FROM laudos 
WHERE user_id = 'audgraos_admin';

-- Mensagem informativa
DO $$
BEGIN
    RAISE NOTICE '=== VERIFICAÇÃO DO CAMPO resultado ===';
    RAISE NOTICE 'Execute todas as consultas acima para diagnosticar o problema';
    RAISE NOTICE 'Se o campo resultado não existir, precisamos adicioná-lo';
END $$;
