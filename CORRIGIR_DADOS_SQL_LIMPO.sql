-- CORRIGIR DADOS ESPECIFICOS DA TABELA LAUDOS
-- Script baseado nos dados da imagem

-- 1. Corrigir laudos com status inconsistente
-- Laudos com resultado NULL devem ter status Em Andamento
UPDATE public.laudos 
SET status = 'Em Andamento'
WHERE user_id = 'audgraos_admin' 
    AND resultado IS NULL 
    AND status = 'Concluído';

-- 2. Verificar resultado da correcao
SELECT 
    id,
    numero_laudo,
    status,
    resultado,
    CASE 
        WHEN resultado IS NULL AND status = 'Em Andamento' THEN 'CORRIGIDO: Em Andamento sem resultado'
        WHEN resultado IS NOT NULL AND resultado != '' AND status = 'Concluído' THEN 'OK: Concluído com resultado'
        ELSE 'VERIFICAR: Status inconsistente'
    END as status_apos_correcao
FROM public.laudos 
WHERE user_id = 'audgraos_admin'
ORDER BY id;

-- 3. Contar laudos por status apos correcao
SELECT 
    status,
    COUNT(*) as total,
    COUNT(CASE WHEN resultado IS NOT NULL AND resultado != '' THEN 1 END) as com_resultado,
    COUNT(CASE WHEN resultado IS NULL OR resultado = '' THEN 1 END) as sem_resultado
FROM public.laudos 
WHERE user_id = 'audgraos_admin'
GROUP BY status;
