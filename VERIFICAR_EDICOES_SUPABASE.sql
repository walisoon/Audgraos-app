-- VERIFICAR EDIÇÕES NO SUPABASE
-- Script para verificar se as edições estão sendo salvas corretamente

-- 1. Verificar todos os laudos do usuário com seus resultados
SELECT 
    id,
    numero_laudo,
    status,
    resultado,
    updated_at,
    created_at
FROM laudos 
WHERE user_id = 'audgraos_admin'
ORDER BY updated_at DESC;

-- 2. Verificar se há laudos com resultado null (problema)
SELECT 
    id,
    numero_laudo,
    status,
    resultado,
    CASE 
        WHEN resultado IS NULL THEN 'PROBLEMA: Resultado é NULL'
        WHEN resultado = '' THEN 'PROBLEMA: Resultado está vazio'
        ELSE 'OK: Resultado preenchido'
    END as status_resultado,
    updated_at
FROM laudos 
WHERE user_id = 'audgraos_admin'
    AND (resultado IS NULL OR resultado = '')
ORDER BY updated_at DESC;

-- 3. Verificar últimos laudos atualizados
SELECT 
    id,
    numero_laudo,
    status,
    resultado,
    updated_at,
    created_at,
    EXTRACT(EPOCH FROM (updated_at - created_at)) as segundos_desde_criacao
FROM laudos 
WHERE user_id = 'audgraos_admin'
    AND updated_at > created_at
ORDER BY updated_at DESC
LIMIT 10;

-- 4. Contar laudos por status
SELECT 
    status,
    COUNT(*) as total,
    COUNT(CASE WHEN resultado IS NOT NULL AND resultado != '' THEN 1 END) as com_resultado,
    COUNT(CASE WHEN resultado IS NULL OR resultado = '' THEN 1 END) as sem_resultado
FROM laudos 
WHERE user_id = 'audgraos_admin'
GROUP BY status;
