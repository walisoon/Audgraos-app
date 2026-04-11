-- SCRIPT FINAL PARA ADICIONAR user_id
-- Baseado no diagnóstico: tabela existe, coluna não existe

-- 1. Definir schema explicitamente
SET search_path TO public;

-- 2. Adicionar coluna user_id na tabela laudos
ALTER TABLE laudos ADD COLUMN user_id TEXT;

-- 3. Criar índice para performance
CREATE INDEX idx_laudos_user_id ON laudos(user_id);

-- 4. Verificar se funcionou
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'laudos' 
AND column_name = 'user_id' 
AND table_schema = 'public';

-- 5. Mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE '=== COLUNA user_id CRIADA COM SUCESSO! ===';
    RAISE NOTICE 'Tabela: laudos';
    RAISE NOTICE 'Schema: public';
    RAISE NOTICE 'Índice criado: idx_laudos_user_id';
    RAISE NOTICE 'Agora reinicie o aplicativo web!';
END $$;
