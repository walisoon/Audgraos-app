-- Script para adicionar coluna user_id na tabela laudos
-- Execute este script diretamente no painel SQL do Supabase

-- Verificar se a coluna já existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'laudos' 
        AND column_name = 'user_id'
    ) THEN
        -- Adicionar a coluna user_id
        ALTER TABLE laudos ADD COLUMN user_id TEXT;
        
        -- Criar índice para melhor performance
        CREATE INDEX idx_laudos_user_id ON laudos(user_id);
        
        RAISE NOTICE 'Coluna user_id adicionada com sucesso!';
    ELSE
        RAISE NOTICE 'Coluna user_id já existe!';
    END IF;
END $$;

-- Opcional: Atualizar laudos existentes com um user_id padrão
-- UPDATE laudos SET user_id = 'system_user' WHERE user_id IS NULL;

-- Verificar resultado
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'laudos' 
AND column_name = 'user_id';
