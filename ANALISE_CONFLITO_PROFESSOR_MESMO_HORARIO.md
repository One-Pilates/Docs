# Análise: Conflito de Professor no Mesmo Horário

## Problema Reportado

O usuário conseguiu criar dois agendamentos para o **mesmo professor (Andrei)** no **mesmo dia e horário (1/12/2025 às 10h)**, mas em:
- **Sala 1** - Especialidade: RPG
- **Sala 2** - Especialidade: Pilates

Isso **não deveria ser permitido**, pois um professor não pode estar em dois lugares ao mesmo tempo.

## Análise do Código Atual

### 1. Validação no `AgendamentoValidator`

**Método:** `validarConflitosBasicos()`
**Linha:** 142

```java
if (agendamentoRepository.existsByProfessorIdAndDataHoraExcludingId(
    dto.getProfessorId(), dataHora, agendamentoIdExcluir)) {
    throw new ConflitoHorarioException(mensagem);
}
```

**Query no Repository (linha 147-150):**
```java
@Query("SELECT CASE WHEN COUNT(a) > 0 THEN true ELSE false END " +
       "FROM Agendamento a " +
       "WHERE a.professor.id = :professorId " +
       "AND a.dataHora = :dataHora " +
       "AND (:excludeId IS NULL OR a.id != :excludeId)")
boolean existsByProfessorIdAndDataHoraExcludingId(...)
```

### 2. Validação Dupla no `AgendamentoService`

**Método:** `validarConflitosAntesDeSalvar()`
**Linha:** 234

```java
if (agendamentoRepository.existsByProfessorIdAndDataHora(
    dto.getProfessorId(), dto.getDataHora())) {
    throw new ConflitoHorarioException("Professor indisponível...");
}
```

**Query no Repository (linha 133):**
```java
boolean existsByProfessorIdAndDataHora(Long professorId, LocalDateTime dataHora);
```

### 3. Fluxo de Criação

**Método:** `criarAgendamento()`
**Linha:** 64-99

```java
@Transactional
public Agendamento criarAgendamento(AgendamentoDTO dto) {
    // 1. Validação completa (inclui mapDtoToEntity que chama validator.validar)
    Agendamento agendamento = mapDtoToEntity(dto);
    
    // 2. Validação dupla (double-check)
    validarConflitosAntesDeSalvar(dto);
    
    // 3. Save no banco
    agendamento = agendamentoRepository.save(agendamento);
    ...
}
```

## Possíveis Causas do Problema

### 1. **Race Condition (Mais Provável)**

**Cenário:**
- Request 1: Cria agendamento Sala 1, 10h
  - Passa validação 1 (não encontra conflito)
  - Passa validação 2 (não encontra conflito)
  - **Ainda não salvou no banco**
  
- Request 2: Cria agendamento Sala 2, 10h (quase simultâneo)
  - Passa validação 1 (não encontra conflito - Request 1 ainda não salvou)
  - Passa validação 2 (não encontra conflito - Request 1 ainda não salvou)
  - Salva no banco
  
- Request 1: Salva no banco
  - **Ambos são salvos com sucesso!**

**Por que acontece:**
- A transação `@Transactional` usa isolamento padrão (`READ_COMMITTED`)
- Entre a validação e o `save()`, há uma janela de tempo onde outro request pode passar pela validação
- Mesmo com validação dupla, se ambos os requests estão na mesma janela, ambos passam

### 2. **Problema com Precisão de `LocalDateTime`**

**Cenário:**
- Se os agendamentos foram criados com milissegundos diferentes
- Exemplo:
  - Agendamento 1: `2025-12-01T10:00:00.123`
  - Agendamento 2: `2025-12-01T10:00:00.456`
- A comparação `a.dataHora = :dataHora` pode não detectar como conflito se a precisão for diferente

**Verificação necessária:**
- Como o `LocalDateTime` está sendo armazenado no banco?
- Qual a precisão (segundos, milissegundos, nanossegundos)?
- Os agendamentos estão sendo criados com a mesma precisão?

### 3. **Problema com Timezone**

**Cenário:**
- Se houver diferença de timezone entre a aplicação e o banco
- Ou se os agendamentos foram criados em momentos diferentes com timezone diferente
- A comparação pode falhar

