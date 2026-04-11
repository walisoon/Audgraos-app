-- Script para adicionar coluna user_id (VERSÃO CORRIGIDA)
-- PRIMEIRO execute VERIFICAR_TABELAS.sql para descobrir o nome correto da tabela

-- Substitua "nome_correto_da_tabela" pelo nome real que encontrar
-- Possíveis nomes: laudos, laudo, audit, auditoria, relatorios, etc.

-- Exemplo (ajuste o nome da tabela após executar VERIFICAR_TABELAS.sql):
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'laudos' -- <<< SUBSTITUA PELO NOME CORRETO
        AND column_name = 'user_id'
    ) THEN
        -- Adicionar a coluna user_id
        ALTER TABLE laudos -- <<< SUBSTITUA PELO NOME CORRETO
        ADD COLUMN user_id TEXT;
        
        -- Criar índice para melhor performance
        CREATE INDEX idx_laudos_user_id ON laudos(user_id); -- <<< SUBSTITUA PELO NOME CORRETO
        
        RAISE NOTICE 'Coluna user_id adicionada com sucesso na tabela laudos!';
    ELSE
        RAISE NOTICE 'Coluna user_id já existe na tabela laudos!';
    END IF;
END $$;

-- Verificar resultado
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'laudos' -- <<< SUBSTITUA PELO NOME CORRETO
AND column_name = 'user_id';
