-- ============================================
-- Script CORRIGIDO para adicionar coluna id na tabela agendamento_aluno
-- Data: 2024-11-15
-- Problema: Tabela agendamento_aluno não possui coluna id
-- Erro encontrado: Multiple primary key defined
-- Solução: Remover chave primária existente antes de adicionar nova
-- ============================================

-- PASSO 1: Verificar estrutura atual da tabela
DESCRIBE agendamento_aluno;

-- PASSO 2: Verificar qual é a chave primária atual
SHOW INDEXES FROM agendamento_aluno WHERE Key_name = 'PRIMARY';

-- PASSO 3: REMOVER chave primária existente
-- (Isso é necessário porque não podemos ter duas chaves primárias)
ALTER TABLE agendamento_aluno DROP PRIMARY KEY;

-- PASSO 4: Adicionar coluna id como AUTO_INCREMENT (sem PRIMARY KEY ainda)
ALTER TABLE agendamento_aluno 
ADD COLUMN id BIGINT AUTO_INCREMENT FIRST;

-- PASSO 5: Definir id como chave primária
ALTER TABLE agendamento_aluno 
ADD PRIMARY KEY (id);

-- PASSO 6: Verificar estrutura final
DESCRIBE agendamento_aluno;

-- PASSO 7: Verificar dados
SELECT * FROM agendamento_aluno LIMIT 10;

-- PASSO 8: Verificar se a coluna id foi populada corretamente
SELECT COUNT(*) as total_registros, 
       MIN(id) as menor_id, 
       MAX(id) as maior_id 
FROM agendamento_aluno;

