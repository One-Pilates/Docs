# Diagnóstico: 400 Bad Request - Erro ao buscar agendamentos por professor

## Data do Diagnóstico
2024-11-15

## Erro Reportado
```
GET http://localhost:8080/api/agendamentos/professorId/10 400 (Bad Request)
```

**Status:** ✅ Backend está rodando e respondendo  
**Status:** ✅ CORS está funcionando (requisição chegou ao backend)  
**Status:** ✅ Autenticação provavelmente está funcionando (não é 401)  
**Status:** ❌ Erro 400 (Bad Request) - Problema na requisição ou processamento

---

## 🔴 PROBLEMA IDENTIFICADO (CAUSA REAL)

**Erro no Log do Backend:**
```
SQL Error: 1054, SQLState: 42S22
Unknown column 'aa1_0.id' in 'field list'
```

**Causa Raiz:**
A tabela `agendamento_aluno` no banco de dados **não possui a coluna `id`**, mas a entidade JPA `AgendamentoAluno` espera essa coluna.

**Solução:**
Executar script SQL para adicionar a coluna `id` na tabela. Ver arquivo:
- `documentacao/script_correcao_agendamento_aluno.sql`
- `documentacao/CORRECAO_TABELA_AGENDAMENTO_ALUNO.md`

---

## 🔴 PROBLEMA PRINCIPAL: Erro 400 Bad Request

### O que significa 400 Bad Request?

O erro `400 Bad Request` indica que o servidor **não conseguiu processar a requisição** devido a:
1. **Parâmetro inválido** na URL
2. **Exceção durante o processamento** (NullPointerException, IllegalArgumentException, etc.)
3. **Problema de validação** de dados
4. **Problema de conversão de tipos**

---

## 1. Análise do Endpoint

### 1.1 Endpoint Solicitado

**Frontend:**
```javascript
GET /api/agendamentos/professorId/10
```

**Backend (`AgendamentoController.java` linha 90-94):**
```java
@GetMapping("/professorId/{id}")
@PreAuthorize("hasAnyAuthority('ADMINISTRADOR', 'SECRETARIA', 'PROFESSOR')")
public ResponseEntity<List<AgendamentoResponseDTO>> listarPorProfessorId(@PathVariable Long id) {
   return ResponseEntity.ok(agendamentoService.buscarAgendamentosPorIdProfessor(id));
}
```

**✅ Endpoint está correto**

### 1.2 Fluxo de Processamento

1. **Controller recebe:** `id = 10` (Long)
2. **Service chama:** `buscarAgendamentosPorIdProfessor(10)`
3. **Repository busca:** `findByProfessorId(10)`
4. **Service converte:** `agendamentos.stream().map(this::toResponseDTO)`
5. **Retorna:** `List<AgendamentoResponseDTO>`

**❓ Onde pode estar falhando?**

---

## 2. Possíveis Causas do Erro 400

### 🔴 CAUSA #1: NullPointerException no método `toResponseDTO`

**Localização:** `AgendamentoService.java` linha 328-352

**Código:**
```java
public AgendamentoResponseDTO toResponseDTO(Agendamento agendamento) {
    AgendamentoResponseDTO dto = new AgendamentoResponseDTO();
    dto.setId(agendamento.getId());
    dto.setDataHora(agendamento.getDataHora());
    dto.setProfessor(agendamento.getProfessor().getNome());  // ⚠️ Pode ser null
    dto.setSala(agendamento.getSala().getNome());          // ⚠️ Pode ser null
    dto.setEspecialidade(agendamento.getEspecialidade().getNome()); // ⚠️ Pode ser null

    Set<AlunoAgendamentoResponseDTO> alunosDTO = agendamento.getAgendamentoAlunos()
            .stream()
            .map(aa -> {
                AlunoAgendamentoResponseDTO alunoDTO = new AlunoAgendamentoResponseDTO();
                alunoDTO.setId(aa.getAluno().getId());        // ⚠️ Pode ser null
                alunoDTO.setNome(aa.getAluno().getNome());    // ⚠️ Pode ser null
                // ...
            })
            .collect(Collectors.toSet());
    // ...
}
```

**Problemas Potenciais:**
- `agendamento.getProfessor()` pode ser `null` → `NullPointerException`
- `agendamento.getSala()` pode ser `null` → `NullPointerException`
- `agendamento.getEspecialidade()` pode ser `null` → `NullPointerException`
- `agendamento.getAgendamentoAlunos()` pode ser `null` → `NullPointerException`
- `aa.getAluno()` pode ser `null` → `NullPointerException`

