-- PRIMEIRO SCRIPT: CRIAR TABELA LAUDOS
-- Execute este ANTES dos outros scripts

-- Criar tabela laudos
CREATE TABLE IF NOT EXISTS public.laudos (
    id BIGINT PRIMARY KEY,
    numero_laudo VARCHAR(50) UNIQUE NOT NULL,
    servico VARCHAR(100),
    data DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'Em Andamento',
    user_id VARCHAR(100),
    
    -- Campos de endereco/transporte
    origem VARCHAR(200),
    destino VARCHAR(200),
    nota_fiscal VARCHAR(100),
    produto VARCHAR(200),
    cliente VARCHAR(200),
    placa VARCHAR(50),
    certificadora VARCHAR(200),
    peso VARCHAR(100),
    transportadora VARCHAR(200),
    nome_classificador VARCHAR(200),
    terminal_recusa VARCHAR(200),
    
    -- Campos de analise
    tipo VARCHAR(100),
    resultado TEXT,
    odor VARCHAR(10),
    sementes VARCHAR(10),
    observacoes TEXT,
    
    -- Campos adicionais para analise
    umidade DECIMAL(5,2),
    materias_estranhas DECIMAL(5,2),
    queimados DECIMAL(5,2),
    ardidos DECIMAL(5,2),
    mofados DECIMAL(5,2),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar indices
CREATE INDEX IF NOT EXISTS idx_laudos_user_id ON laudos(user_id);
CREATE INDEX IF NOT EXISTS idx_laudos_status ON laudos(status);

-- Habilitar RLS
ALTER TABLE laudos ENABLE ROW LEVEL SECURITY;

-- Criar politicas RLS
CREATE POLICY "Users can view their own laudos" ON laudos
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own laudos" ON laudos
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own laudos" ON laudos
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete their own laudos" ON laudos
    FOR DELETE USING (auth.uid()::text = user_id);

-- Verificar criacao
SELECT 'Tabela laudos criada com sucesso!' as status;
