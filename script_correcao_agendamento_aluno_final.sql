-- ============================================
-- Script FINAL para adicionar coluna id na tabela agendamento_aluno
-- Data: 2024-11-15
-- Estrutura atual: Chave primária composta (agendamento_id, aluno_id)
-- Estrutura desejada: Coluna id como chave primária + índice único em (agendamento_id, aluno_id)
-- ============================================

-- PASSO 1: Verificar estrutura atual da tabela
DESCRIBE agendamento_aluno;

-- PASSO 2: Verificar chave primária atual (deve mostrar agendamento_id e aluno_id)
SHOW INDEXES FROM agendamento_aluno WHERE Key_name = 'PRIMARY';

-- PASSO 3: Verificar se há dados duplicados (não deveria ter, mas vamos verificar)
SELECT agendamento_id, aluno_id, COUNT(*) as quantidade
FROM agendamento_aluno
GROUP BY agendamento_id, aluno_id
HAVING COUNT(*) > 1;

-- PASSO 4: Adicionar coluna id como AUTO_INCREMENT (sem PRIMARY KEY ainda)
-- Isso vai criar a coluna e preencher automaticamente com valores sequenciais
ALTER TABLE agendamento_aluno 
ADD COLUMN id BIGINT AUTO_INCREMENT FIRST;

-- PASSO 5: Remover chave primária composta existente
ALTER TABLE agendamento_aluno DROP PRIMARY KEY;

-- PASSO 6: Definir id como chave primária
ALTER TABLE agendamento_aluno 
ADD PRIMARY KEY (id);

-- PASSO 7: Criar índice único em (agendamento_id, aluno_id) para evitar duplicatas
-- Isso garante que não podemos ter o mesmo aluno no mesmo agendamento duas vezes
ALTER TABLE agendamento_aluno 
ADD UNIQUE KEY uk_agendamento_aluno (agendamento_id, aluno_id);

-- PASSO 8: Verificar estrutura final
DESCRIBE agendamento_aluno;

-- PASSO 9: Verificar índices
SHOW INDEXES FROM agendamento_aluno;

-- PASSO 10: Verificar dados (primeiros 10 registros)
SELECT * FROM agendamento_aluno LIMIT 10;

-- PASSO 11: Verificar se a coluna id foi populada corretamente
SELECT COUNT(*) as total_registros, 
       MIN(id) as menor_id, 
       MAX(id) as maior_id 
FROM agendamento_aluno;