**Solução:**
- Adicionar validações null-safe
- Verificar se `@EntityGraph` está carregando todas as relações corretamente

---

### 🔴 CAUSA #2: Problema com `@EntityGraph` no Repository

**Localização:** `AgendamentoRepository.java` linha 49-50

**Código:**
```java
@EntityGraph(attributePaths = {"agendamentoAlunos", "agendamentoAlunos.aluno", "professor", "sala", "especialidade"})
List<Agendamento> findByProfessorId(Long professorId);
```

**Problemas Potenciais:**
- `@EntityGraph` pode não estar carregando todas as relações
- Alguma relação pode estar `null` no banco de dados
- Lazy loading pode estar sendo acionado mesmo com `@EntityGraph`

**Solução:**
- Verificar se todas as relações estão sendo carregadas
- Adicionar logs para verificar o que está sendo retornado

---

### 🔴 CAUSA #3: Problema de Conversão de Tipo

**Localização:** `AgendamentoController.java` linha 92

**Código:**
```java
@GetMapping("/professorId/{id}")
public ResponseEntity<List<AgendamentoResponseDTO>> listarPorProfessorId(@PathVariable Long id) {
```

**Problemas Potenciais:**
- Se o parâmetro `id` não puder ser convertido para `Long`, Spring retorna 400
- Mas o valor `10` é válido, então provavelmente não é isso

**Solução:**
- Verificar se há alguma validação customizada no parâmetro

---

### 🟡 CAUSA #4: Exceção no Handler de Exceções

**Localização:** `GlobalExceptionHandler.java` linha 51-55

**Código:**
```java
@ExceptionHandler(RuntimeException.class)
public ResponseEntity<String> handleRuntime(RuntimeException ex) {
    String msg = ex.getMessage() == null ? "Erro" : ex.getMessage();
    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(msg);
}
```

**Problema:**
- Qualquer `RuntimeException` (incluindo `NullPointerException`) retorna 400
- A mensagem de erro pode não estar sendo enviada corretamente

**Solução:**
- Verificar logs do backend para ver a exceção exata
- Melhorar tratamento de exceções para retornar mais informações

---

## 3. Verificações Necessárias

### 3.1 Verificar Logs do Backend

**No console do backend, procurar por:**
```
Buscando agendamentos para professor ID: 10
Encontrados X agendamentos para professor ID: 10
```

**Se aparecer erro:**
```
java.lang.NullPointerException
    at com.onePilates.agendamento.service.AgendamentoService.toResponseDTO(...)
```

**Isso confirma a CAUSA #1**

### 3.2 Verificar Resposta HTTP no Navegador

**No DevTools → Network:**
1. Clicar na requisição que falhou
2. Ver aba **Response** ou **Preview**
3. Verificar a mensagem de erro retornada

**Exemplos de respostas possíveis:**
- `"null"` → NullPointerException
- `"Erro"` → RuntimeException genérica
- `{"erro": "..."}` → BusinessException

### 3.3 Verificar Dados no Banco

**Verificar se o professor ID 10 existe:**
```sql
SELECT * FROM funcionario WHERE id = 10;
```

**Verificar se há agendamentos para o professor:**
```sql
SELECT * FROM agendamento WHERE professor_id = 10;
```

**Verificar se as relações estão corretas:**
```sql
SELECT 
    a.id,
    a.professor_id,
    a.sala_id,
    a.especialidade_id,
    p.nome AS professor_nome,
    s.nome AS sala_nome,
    e.nome AS especialidade_nome
FROM agendamento a
LEFT JOIN funcionario p ON a.professor_id = p.id
LEFT JOIN sala s ON a.sala_id = s.id
LEFT JOIN especialidade e ON a.especialidade_id = e.id
WHERE a.professor_id = 10;
```

---

## 4. Soluções Propostas

### Solução 1: Adicionar Validações Null-Safe no `toResponseDTO`

**Arquivo:** `backend/agendamento/src/main/java/com/onePilates/agendamento/service/AgendamentoService.java`

**Código Atual:**
```java
public AgendamentoResponseDTO toResponseDTO(Agendamento agendamento) {
    AgendamentoResponseDTO dto = new AgendamentoResponseDTO();
    dto.setId(agendamento.getId());
    dto.setDataHora(agendamento.getDataHora());
    dto.setProfessor(agendamento.getProfessor().getNome());  // ⚠️ Pode ser null
    // ...
}
```