### 4. **Problema com Isolamento de Transação**

**Cenário:**
- O isolamento `READ_COMMITTED` permite leituras não repetíveis
- Request 1 lê (não encontra conflito)
- Request 2 lê (não encontra conflito - Request 1 ainda não commitou)
- Request 1 salva
- Request 2 salva
- Ambos são commitados

## Soluções Propostas

### Solução 1: **Lock Pessimista (Recomendada)**

**Implementação:**
```java
@Transactional(isolation = Isolation.SERIALIZABLE)
public Agendamento criarAgendamento(AgendamentoDTO dto) {
    // Lock pessimista na validação
    agendamentoRepository.lockByProfessorIdAndDataHora(
        dto.getProfessorId(), dto.getDataHora());
    
    // Validação
    validarConflitosBasicos(dto);
    
    // Save
    return agendamentoRepository.save(agendamento);
}
```

**Repository:**
```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("SELECT a FROM Agendamento a " +
       "WHERE a.professor.id = :professorId " +
       "AND a.dataHora = :dataHora")
Optional<Agendamento> lockByProfessorIdAndDataHora(
    @Param("professorId") Long professorId,
    @Param("dataHora") LocalDateTime dataHora);
```

**Vantagens:**
- Previne race conditions completamente
- Garante que apenas um request pode validar/salvar por vez
- Mais seguro

**Desvantagens:**
- Pode causar deadlocks se não for bem implementado
- Pode reduzir performance em alta concorrência

### Solução 2: **Constraint Única no Banco de Dados**

**Implementação:**
```sql
ALTER TABLE agendamento 
ADD CONSTRAINT uk_professor_datahora 
UNIQUE (professor_id, data_hora);
```

**Vantagens:**
- Garantia no nível de banco de dados
- Impossível burlar
- Mais simples de implementar

**Desvantagens:**
- Erro genérico (precisa tratar `DataIntegrityViolationException`)
- Menos controle sobre mensagem de erro

### Solução 3: **Isolamento SERIALIZABLE**

**Implementação:**
```java
@Transactional(isolation = Isolation.SERIALIZABLE)
public Agendamento criarAgendamento(AgendamentoDTO dto) {
    // Mesmo código atual
}
```

**Vantagens:**
- Simples de implementar
- Previne race conditions

**Desvantagens:**
- Pode causar muitos deadlocks
- Performance muito ruim em alta concorrência
- Pode causar timeouts

### Solução 4: **Normalizar DataHora (Arredondar para Minutos)**

**Implementação:**
```java
private LocalDateTime normalizarDataHora(LocalDateTime dataHora) {
    return dataHora.withSecond(0).withNano(0);
}

// Na validação e no save
dto.setDataHora(normalizarDataHora(dto.getDataHora()));
```

**Vantagens:**
- Garante que agendamentos no mesmo minuto sejam considerados conflito
- Resolve problema de precisão

**Desvantagens:**
- Não resolve race condition
- Pode perder precisão se necessário

### Solução 5: **Combinação: Constraint + Lock + Normalização**

**Implementação:**
1. Adicionar constraint única no banco
2. Normalizar dataHora para minutos
3. Usar lock pessimista na validação
4. Manter validação dupla

**Vantagens:**
- Máxima segurança
- Múltiplas camadas de proteção

**Desvantagens:**
- Mais complexo
- Pode ser overkill

## Recomendação

**Solução Recomendada: Combinação de Solução 2 + Solução 4**

1. **Adicionar constraint única no banco de dados** (Solução 2)
   - Garantia no nível mais baixo
   - Impossível burlar

2. **Normalizar dataHora para minutos** (Solução 4)
   - Garante que agendamentos no mesmo minuto sejam considerados conflito
   - Resolve problema de precisão

3. **Manter validação dupla atual**
   - Para melhor experiência do usuário (erro antes de tentar salvar)
   - A constraint é o fallback de segurança

**Por que não usar Lock Pessimista:**
- Pode causar deadlocks
- Performance pode ser afetada
- A constraint única já resolve o problema de forma mais simples

## Próximos Passos

1. Verificar se há constraint única no banco de dados
2. Verificar precisão do `LocalDateTime` no banco
3. Verificar se há logs de criação simultânea
4. Implementar solução recomendada

