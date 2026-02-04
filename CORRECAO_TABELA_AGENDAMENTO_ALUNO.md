# Correção: Tabela agendamento_aluno sem coluna id

## Problema Identificado

**Erro:**
```
Unknown column 'aa1_0.id' in 'field list'
```

**Causa:**
A entidade `AgendamentoAluno` tem um campo `id` com `@Id` e `@GeneratedValue`, mas a tabela `agendamento_aluno` no banco de dados não possui essa coluna.

**Estrutura Esperada pela Entidade:**
```java
@Entity
@Table(name = "agendamento_aluno")
public class AgendamentoAluno {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;  // ← Esta coluna não existe no banco
    
    @ManyToOne
    @JoinColumn(name = "agendamento_id", nullable = false)
    private Agendamento agendamento;
    
    @ManyToOne
    @JoinColumn(name = "aluno_id", nullable = false)
    private Aluno aluno;
    
    // ... outros campos
}
```

---

## Solução: Adicionar Coluna id na Tabela

### Opção 1: Script SQL Manual (RECOMENDADO - Preserva Dados)

**⚠️ IMPORTANTE:** Se a tabela já tiver uma chave primária, é necessário removê-la primeiro!

**Executar no MySQL:**

```sql
-- 1. Verificar estrutura atual da tabela
DESCRIBE agendamento_aluno;

-- 2. Verificar chave primária atual
SHOW INDEXES FROM agendamento_aluno WHERE Key_name = 'PRIMARY';

-- 3. REMOVER chave primária existente (necessário!)
ALTER TABLE agendamento_aluno DROP PRIMARY KEY;

-- 4. Adicionar coluna id como AUTO_INCREMENT
ALTER TABLE agendamento_aluno 
ADD COLUMN id BIGINT AUTO_INCREMENT FIRST;

-- 5. Definir id como chave primária
ALTER TABLE agendamento_aluno 
ADD PRIMARY KEY (id);

-- 6. Verificar se a coluna foi criada
DESCRIBE agendamento_aluno;
```

**Nota:** Se você receber o erro "Multiple primary key defined", significa que a tabela já possui uma chave primária. Nesse caso, siga os passos acima para remover a chave primária existente antes de adicionar a nova.

### Opção 2: Recriar Tabela (APAGA DADOS - Use com Cuidado)

**⚠️ ATENÇÃO: Isso apagará todos os dados da tabela!**

```sql
-- 1. Fazer backup dos dados (se necessário)
CREATE TABLE agendamento_aluno_backup AS SELECT * FROM agendamento_aluno;

-- 2. Dropar a tabela
DROP TABLE agendamento_aluno;

-- 3. Alterar ddl-auto temporariamente para criar
-- No application.properties:
-- spring.jpa.hibernate.ddl-auto=create

-- 4. Reiniciar aplicação (Hibernate criará a tabela corretamente)

-- 5. Restaurar dados do backup (se necessário)
-- INSERT INTO agendamento_aluno (agendamento_id, aluno_id, status_presenca, ...)
-- SELECT agendamento_id, aluno_id, status_presenca, ... FROM agendamento_aluno_backup;
```

### Opção 3: Usar Flyway/Liquibase (Recomendado para Produção)

Criar uma migration script:

```sql
-- V1__Add_id_column_to_agendamento_aluno.sql
ALTER TABLE agendamento_aluno 
ADD COLUMN id BIGINT AUTO_INCREMENT PRIMARY KEY FIRST;
```

---

## Script SQL Completo (Opção 1 - Recomendada) - VERSÃO FINAL

**Estrutura Atual da Tabela:**
- Chave primária composta: `(agendamento_id, aluno_id)`
- Não possui coluna `id`

**Estrutura Desejada:**
- Coluna `id` como chave primária (AUTO_INCREMENT)
- Índice único em `(agendamento_id, aluno_id)` para evitar duplicatas