**Código Proposto:**
```java
public AgendamentoResponseDTO toResponseDTO(Agendamento agendamento) {
    if (agendamento == null) {
        logger.warn("Tentativa de converter agendamento null para DTO");
        return null;
    }
    
    AgendamentoResponseDTO dto = new AgendamentoResponseDTO();
    dto.setId(agendamento.getId());
    dto.setDataHora(agendamento.getDataHora());
    
    // Validações null-safe
    if (agendamento.getProfessor() != null) {
        dto.setProfessor(agendamento.getProfessor().getNome());
    } else {
        logger.warn("Agendamento ID {} tem professor null", agendamento.getId());
        dto.setProfessor("Professor não encontrado");
    }
    
    if (agendamento.getSala() != null) {
        dto.setSala(agendamento.getSala().getNome());
    } else {
        logger.warn("Agendamento ID {} tem sala null", agendamento.getId());
        dto.setSala("Sala não encontrada");
    }
    
    if (agendamento.getEspecialidade() != null) {
        dto.setEspecialidade(agendamento.getEspecialidade().getNome());
    } else {
        logger.warn("Agendamento ID {} tem especialidade null", agendamento.getId());
        dto.setEspecialidade("Especialidade não encontrada");
    }
    
    // Tratar agendamentoAlunos
    if (agendamento.getAgendamentoAlunos() != null) {
        Set<AlunoAgendamentoResponseDTO> alunosDTO = agendamento.getAgendamentoAlunos()
                .stream()
                .filter(aa -> aa != null && aa.getAluno() != null)  // Filtrar nulls
                .map(aa -> {
                    AlunoAgendamentoResponseDTO alunoDTO = new AlunoAgendamentoResponseDTO();
                    alunoDTO.setId(aa.getAluno().getId());
                    alunoDTO.setNome(aa.getAluno().getNome());
                    alunoDTO.setObservacao(aa.getAluno().getObservacao());
                    alunoDTO.setStatus(aa.getAluno().getStatus());
                    return alunoDTO;
                })
                .collect(Collectors.toSet());
        dto.setAlunos(alunosDTO);
    } else {
        logger.warn("Agendamento ID {} tem agendamentoAlunos null", agendamento.getId());
        dto.setAlunos(Collections.emptySet());
    }
    
    return dto;
}
```

---

### Solução 2: Melhorar Tratamento de Exceções

**Arquivo:** `backend/agendamento/src/main/java/com/onePilates/agendamento/handler/GlobalExceptionHandler.java`

**Adicionar handler específico para NullPointerException:**
```java
@ExceptionHandler(NullPointerException.class)
public ResponseEntity<Map<String, String>> handleNullPointer(NullPointerException ex) {
    logger.error("NullPointerException capturada", ex);
    Map<String, String> erro = new HashMap<>();
    erro.put("erro", "Erro ao processar dados. Algum campo obrigatório está ausente.");
    erro.put("detalhes", ex.getMessage() != null ? ex.getMessage() : "NullPointerException");
    return new ResponseEntity<>(erro, HttpStatus.BAD_REQUEST);
}
```

---

### Solução 3: Adicionar Logs de Debug

**Arquivo:** `backend/agendamento/src/main/java/com/onePilates/agendamento/service/AgendamentoService.java`

**No método `buscarAgendamentosPorIdProfessor`:**
```java
public List<AgendamentoResponseDTO> buscarAgendamentosPorIdProfessor(Long id) {
    logger.debug("Buscando agendamentos para professor ID: {}", id);
    
    try {
        List<Agendamento> agendamentos = agendamentoRepository.findByProfessorId(id);
        logger.debug("Encontrados {} agendamentos para professor ID: {}", agendamentos.size(), id);
        
        // Log detalhado para debug
        for (Agendamento ag : agendamentos) {
            logger.debug("Agendamento ID: {}, Professor: {}, Sala: {}, Especialidade: {}", 
                ag.getId(),
                ag.getProfessor() != null ? ag.getProfessor().getNome() : "NULL",
                ag.getSala() != null ? ag.getSala().getNome() : "NULL",
                ag.getEspecialidade() != null ? ag.getEspecialidade().getNome() : "NULL"
            );
        }
        
        return agendamentos.stream()
                .map(this::toResponseDTO)
                .collect(Collectors.toList());
    } catch (Exception e) {
        logger.error("Erro ao buscar agendamentos para professor ID: {}", id, e);
        throw e;
    }
}
```

---

## 5. Checklist de Diagnóstico

### 5.1 Verificações no Backend

