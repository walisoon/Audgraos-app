-- ADICIONAR CAMPO resultado NA TABELA laudos
-- Execute este script se o campo resultado não existir

-- 1. Adicionar coluna resultado
ALTER TABLE laudos ADD COLUMN resultado TEXT;

-- 2. Verificar se foi adicionada
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'laudos'
AND column_name = 'resultado';

-- 3. Mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE '=== COLUNA resultado ADICIONADA COM SUCESSO! ===';
    RAISE NOTICE 'Tabela: laudos';
    RAISE NOTICE 'Schema: public';
    RAISE NOTICE 'Agora o campo resultado será salvo corretamente';
END $$;
