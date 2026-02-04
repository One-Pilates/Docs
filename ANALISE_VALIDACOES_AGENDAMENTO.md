# Análise das Validações de Agendamento

## Objetivo
Garantir que as mensagens de erro retornadas sejam corretas, específicas e informativas sobre o motivo exato da impossibilidade de agendamento.

---

## Problemas Identificados

### 🔴 **Problema 1: Ordem de Validação Ineficiente**

**Situação Atual:**
As validações são executadas nesta ordem:
1. Busca de entidades (sala, professor, especialidade, alunos)
2. Validação de conflitos básicos (sala, professor, alunos)
3. Validação de lotação da sala
4. Validação de equipamentos PCD
5. Validação de ausência do professor
6. Validação de status do aluno
7. Validação de status do professor
8. Validação de especialidade da sala
9. Validação de especialidade do professor

**Problema:**
- Validações "baratas" (status) são executadas depois de validações "caras" (conflitos, queries ao banco)
- Se um aluno está inativo, o sistema já executou várias queries desnecessárias
- Usuário recebe erro apenas do primeiro problema encontrado

**Impacto:**
- Performance degradada
- Experiência do usuário ruim (precisa corrigir um erro por vez)

---

### 🔴 **Problema 2: Mensagens de Erro Genéricas ou Pouco Informativas**

**Exemplos Identificados:**

1. **Conflito de Horário:**
   - ❌ Atual: "Professor indisponível para o horário agendado."
   - ✅ Ideal: "O professor João Silva já possui um agendamento em 15/12/2025 às 14:00."

2. **Conflito de Sala:**
   - ❌ Atual: "Sala indisponível para o horário agendado."
   - ✅ Ideal: "A sala Pilates 1 já está ocupada em 15/12/2025 às 14:00."

3. **Conflito de Alunos:**
   - ✅ Atual: "Alunos indisponíveis para o horário: Maria, João" (já está bom, mas poderia incluir horário)

4. **Especialidade Incompatível:**
   - ❌ Atual: "A professora Ana não atende a especialidade Pilates."
   - ✅ Ideal: "A professora Ana não atende a especialidade Pilates. Especialidades disponíveis: RPG, Fisioterapia."

---

### 🔴 **Problema 3: Validação Dupla Incompleta**

**Situação Atual:**
A validação dupla no `AgendamentoService.validarConflitosAntesDeSalvar()` valida apenas:
- Conflito de professor
- Conflito de sala

**Problema:**
- Não valida conflito de alunos na validação dupla
- Inconsistência: primeira validação verifica alunos, segunda não

---

### 🔴 **Problema 4: Falta de Validação de Data/Hora no Passado**

**Situação Atual:**
Não há validação para impedir agendamentos em datas/horas passadas.

**Problema:**
- Sistema permite criar agendamentos no passado
- Pode causar problemas de lógica de negócio

---

### 🔴 **Problema 5: Falta de Agregação de Múltiplos Erros**

**Situação Atual:**
Se houver múltiplos problemas (ex: aluno inativo + sala lotada), apenas o primeiro erro é retornado.

**Problema:**
- Usuário precisa corrigir um erro por vez
- Experiência do usuário ruim
- Processo de correção demorado

**Exemplo:**
```
Erro 1: "Aluno Maria está inativo"
Usuário corrige → tenta novamente
Erro 2: "Sala lotada"
Usuário corrige → tenta novamente
Erro 3: "Professor indisponível"
```

**Ideal:**
```
Erros encontrados:
1. Aluno Maria está inativo
2. A sala Pilates 1 suporta apenas 5 alunos, mas foram solicitados 7
3. O professor João já possui agendamento em 15/12/2025 às 14:00
```

---

### 🔴 **Problema 6: Mensagens de Erro Não Incluem Contexto Suficiente**

**Exemplos:**

1. **Sala Lotada:**
   - ❌ Atual: "A sala Pilates 1 suporta no máximo 5 alunos, mas foram solicitados 7."
   - ✅ Melhor: "A sala Pilates 1 suporta no máximo 5 alunos, mas foram solicitados 7 alunos. Remova 2 alunos ou escolha outra sala."

2. **Equipamento PCD:**
   - ❌ Atual: "A sala Pilates 1 possui apenas 2 equipamentos PCD, mas 3 alunos com limitações físicas foram agendados."
   - ✅ Melhor: "A sala Pilates 1 possui apenas 2 equipamentos PCD, mas 3 alunos com limitações físicas foram agendados (Maria, João, Ana). Remova 1 aluno com limitações ou escolha outra sala."

3. **Professor Ausente:**
   - ✅ Atual: "O professor João está ausente no horário agendado (15/12/2025 14:00)." (já está bom)

---

### 🔴 **Problema 7: Falta de Validação de Data/Hora Válida**

**Situação Atual:**
Não há validação para:
- Data/hora nula
- Data/hora muito no futuro (ex: mais de 1 ano)
- Horário fora do expediente (ex: 23:00, 06:00)

---

## Soluções Propostas

### ✅ **Solução 1: Reordenar Validações por Custo**

