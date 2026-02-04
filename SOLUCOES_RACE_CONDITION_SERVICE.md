# Soluções para Race Condition em AgendamentoService

## Problema Identificado

É possível criar dois agendamentos com o mesmo professor no mesmo horário devido a **race condition** entre a validação e o save.

## Análise do Código Atual

### Fluxo Atual (Vulnerável):

```java
@Transactional
public Agendamento criarAgendamento(AgendamentoDTO dto) {
    // 1. Validação (dentro de mapDtoToEntity)
    Agendamento agendamento = mapDtoToEntity(dto);  // ← Valida aqui

    // 2. Save (janela de race condition aqui)
    agendamento = agendamentoRepository.save(agendamento);

    // 3. Notificações...
}
```

**Problema**: Entre a validação (linha 1) e o save (linha 2), outra thread pode passar pela validação e criar um agendamento duplicado.

---

## Soluções Propostas (Apenas no Service)

### ✅ **Solução 1: Validação Dupla (Double-Check) - RECOMENDADA**

**Conceito**: Validar novamente imediatamente antes do save, reduzindo a janela de race condition.

**Vantagens**:

- ✅ Implementação simples
- ✅ Reduz significativamente a chance de race condition
- ✅ Não requer mudanças no repositório
- ✅ Boa performance

**Desvantagens**:

- ⚠️ Não elimina 100% a possibilidade (mas reduz drasticamente)
- ⚠️ Requer duas queries de validação

**Implementação**:

```java
@Transactional
public Agendamento criarAgendamento(AgendamentoDTO dto) {
    logger.info("Tentativa de criar agendamento para data/hora: {}", dto.getDataHora());

    try {
        // Primeira validação (completa)
        Agendamento agendamento = mapDtoToEntity(dto);

        // Segunda validação (double-check) imediatamente antes do save
        validarConflitosAntesDeSalvar(dto);

        agendamento = agendamentoRepository.save(agendamento);

        // ... resto do código
    }
}

private void validarConflitosAntesDeSalvar(AgendamentoDTO dto) {
    // Validação rápida apenas de conflitos críticos
    if (agendamentoRepository.existsByProfessorIdAndDataHora(dto.getProfessorId(), dto.getDataHora())) {
        throw new ConflitoHorarioException("Professor indisponível para o horário agendado.");
    }

    if (agendamentoRepository.existsBySalaIdAndDataHora(dto.getSalaId(), dto.getDataHora())) {
        throw new ConflitoHorarioException("Sala indisponível para o horário agendado.");
    }
}
```

---

### ✅ **Solução 2: Aumentar Nível de Isolamento da Transação**

**Conceito**: Usar isolamento `SERIALIZABLE` para garantir que as transações sejam executadas de forma serial.

**Vantagens**:

- ✅ Elimina completamente race conditions
- ✅ Implementação simples (apenas anotação)

**Desvantagens**:

- ⚠️ **Impacto significativo na performance** (pode causar deadlocks)
- ⚠️ Pode reduzir throughput do sistema
- ⚠️ Não é recomendado para sistemas com alta concorrência

**Implementação**:

```java
@Transactional(isolation = Isolation.SERIALIZABLE)
public Agendamento criarAgendamento(AgendamentoDTO dto) {
    // ... código existente
}
```

**Nota**: Requer import:

```java
import org.springframework.transaction.annotation.Isolation;
```

---

### ✅ **Solução 3: Lock Pessimista na Validação (via EntityManager)**

**Conceito**: Usar `EntityManager` com lock pessimista para bloquear linhas durante a validação.

**Vantagens**:

- ✅ Previne race conditions efetivamente
- ✅ Boa performance (melhor que SERIALIZABLE)
- ✅ Implementação apenas no service

**Desvantagens**:

- ⚠️ Requer acesso ao `EntityManager`
- ⚠️ Pode causar deadlocks se não gerenciado corretamente
- ⚠️ Requer criar métodos adicionais no service

**Implementação**:

```java
@Autowired
private EntityManager entityManager;

@Transactional
public Agendamento criarAgendamento(AgendamentoDTO dto) {
    logger.info("Tentativa de criar agendamento para data/hora: {}", dto.getDataHora());

    try {
        // Buscar agendamentos existentes com lock pessimista
        List<Agendamento> conflitos = entityManager.createQuery(
            "SELECT a FROM Agendamento a WHERE a.professor.id = :professorId AND a.dataHora = :dataHora",
            Agendamento.class
        )
        .setParameter("professorId", dto.getProfessorId())
        .setParameter("dataHora", dto.getDataHora())
        .setLockMode(LockModeType.PESSIMISTIC_WRITE)
        .getResultList();

        if (!conflitos.isEmpty()) {
            throw new ConflitoHorarioException("Professor indisponível para o horário agendado.");
        }

        // Mesma validação para sala
        List<Agendamento> conflitosSala = entityManager.createQuery(
            "SELECT a FROM Agendamento a WHERE a.sala.id = :salaId AND a.dataHora = :dataHora",
            Agendamento.class
        )
        .setParameter("salaId", dto.getSalaId())
        .setParameter("dataHora", dto.getDataHora())
        .setLockMode(LockModeType.PESSIMISTIC_WRITE)
        .getResultList();

        if (!conflitosSala.isEmpty()) {
            throw new ConflitoHorarioException("Sala indisponível para o horário agendado.");
        }

        // Agora pode criar com segurança
        Agendamento agendamento = mapDtoToEntity(dto);
        agendamento = agendamentoRepository.save(agendamento);

        // ... resto do código
    }
}
```