```sql
-- ============================================
-- Script para adicionar coluna id na tabela agendamento_aluno
-- CORRIGIDO: Remove chave primária composta e adiciona coluna id
-- ============================================

-- 1. Verificar estrutura atual
DESCRIBE agendamento_aluno;

-- 2. Verificar chave primária atual (deve mostrar agendamento_id e aluno_id)
SHOW INDEXES FROM agendamento_aluno WHERE Key_name = 'PRIMARY';

-- 3. Adicionar coluna id como AUTO_INCREMENT (sem PRIMARY KEY ainda)
ALTER TABLE agendamento_aluno 
ADD COLUMN id BIGINT AUTO_INCREMENT FIRST;

-- 4. Remover chave primária composta existente
ALTER TABLE agendamento_aluno DROP PRIMARY KEY;

-- 5. Definir id como chave primária
ALTER TABLE agendamento_aluno 
ADD PRIMARY KEY (id);

-- 6. Criar índice único em (agendamento_id, aluno_id) para evitar duplicatas
ALTER TABLE agendamento_aluno 
ADD UNIQUE KEY uk_agendamento_aluno (agendamento_id, aluno_id);

-- 7. Verificar estrutura final
DESCRIBE agendamento_aluno;

-- 8. Verificar índices
SHOW INDEXES FROM agendamento_aluno;

-- 9. Verificar dados
SELECT * FROM agendamento_aluno LIMIT 10;
```

**⚠️ ATENÇÃO:** 
- Execute os comandos na ordem apresentada
- O passo 6 (índice único) é importante para evitar duplicatas de `(agendamento_id, aluno_id)`
- A coluna `id` será preenchida automaticamente com valores sequenciais (1, 2, 3, ...)

---

## Verificação Pós-Correção

Após executar o script, verificar:

1. **Estrutura da tabela:**
   ```sql
   DESCRIBE agendamento_aluno;
   ```
   
   **Resultado esperado:**
   ```
   +------------------------+--------------+------+-----+---------+----------------+
   | Field                  | Type         | Null | Key | Default | Extra          |
   +------------------------+--------------+------+-----+---------+----------------+
   | id                     | bigint       | NO   | PRI | NULL    | auto_increment |
   | agendamento_id         | bigint       | NO   | MUL | NULL    |                |
   | aluno_id               | bigint       | NO   | MUL | NULL    |                |
   | status_presenca        | varchar(255) | NO   |     | NULL    |                |
   | data_registro_presenca | datetime     | YES  |     | NULL    |                |
   | observacao             | varchar(255) | YES  |     | NULL    |                |
   +------------------------+--------------+------+-----+---------+----------------+
   ```

2. **Testar endpoint:**
   ```
   GET http://localhost:8080/api/agendamentos/professorId/10
   ```
   
   **Resultado esperado:** Status 200 com lista de agendamentos

---

## Estrutura Correta da Tabela

A tabela `agendamento_aluno` deve ter a seguinte estrutura:

```sql
CREATE TABLE agendamento_aluno (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    agendamento_id BIGINT NOT NULL,
    aluno_id BIGINT NOT NULL,
    status_presenca ENUM('PENDENTE','PRESENTE','FALTA') NOT NULL,
    data_registro_presenca DATETIME(6),
    observacao VARCHAR(255),
    UNIQUE KEY uk_agendamento_aluno (agendamento_id, aluno_id),
    FOREIGN KEY (agendamento_id) REFERENCES agendamento(id),
    FOREIGN KEY (aluno_id) REFERENCES aluno(id)
);
```

**Notas:**
- `id` é a chave primária (AUTO_INCREMENT)
- `uk_agendamento_aluno` é um índice único que garante que não podemos ter o mesmo aluno no mesmo agendamento duas vezes
- `status_presenca` é um ENUM (não VARCHAR)
- `data_registro_presenca` é DATETIME(6) para suportar microsegundos

---

## Notas Importantes

1. **Backup:** Sempre faça backup antes de alterar estrutura de tabelas em produção
2. **Downtime:** A alteração pode causar um breve downtime se houver muitos dados
3. **Índices:** Após adicionar a coluna, verificar se os índices estão corretos
4. **Foreign Keys:** Verificar se as foreign keys estão funcionando corretamente

---

## Próximos Passos

1. ✅ Executar script SQL para adicionar coluna `id`
2. ✅ Verificar estrutura da tabela
3. ✅ Testar endpoint novamente
4. ✅ Se funcionar, problema resolvido!

---

**Data:** 2024-11-15  
**Problema:** Tabela `agendamento_aluno` sem coluna `id`  
**Solução:** Adicionar coluna `id` via ALTER TABLE

