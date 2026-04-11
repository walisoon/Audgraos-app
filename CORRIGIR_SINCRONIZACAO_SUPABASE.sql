-- CORRIGIR SINCRONIZAÇÃO DE EDIÇÕES
-- Script para corrigir problemas de sincronização no Supabase

-- 1. Atualizar laudos com resultado NULL para string vazia
UPDATE laudos 
SET resultado = ''
WHERE user_id = 'audgraos_admin' 
    AND resultado IS NULL;

-- 2. Verificar se há laudos com status inconsistente
-- Laudos com resultado preenchido devem ter status "Concluído"
UPDATE laudos 
SET status = 'Concluído'
WHERE user_id = 'audgraos_admin' 
    AND resultado IS NOT NULL 
    AND resultado != ''
    AND status != 'Concluído';

-- 3. Laudos sem resultado devem ter status "Em Andamento"
UPDATE laudos 
SET status = 'Em Andamento'
WHERE user_id = 'audgraos_admin' 
    AND (resultado IS NULL OR resultado = '')
    AND status != 'Em Andamento';

-- 4. Forçar atualização do timestamp para sincronização
UPDATE laudos 
SET updated_at = NOW()
WHERE user_id = 'audgraos_admin' 
    AND resultado IS NOT NULL 
    AND resultado != '';

-- 5. Verificar resultado
SELECT 
    id,
    numero_laudo,
    status,
    resultado,
    updated_at,
    CASE 
        WHEN resultado IS NOT NULL AND resultado != '' AND status = 'Concluído' THEN 'OK: Concluído com resultado'
        WHEN (resultado IS NULL OR resultado = '') AND status = 'Em Andamento' THEN 'OK: Em Andamento sem resultado'
        ELSE 'PROBLEMA: Status inconsistente'
    END as status_verificacao
FROM laudos 
WHERE user_id = 'audgraos_admin'
ORDER BY updated_at DESC;