- [ ] **Verificar logs do Spring Boot:**
  - Aparece "Buscando agendamentos para professor ID: 10"?
  - Aparece algum erro ou exceção?
  
- [ ] **Verificar resposta HTTP:**
  - Qual é a mensagem de erro retornada?
  - É um JSON ou uma string?
  
- [ ] **Verificar dados no banco:**
  - Professor ID 10 existe?
  - Há agendamentos para o professor?
  - As relações (professor, sala, especialidade) estão corretas?

### 5.2 Verificações no Frontend

- [ ] **Verificar no DevTools → Network:**
  - Qual é o status code? (deve ser 400)
  - Qual é a resposta retornada?
  - Qual é a mensagem de erro?

---

## 6. Testes de Verificação

### Teste 1: Verificar Endpoint Diretamente

**No navegador ou Postman:**
```
GET http://localhost:8080/api/agendamentos/professorId/10
Headers:
  Authorization: Bearer <token>
```

**Resultado esperado:**
- Se funcionar: Lista de agendamentos (JSON)
- Se falhar: Ver mensagem de erro retornada

### Teste 2: Verificar Logs do Backend

**No console do backend, procurar por:**
```
Buscando agendamentos para professor ID: 10
```

**Se aparecer erro:**
- Copiar stack trace completo
- Identificar a linha exata do erro

### Teste 3: Verificar Dados no Banco

**Executar query SQL:**
```sql
SELECT 
    a.id AS agendamento_id,
    a.professor_id,
    p.nome AS professor_nome,
    a.sala_id,
    s.nome AS sala_nome,
    a.especialidade_id,
    e.nome AS especialidade_nome
FROM agendamento a
LEFT JOIN funcionario p ON a.professor_id = p.id
LEFT JOIN sala s ON a.sala_id = s.id
LEFT JOIN especialidade e ON a.especialidade_id = e.id
WHERE a.professor_id = 10;
```

**Verificar:**
- Há agendamentos retornados?
- Algum campo está NULL?
- As relações estão corretas?

---

## 7. Resumo Executivo

### Problema Mais Provável
**NullPointerException no método `toResponseDTO`** (80% de probabilidade)

### Causa Provável
- Alguma relação (professor, sala, especialidade, ou aluno) está `null` no agendamento
- O `@EntityGraph` pode não estar carregando todas as relações corretamente
- Ou há dados inconsistentes no banco de dados

### Ação Imediata Recomendada

1. ✅ **Verificar logs do backend:**
   - Procurar por erros ou exceções
   - Verificar se aparece "Buscando agendamentos para professor ID: 10"

2. ✅ **Verificar resposta HTTP:**
   - Abrir DevTools → Network
   - Clicar na requisição que falhou
   - Ver aba Response/Preview para ver a mensagem de erro

3. ✅ **Verificar dados no banco:**
   - Executar query SQL para verificar se há dados
   - Verificar se há campos NULL

4. ✅ **Aplicar Solução 1:**
   - Adicionar validações null-safe no `toResponseDTO`
   - Adicionar logs de debug

### Próximos Passos

1. Se confirmar NullPointerException:
   - Aplicar Solução 1 (validações null-safe)
   - Verificar por que as relações estão null

2. Se não for NullPointerException:
   - Verificar logs para identificar a exceção exata
   - Aplicar solução específica para a exceção encontrada

---

## 8. Informações Técnicas

### Exceções que Retornam 400

No `GlobalExceptionHandler`, as seguintes exceções retornam 400:

1. **`MethodArgumentNotValidException`** - Validação de parâmetros
2. **`BusinessException`** - Regras de negócio
3. **`RuntimeException`** - Qualquer RuntimeException (incluindo NullPointerException)

### Como Identificar a Exceção Exata

1. **Verificar logs do backend** (mais confiável)
2. **Verificar resposta HTTP** no navegador
3. **Adicionar logs de debug** no código

### Método `toResponseDTO` - Pontos de Falha

1. `agendamento.getProfessor().getNome()` - Se professor for null
2. `agendamento.getSala().getNome()` - Se sala for null
3. `agendamento.getEspecialidade().getNome()` - Se especialidade for null
4. `agendamento.getAgendamentoAlunos()` - Se for null
5. `aa.getAluno().getNome()` - Se aluno for null

---

**Data do Diagnóstico:** 2024-11-15  
**Erro:** `400 Bad Request`  
**Endpoint:** `GET /api/agendamentos/professorId/10`  
**Status:** Backend rodando, CORS funcionando, problema no processamento