**Objetivo:** Executar validações mais baratas primeiro.

**Nova Ordem Sugerida:**
1. ✅ Validação de entidades existentes (já está no início)
2. ✅ Validação de status (aluno e professor) - **MOVER PARA CIMA**
3. ✅ Validação de especialidades (sala e professor) - **MOVER PARA CIMA**
4. ✅ Validação de data/hora (passado, futuro, expediente) - **NOVO**
5. ✅ Validação de lotação e equipamentos PCD
6. ✅ Validação de ausência do professor
7. ✅ Validação de conflitos (sala, professor, alunos) - **DEIXAR POR ÚLTIMO**

**Benefícios:**
- Erros baratos são detectados primeiro
- Menos queries desnecessárias
- Melhor performance

---

### ✅ **Solução 2: Melhorar Mensagens de Erro com Mais Contexto**

**Implementação:**

1. **Conflito de Horário - Professor:**
   ```java
   // Buscar o agendamento conflitante para incluir na mensagem
   Agendamento conflito = agendamentoRepository.findByProfessorIdAndDataHora(...);
   throw new ConflitoHorarioException(
       String.format("O professor %s já possui um agendamento em %s na sala %s.",
           professor.getNome(),
           dataHora.format(DateTimeFormatter.ofPattern("dd/MM/yyyy 'às' HH:mm")),
           conflito.getSala().getNome())
   );
   ```

2. **Conflito de Horário - Sala:**
   ```java
   Agendamento conflito = agendamentoRepository.findBySalaIdAndDataHora(...);
   throw new ConflitoHorarioException(
       String.format("A sala %s já está ocupada em %s pelo professor %s.",
           sala.getNome(),
           dataHora.format(DateTimeFormatter.ofPattern("dd/MM/yyyy 'às' HH:mm")),
           conflito.getProfessor().getNome())
   );
   ```

3. **Especialidade Incompatível - Professor:**
   ```java
   String especialidadesDisponiveis = professor.getEspecialidades().stream()
       .map(Especialidade::getNome)
       .collect(Collectors.joining(", "));
   throw new EspecialidadeIncompativelException(
       String.format("A professora %s não atende a especialidade %s. Especialidades disponíveis: %s.",
           professor.getNome(),
           especialidade.getNome(),
           especialidadesDisponiveis)
   );
   ```

4. **Sala Lotada:**
   ```java
   throw new SalaLotadaException(
       String.format("A sala %s suporta no máximo %d alunos, mas foram solicitados %d alunos. Remova %d aluno(s) ou escolha outra sala.",
           sala.getNome(),
           sala.getQuantidadeMaximaAlunos(),
           quantidadeAlunos,
           quantidadeAlunos - sala.getQuantidadeMaximaAlunos())
   );
   ```

5. **Equipamento PCD:**
   ```java
   String nomesAlunosPCD = alunos.stream()
       .filter(a -> Boolean.TRUE.equals(a.getAlunoComLimitacoesFisicas()))
       .map(Aluno::getNome)
       .collect(Collectors.joining(", "));
   throw new EquipamentoPCDInsuficienteException(
       String.format("A sala %s possui apenas %d equipamentos PCD, mas %d alunos com limitações físicas foram agendados (%s). Remova %d aluno(s) com limitações ou escolha outra sala.",
           sala.getNome(),
           sala.getQuantidadeEquipamentosPCD(),
           alunosComLimitacoes,
           nomesAlunosPCD,
           alunosComLimitacoes - sala.getQuantidadeEquipamentosPCD())
   );
   ```

---

### ✅ **Solução 3: Completar Validação Dupla com Alunos**

**Implementação:**
```java
private void validarConflitosAntesDeSalvar(AgendamentoDTO dto) {
    logger.debug("Validação dupla (double-check) de conflitos antes de salvar agendamento");
    
    // Validação de professor
    if (agendamentoRepository.existsByProfessorIdAndDataHora(dto.getProfessorId(), dto.getDataHora())) {
        throw new ConflitoHorarioException("Professor indisponível para o horário agendado.");
    }
    
    // Validação de sala
    if (agendamentoRepository.existsBySalaIdAndDataHora(dto.getSalaId(), dto.getDataHora())) {
        throw new ConflitoHorarioException("Sala indisponível para o horário agendado.");
    }
    
    // Validação de alunos (ADICIONAR)
    List<Aluno> alunos = alunoRepository.findAllById(dto.getAlunoIds());
    List<String> nomesIndisponiveis = alunos.stream()
        .filter(aluno -> !agendamentoRepository.findAgendamentosByAlunoAndDataHora(aluno, dto.getDataHora()).isEmpty())
        .map(Aluno::getNome)
        .toList();
    
    if (!nomesIndisponiveis.isEmpty()) {
        throw new ConflitoHorarioException("Alunos indisponíveis para o horário: " + String.join(", ", nomesIndisponiveis));
    }
    
    logger.debug("Validação dupla concluída sem conflitos");
}
```

---

### ✅ **Solução 4: Adicionar Validação de Data/Hora**

