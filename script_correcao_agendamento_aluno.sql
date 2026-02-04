-- ============================================
-- Script para adicionar coluna id na tabela agendamento_aluno
-- Data: 2024-11-15
-- Problema: Tabela agendamento_aluno não possui coluna id
-- Erro: Multiple primary key defined (já existe chave primária)
-- ============================================

-- 1. Verificar estrutura atual da tabela
DESCRIBE agendamento_aluno;

-- 2. Verificar chave primária atual
SHOW INDEXES FROM agendamento_aluno WHERE Key_name = 'PRIMARY';

-- 3. REMOVER chave primária existente (necessário antes de adicionar nova)
ALTER TABLE agendamento_aluno DROP PRIMARY KEY;

-- 4. Adicionar coluna id como AUTO_INCREMENT
ALTER TABLE agendamento_aluno 
ADD COLUMN id BIGINT AUTO_INCREMENT FIRST;

-- 5. Definir id como chave primária
ALTER TABLE agendamento_aluno 
ADD PRIMARY KEY (id);

-- 6. Verificar estrutura final
DESCRIBE agendamento_aluno;

-- 7. Verificar dados (primeiros 10 registros)
SELECT * FROM agendamento_aluno LIMIT 10;

-- 8. Verificar se a coluna id foi populada corretamente
SELECT COUNT(*) as total_registros, 
       MIN(id) as menor_id, 
       MAX(id) as maior_id 
FROM agendamento_aluno;

