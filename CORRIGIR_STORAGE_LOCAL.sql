-- CORRIGIR STORAGE LOCAL - ATUALIZAR STATUS INCONSISTENTE
-- Execute este script no Supabase para corrigir os dados

-- Corrigir laudos com resultado NULL para status "Em Andamento"
UPDATE public.laudos 
SET status = 'Em Andamento'
WHERE user_id = 'audgraos_admin' 
    AND (resultado IS NULL OR resultado = '' OR resultado = 'null')
    AND status = 'Concluído';

-- Verificar resultado
SELECT 
    id,
    numero_laudo,
    status,
    resultado,
    CASE 
        WHEN resultado IS NULL OR resultado = '' OR resultado = 'null' THEN 'SEM RESULTADO'
        ELSE 'COM RESULTADO'
    END as tem_resultado,
    CASE 
        WHEN status = 'Em Andamento' AND (resultado IS NULL OR resultado = '' OR resultado = 'null') THEN 'CORRETO'
        WHEN status = 'Concluído' AND resultado IS NOT NULL AND resultado != '' AND resultado != 'null' THEN 'CORRETO'
        ELSE 'INCONSISTENTE'
    END as status_consistente
FROM public.laudos 
WHERE user_id = 'audgraos_admin'
ORDER BY id;
