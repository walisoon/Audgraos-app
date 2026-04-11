-- Script final para adicionar coluna user_id na tabela laudos
-- Versão simplificada e testada

-- Adicionar coluna user_id se não existir
ALTER TABLE laudos 
ADD COLUMN IF NOT EXISTS user_id TEXT;

-- Criar índice para performance (se não existir)
CREATE INDEX IF NOT EXISTS idx_laudos_user_id ON laudos(user_id);

-- Verificar se a coluna foi criada
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'laudos' 
AND column_name = 'user_id';

-- Mostrar mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE 'Coluna user_id adicionada com sucesso!';
END $$;