**Nova Validação:**
```java
private void validarDataHora(LocalDateTime dataHora) {
    LocalDateTime agora = LocalDateTime.now();
    
    // Validar se não é no passado
    if (dataHora.isBefore(agora)) {
        throw new OperacaoInvalidaException(
            String.format("Não é possível agendar em data/hora passada. Data/hora informada: %s",
                dataHora.format(DateTimeFormatter.ofPattern("dd/MM/yyyy 'às' HH:mm")))
        );
    }
    
    // Validar se não é muito no futuro (opcional - mais de 1 ano)
    LocalDateTime umAnoDepois = agora.plusYears(1);
    if (dataHora.isAfter(umAnoDepois)) {
        throw new OperacaoInvalidaException(
            "Não é possível agendar com mais de 1 ano de antecedência."
        );
    }
    
    // Validar horário de expediente (opcional - 8h às 20h)
    int hora = dataHora.getHour();
    if (hora < 8 || hora >= 20) {
        throw new OperacaoInvalidaException(
            String.format("O horário de agendamento deve estar entre 08:00 e 20:00. Horário informado: %02d:00",
                hora)
        );
    }
}
```

---

### ✅ **Solução 5: Agregação de Múltiplos Erros (Opcional - Complexo)**

**Implementação:**

Criar uma exceção especial para múltiplos erros:
```java
public class MultiplosErrosValidacaoException extends BusinessException {
    private final List<String> erros;
    
    public MultiplosErrosValidacaoException(List<String> erros) {
        super("Múltiplos erros de validação encontrados", "MULTIPLOS_ERROS");
        this.erros = erros;
    }
    
    public List<String> getErros() {
        return erros;
    }
}
```

Modificar o validator para coletar todos os erros:
```java
public void validar(AgendamentoDTO dto, Long agendamentoIdExcluir) {
    List<String> erros = new ArrayList<>();
    
    // Coletar erros ao invés de lançar imediatamente
    try {
        validarStatusAluno(alunos);
    } catch (AlunoInativoException e) {
        erros.add(e.getMessage());
    }
    
    try {
        validarStatusProfessor(professor);
    } catch (ProfessorInativoException e) {
        erros.add(e.getMessage());
    }
    
    // ... outras validações
    
    if (!erros.isEmpty()) {
        if (erros.size() == 1) {
            throw new BusinessException(erros.get(0));
        } else {
            throw new MultiplosErrosValidacaoException(erros);
        }
    }
}
```

**Nota:** Esta solução é mais complexa e pode não ser necessária se as outras melhorias forem implementadas.

---

### ✅ **Solução 6: Adicionar Métodos no Repository para Buscar Conflitos**

**Problema:** Atualmente só verificamos se existe conflito, mas não buscamos o agendamento conflitante para incluir na mensagem.

**Solução:** Adicionar métodos para buscar o agendamento conflitante:
```java
@Query("SELECT a FROM Agendamento a WHERE a.professor.id = :professorId AND a.dataHora = :dataHora")
Optional<Agendamento> findByProfessorIdAndDataHora(@Param("professorId") Long professorId,
                                                     @Param("dataHora") LocalDateTime dataHora);

@Query("SELECT a FROM Agendamento a WHERE a.sala.id = :salaId AND a.dataHora = :dataHora")
Optional<Agendamento> findBySalaIdAndDataHora(@Param("salaId") Long salaId,
                                               @Param("dataHora") LocalDateTime dataHora);
```

---

## Priorização das Soluções

### 🔴 **Alta Prioridade (Implementar Imediatamente):**
1. ✅ **Solução 1:** Reordenar validações por custo
2. ✅ **Solução 2:** Melhorar mensagens de erro com contexto
3. ✅ **Solução 3:** Completar validação dupla com alunos
4. ✅ **Solução 4:** Adicionar validação de data/hora

### 🟡 **Média Prioridade:**
5. ✅ **Solução 6:** Adicionar métodos no repository para buscar conflitos

### 🟢 **Baixa Prioridade (Opcional):**
6. ✅ **Solução 5:** Agregação de múltiplos erros (complexo, pode não ser necessário)

---

## Resumo das Melhorias

| Problema | Solução | Prioridade | Complexidade |
|----------|---------|------------|--------------|
| Ordem de validação ineficiente | Reordenar por custo | Alta | Baixa |
| Mensagens genéricas | Adicionar contexto | Alta | Média |
| Validação dupla incompleta | Incluir alunos | Alta | Baixa |
| Falta validação data/hora | Adicionar validação | Alta | Baixa |
| Falta métodos de busca | Adicionar no repository | Média | Baixa |
| Múltiplos erros | Agregação (opcional) | Baixa | Alta |

---

## Observações Finais

- As soluções de alta prioridade são simples de implementar e trazem grande melhoria na experiência do usuário
- A solução de agregação de múltiplos erros é mais complexa e pode não ser necessária se as outras melhorias forem implementadas
- Todas as soluções mantêm compatibilidade com o código existente
- As mensagens melhoradas facilitam a correção de erros pelo usuário