**Nota**: Requer imports:

```java
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
```

---

### ✅ **Solução 4: Sincronização por Chave Composta (Lock em Memória)**

**Conceito**: Usar um `ConcurrentHashMap` com locks por chave (professor+dataHora) para sincronizar criação de agendamentos.

**Vantagens**:

- ✅ Previne race conditions completamente
- ✅ Performance boa (lock apenas por chave específica)
- ✅ Implementação apenas no service

**Desvantagens**:

- ⚠️ Lock em memória (não funciona em cluster/múltiplas instâncias)
- ⚠️ Requer gerenciamento de limpeza de locks
- ⚠️ Mais complexo de implementar

**Implementação**:

```java
private final ConcurrentHashMap<String, Object> locks = new ConcurrentHashMap<>();

@Transactional
public Agendamento criarAgendamento(AgendamentoDTO dto) {
    logger.info("Tentativa de criar agendamento para data/hora: {}", dto.getDataHora());

    // Criar chave única para o lock
    String lockKey = dto.getProfessorId() + "_" + dto.getDataHora().toString();

    // Obter ou criar lock para esta chave
    Object lock = locks.computeIfAbsent(lockKey, k -> new Object());

    synchronized (lock) {
        try {
            // Validação dentro do lock
            Agendamento agendamento = mapDtoToEntity(dto);
            agendamento = agendamentoRepository.save(agendamento);

            // ... resto do código

            return agendamento;
        } finally {
            // Limpar lock se não houver mais uso (opcional, para evitar memory leak)
            // locks.remove(lockKey); // Descomentar se necessário
        }
    }
}
```

**Nota**: Requer import:

```java
import java.util.concurrent.ConcurrentHashMap;
```

---

### ✅ **Solução 5: Combinação - Validação Dupla + Isolamento READ_COMMITTED**

**Conceito**: Combinar validação dupla com isolamento `READ_COMMITTED` (padrão) para máxima segurança.

**Vantagens**:

- ✅ Combina benefícios de múltiplas abordagens
- ✅ Boa performance
- ✅ Alta confiabilidade

**Desvantagens**:

- ⚠️ Implementação um pouco mais complexa

**Implementação**:

```java
@Transactional(isolation = Isolation.READ_COMMITTED)
public Agendamento criarAgendamento(AgendamentoDTO dto) {
    logger.info("Tentativa de criar agendamento para data/hora: {}", dto.getDataHora());

    try {
        // Primeira validação (completa)
        Agendamento agendamento = mapDtoToEntity(dto);

        // Segunda validação (double-check) imediatamente antes do save
        validarConflitosAntesDeSalvar(dto);

        agendamento = agendamentoRepository.save(agendamento);

        // ... resto do código
    }
}

private void validarConflitosAntesDeSalvar(AgendamentoDTO dto) {
    if (agendamentoRepository.existsByProfessorIdAndDataHora(dto.getProfessorId(), dto.getDataHora())) {
        throw new ConflitoHorarioException("Professor indisponível para o horário agendado.");
    }

    if (agendamentoRepository.existsBySalaIdAndDataHora(dto.getSalaId(), dto.getDataHora())) {
        throw new ConflitoHorarioException("Sala indisponível para o horário agendado.");
    }
}
```

---

## Comparação das Soluções

| Solução                | Eficácia   | Performance | Complexidade | Recomendação               |
| ---------------------- | ---------- | ----------- | ------------ | -------------------------- |
| **1. Validação Dupla** | ⭐⭐⭐⭐   | ⭐⭐⭐⭐⭐  | ⭐⭐⭐⭐⭐   | ✅ **RECOMENDADA**         |
| **2. SERIALIZABLE**    | ⭐⭐⭐⭐⭐ | ⭐⭐        | ⭐⭐⭐⭐⭐   | ⚠️ Não recomendado         |
| **3. Lock Pessimista** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐    | ⭐⭐⭐       | ✅ Boa opção               |
| **4. Lock em Memória** | ⭐⭐⭐⭐   | ⭐⭐⭐⭐    | ⭐⭐         | ⚠️ Não funciona em cluster |
| **5. Combinação**      | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐    | ⭐⭐⭐       | ✅ **MELHOR OPÇÃO**        |

---

## Recomendação Final

**Implementar Solução 5 (Combinação)**:

1. Validação dupla (double-check)
2. Isolamento READ_COMMITTED (já é padrão, mas explícito)
3. Validação rápida antes do save

Esta solução oferece:

- ✅ Alta confiabilidade
- ✅ Boa performance
- ✅ Implementação simples
- ✅ Funciona em qualquer ambiente (single instance ou cluster)

---

## Observação Importante

⚠️ **Nenhuma solução apenas no service elimina 100% a possibilidade de race condition sem constraints no banco de dados.**

Para garantir 100% de segurança, recomenda-se também:

- Adicionar constraint `UNIQUE(professor_id, data_hora)` no banco de dados
- Adicionar constraint `UNIQUE(sala_id, data_hora)` no banco de dados

Mas as soluções acima reduzem drasticamente a probabilidade de ocorrência.
