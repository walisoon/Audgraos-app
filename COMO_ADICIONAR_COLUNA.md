# Como Adicionar a Coluna user_id no Supabase

## Opção 1: Via Painel do Supabase (Recomendado)

1. **Acesse o painel do Supabase**: https://supabase.com/dashboard
2. **Selecione seu projeto**: oowbeehssifgizhgxgpc
3. **Vá para "SQL Editor"** no menu lateral
4. **Clique em "New query"**
5. **Copie e cole o conteúdo do arquivo `CRIAR_COLUNA_USER_ID.sql`**
6. **Clique em "Run"** para executar

## Opção 2: Via Linha de Comando (se tiver CLI)

```bash
# Instalar CLI do Supabase
npm install -g supabase

# Fazer login
supabase login

# Conectar ao projeto
supabase link --project-ref oowbeehssifgizhgxgpc

# Executar o script
supabase db push --file CRIAR_COLUNA_USER_ID.sql
```

## Opção 3: Via API (automático no app)

O aplicativo já tentará criar a coluna automaticamente, mas o método manual é mais confiável.

## Verificação

Após executar, você pode verificar se a coluna foi criada:

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'laudos' 
AND column_name = 'user_id';
```

## O que acontece após criar a coluna?

1. **Separação real por usuário**: Cada usuário só verá seus próprios laudos
2. **Filtragem no banco**: Mais eficiente que filtragem local
3. **Sincronização melhor**: Dados já virão filtrados do Supabase
4. **Backup automático**: Dados separados por usuário no banco

## Benefícios

- **Segurança**: Usuários não veem laudos de outros
- **Performance**: Queries mais rápidas com índice
- **Escalabilidade**: Suporta múltiplos usuários
- **Organização**: Dados bem estruturados

## Se encontrar problemas

- **Permissão negada**: Verifique se você tem permissão de admin no projeto
- **Tabela não existe**: Verifique se o nome da tabela está correto ("laudos")
- **Coluna já existe**: O script já trata este caso automaticamente
