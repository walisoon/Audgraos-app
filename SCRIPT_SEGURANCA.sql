-- Script mais seguro para adicionar coluna
-- Com verificações adicionais e tratamento de erros

-- 1. Verificar se estamos no schema public
SET search_path TO public;

-- 2. Verificar se a tabela existe antes de tentar alterar
DO $$
BEGIN
    -- Verificar se a tabela laudos existe
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'laudos'
        AND table_type = 'BASE TABLE'
    ) THEN
        -- Tabela existe, adicionar a coluna
        BEGIN
            -- Adicionar coluna se não existir
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = 'laudos' 
                AND column_name = 'user_id'
            ) THEN
                EXECUTE 'ALTER TABLE laudos ADD COLUMN user_id TEXT';
                RAISE NOTICE 'Coluna user_id adicionada à tabela laudos';
            ELSE
                RAISE NOTICE 'Coluna user_id já existe na tabela laudos';
            END IF;
            
            -- Criar índice se não existir
            IF NOT EXISTS (
                SELECT 1 FROM pg_indexes 
                WHERE tablename = 'laudos' 
                AND indexname = 'idx_laudos_user_id'
            ) THEN
                CREATE INDEX idx_laudos_user_id ON laudos(user_id);
                RAISE NOTICE 'Índice criado para laudos.user_id';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Erro ao processar tabela laudos: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Tabela laudos não encontrada no schema public';
    END IF;
    
    -- Fazer o mesmo para auditorias
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'auditorias'
        AND table_type = 'BASE TABLE'
    ) THEN
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = 'auditorias' 
                AND column_name = 'user_id'
            ) THEN
                EXECUTE 'ALTER TABLE auditorias ADD COLUMN user_id TEXT';
                RAISE NOTICE 'Coluna user_id adicionada à tabela auditorias';
            ELSE
                RAISE NOTICE 'Coluna user_id já existe na tabela auditorias';
            END IF;
            
            IF NOT EXISTS (
                SELECT 1 FROM pg_indexes 
                WHERE tablename = 'auditorias' 
                AND indexname = 'idx_auditorias_user_id'
            ) THEN
                CREATE INDEX idx_auditorias_user_id ON auditorias(user_id);
                RAISE NOTICE 'Índice criado para auditorias.user_id';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Erro ao processar tabela auditorias: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Tabela auditorias não encontrada no schema public';
    END IF;
END $$;

-- 3. Verificação final
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('laudos', 'auditorias') 
AND column_name = 'user_id'
AND table_schema = 'public';
