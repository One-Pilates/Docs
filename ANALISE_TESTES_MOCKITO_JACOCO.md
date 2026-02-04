# Análise Detalhada dos Testes, Mockito e JaCoCo

## 📋 Índice
1. [Visão Geral dos Testes](#visão-geral-dos-testes)
2. [Estrutura dos Testes](#estrutura-dos-testes)
3. [Como os Testes Funcionam - Passo a Passo](#como-os-testes-funcionam---passo-a-passo)
4. [Mockito - Conceitos e Funcionamento](#mockito---conceitos-e-funcionamento)
5. [Exemplos Práticos de Testes](#exemplos-práticos-de-testes)
6. [JaCoCo - Cobertura de Código](#jacoco---cobertura-de-código)
7. [Tipos de Testes no Projeto](#tipos-de-testes-no-projeto)

---

## 📊 Visão Geral dos Testes

O projeto utiliza uma arquitetura de testes bem estruturada, seguindo as melhores práticas:

- **Framework de Testes**: JUnit 5 (Jupiter)
- **Framework de Mocking**: Mockito
- **Cobertura de Código**: JaCoCo
- **Testes Unitários**: Services, Validators
- **Testes de Integração**: Controllers

### Estatísticas dos Testes
- **Total de Testes**: 14 arquivos de teste
- **Localização**: `src/test/java/com/onePilates/agendamento/`
- **Estrutura**:
  - 12 testes de serviços (`service/`)
  - 1 teste de validação (`validator/`)
  - 1 teste de integração (`integration/`)

---

## 🏗️ Estrutura dos Testes

### Arquitetura Típica de um Teste

Cada classe de teste segue este padrão:

```java
@ExtendWith(MockitoExtension.class)  // 1. Ativa o Mockito
class NomeDoServiceTest {
    
    @Mock                              // 2. Cria mocks das dependências
    private Repository repository;
    
    @InjectMocks                       // 3. Injeta os mocks no objeto testado
    private Service service;
    
    private Entidade entidade;         // 4. Dados de teste
    
    @BeforeEach                        // 5. Prepara dados antes de cada teste
    void setUp() {
        // Configuração inicial
    }
    
    @Test                              // 6. Método de teste individual
    void nomeDoTeste_Condicao_ResultadoEsperado() {
        // Arrange: prepara o cenário
        // Act: executa a ação
        // Assert: verifica o resultado
    }
}
```

---

## 🔍 Como os Testes Funcionam - Passo a Passo

### 1. Anotação `@ExtendWith(MockitoExtension.class)`

**O que faz?**
- Integra o Mockito com o JUnit 5
- Inicializa automaticamente os mocks anotados com `@Mock`
- Injeta os mocks no objeto anotado com `@InjectMocks`

**Por que usar?**
- Antes, era necessário chamar `MockitoAnnotations.openMocks(this)` manualmente
- Simplifica o código e torna os testes mais limpos
- Garante que os mocks são reinicializados a cada teste

**Exemplo:**
```java
@ExtendWith(MockitoExtension.class)
class AgendamentoServiceTest {
    // Mockito está ativo e pronto para uso
}
```

### 2. Anotação `@Mock`

**O que faz?**
- Cria um objeto "simulado" (mock) de uma classe ou interface
- Este objeto NÃO é real - não executa código real
- Permite controlar o comportamento do objeto durante o teste

**Quando usar?**
- Para dependências do objeto que você está testando
- Quando quer isolar a unidade de código testada
- Para simular comportamentos específicos (sucesso, erro, etc.)

**Exemplo:**
```java
@Mock
private AgendamentoRepository agendamentoRepository;
// Este não é um repositório real - é uma simulação
```

**Características dos Mocks:**
- Por padrão, métodos retornam valores vazios/null
- Você precisa configurar explicitamente o comportamento esperado
- Você pode verificar se métodos foram chamados e quantas vezes

### 3. Anotação `@InjectMocks`

**O que faz?**
- Cria uma instância REAL da classe que você quer testar
- Injeta automaticamente os mocks nas dependências desta classe
- Se a classe usa injeção por construtor, o Mockito encontra e injeta os mocks

**Importante:**
- Cria uma instância REAL (não um mock) da classe sob teste
- Automaticamente encontra e injeta os `@Mock` nas dependências
- Funciona com construtores, setters ou campos (via reflexão)

**Exemplo:**
```java
@Mock
private AgendamentoRepository repository;

@Mock
private EmailService emailService;

@InjectMocks
private AgendamentoService service;
// Agora 'service' é uma instância real, mas com mocks nas dependências
```

### 4. Método `@BeforeEach`

**O que faz?**
- Executado ANTES de cada método `@Test`
- Usado para configurar dados e cenários comuns
- Garante que cada teste começa com um estado conhecido

**Por que usar?**
- Evita repetição de código
- Garante consistência entre testes
- Facilita manutenção

**Exemplo:**
```java
@BeforeEach
void setUp() {
    dto = new AgendamentoDTO();
    dto.setDataHora(LocalDateTime.now().plusDays(1));
    dto.setSalaId(1L);
    // Configurações comuns para todos os testes
}
```

### 5. Métodos `@Test`

**O que faz?**
- Marca um método como um teste individual
- Cada método é executado independentemente
- Segue o padrão Arrange-Act-Assert (AAA)

**Estrutura de um teste (padrão AAA):**

```java
@Test
void criarAgendamento_DeveCriarComSucesso_QuandoDadosValidos() {
    // ARRANGE: Prepara o cenário
    when(repository.findById(1L)).thenReturn(Optional.of(entidade));
    
    // ACT: Executa a ação que queremos testar
    Agendamento resultado = service.criarAgendamento(dto);
    
    // ASSERT: Verifica o resultado esperado
    assertNotNull(resultado);
    assertEquals(1L, resultado.getId());
    verify(repository).save(any(Agendamento.class));
}
```

---

## 🎭 Mockito - Conceitos e Funcionamento

### O que é Mockito?

Mockito é um framework de Java que permite criar **objetos simulados (mocks)** para testes. Ele permite:
- Simular dependências complexas
- Controlar o comportamento de objetos
- Verificar interações entre objetos
- Isolar a unidade de código testada

### Por que usar Mocks?

**Sem Mocks:**
```java
// PROBLEMA: Teste depende de banco de dados real
AgendamentoService service = new AgendamentoService(
    new AgendamentoRepository(), // Precisa de banco de dados
    new EmailService()           // Precisa de servidor de email
);
// Teste é lento, frágil e depende de serviços externos
```

**Com Mocks:**
```java
// SOLUÇÃO: Teste é rápido e isolado
@Mock AgendamentoRepository repository;
@Mock EmailService emailService;
@InjectMocks AgendamentoService service;
// Teste é rápido, previsível e não depende de serviços externos
```

### Principais Funcionalidades do Mockito

#### 1. `when().thenReturn()` - Definindo Comportamento

**O que faz?**
- Define o que um método mockado deve retornar quando chamado

**Sintaxe:**
```java
when(mock.metodo(parametros)).thenReturn(valorRetorno);
```

**Exemplo:**
```java
@Mock
private ProfessorRepository professorRepository;

@Test
void teste() {
    // Quando buscar por ID 1, retorna um professor específico
    when(professorRepository.findById(1L))
        .thenReturn(Optional.of(professor));
    
    // Quando o método for chamado, retornará o professor mockado
    Optional<Professor> resultado = professorRepository.findById(1L);
}
```

**Argument Matchers:**
```java
// Aceita qualquer Long
when(repository.findById(anyLong())).thenReturn(Optional.of(entidade));

// Aceita qualquer objeto do tipo Agendamento
when(repository.save(any(Agendamento.class))).thenReturn(agendamento);

// Aceita qualquer coleção
when(repository.findAllById(any())).thenReturn(lista);

// Valores específicos
when(repository.findById(1L)).thenReturn(Optional.of(entidade));
when(repository.findById(999L)).thenReturn(Optional.empty());
```

**Argument Matchers comuns:**
- `any()` - qualquer objeto
- `any(Class.class)` - qualquer objeto do tipo especificado
- `anyString()` - qualquer String
- `anyLong()` - qualquer Long
- `anyList()` - qualquer List
- `eq(valor)` - valor específico (usado quando há outros matchers)
- `isNull()` - valor null
- `isNotNull()` - valor não-nulo

#### 2. `doNothing().when()` - Métodos Void

**O que faz?**
- Para métodos que não retornam nada (void), define que nada deve acontecer

**Exemplo:**
```java
@Mock
private EmailService emailService;

@Test
void teste() {
    // Quando o método void for chamado, não faz nada
    doNothing().when(emailService).enviarEmail(anyString());
    
    // Ou pode ser usado para métodos que não devem lançar exceção
    doNothing().when(validator).validar(any(AgendamentoDTO.class));
}
```

#### 3. `doThrow().when()` - Simulando Exceções

**O que faz?**
- Define que um método deve lançar uma exceção quando chamado

**Exemplo:**
```java
@Test
void teste() {
    // Quando validar for chamado, lança uma BusinessException
    doThrow(new BusinessException("Erro", "CODIGO"))
        .when(validator).validar(any(AgendamentoDTO.class));
    
    // Agora quando chamar o método, a exceção será lançada
    assertThrows(BusinessException.class, () -> {
        service.criarAgendamento(dto);
    });
}
```

#### 4. `verify()` - Verificando Interações

**O que faz?**
- Verifica se um método foi chamado e quantas vezes
- Importante para garantir que o código testado está interagindo corretamente com suas dependências

**Sintaxe:**
```java
verify(mock).metodo(parametros);
verify(mock, times(n)).metodo(parametros);
verify(mock, never()).metodo(parametros);
verify(mock, atLeast(n)).metodo(parametros);
verify(mock, atMost(n)).metodo(parametros);
```

**Exemplos:**
```java
@Test
void criarAgendamento_DeveSalvarNoBanco() {
    service.criarAgendamento(dto);
    
    // Verifica se save foi chamado
    verify(repository).save(any(Agendamento.class));
    
    // Verifica se save foi chamado exatamente 1 vez
    verify(repository, times(1)).save(any(Agendamento.class));
    
    // Verifica se delete nunca foi chamado
    verify(repository, never()).deleteById(any());
}
```

**Modos de Verificação:**
- `verify(mock)` - deve ser chamado pelo menos 1 vez (padrão)
- `verify(mock, times(1))` - deve ser chamado exatamente 1 vez
- `verify(mock, times(n))` - deve ser chamado exatamente n vezes
- `verify(mock, never())` - nunca deve ser chamado
- `verify(mock, atLeast(n))` - deve ser chamado pelo menos n vezes
- `verify(mock, atMost(n))` - deve ser chamado no máximo n vezes

#### 5. `mock()` - Criação Manual de Mocks

**O que faz?**
- Cria um mock manualmente (alternativa a `@Mock`)

**Quando usar?**
- Quando precisa criar mocks dinamicamente
- Para tipos genéricos complexos
- Para mocks locais em métodos específicos

**Exemplo:**
```java
@Test
void teste() {
    MultipartFile file = mock(MultipartFile.class);
    when(file.getOriginalFilename()).thenReturn("foto.jpg");
    when(file.getSize()).thenReturn(1024L);
}
```

---

## 📚 Exemplos Práticos de Testes

### Exemplo 1: Teste de Criação com Sucesso

```java
@Test
void criarAgendamento_DeveCriarComSucesso_QuandoDadosValidos() {
    // ARRANGE: Configura os mocks para retornar dados válidos
    when(professorRepository.findById(1L))
        .thenReturn(Optional.of(professor));
    when(salaRepository.findById(1L))
        .thenReturn(Optional.of(sala));
    when(especialidadeRepository.findById(1L))
        .thenReturn(Optional.of(especialidade));
    when(alunoRepository.findAllById(any()))
        .thenReturn(alunos);
    when(agendamentoRepository.save(any(Agendamento.class)))
        .thenReturn(agendamento);
    when(agendamentoRepository.findById(1L))
        .thenReturn(Optional.of(agendamento));
    
    // Configura validador para não lançar exceção
    doNothing().when(agendamentoValidator)
        .validar(any(AgendamentoDTO.class));
    
    // ACT: Executa o método que queremos testar
    Agendamento resultado = agendamentoService.criarAgendamento(dto);
    
    // ASSERT: Verifica se o resultado está correto
    assertNotNull(resultado);                    // Resultado não é null
    assertEquals(1L, resultado.getId());         // ID correto
    verify(agendamentoRepository, times(1))      // Save foi chamado 1 vez
        .save(any(Agendamento.class));
    verify(notifier, times(1))                   // Notificação foi enviada
        .notificarTodos(any(Agendamento.class));
}
```

**Explicação:**
1. **ARRANGE**: Prepara todos os mocks para simular um cenário de sucesso
2. **ACT**: Chama o método real do serviço
3. **ASSERT**: Verifica que o resultado está correto e que os métodos esperados foram chamados

### Exemplo 2: Teste de Validação de Erro

```java
@Test
void criarAgendamento_DeveLancarExcecao_QuandoValidacaoFalha() {
    // ARRANGE: Configura o validador para lançar exceção
    doThrow(new BusinessException("Erro de validação", "ERRO_VALIDACAO"))
        .when(agendamentoValidator)
        .validar(any(AgendamentoDTO.class));
    
    // ACT & ASSERT: Verifica que a exceção foi lançada
    assertThrows(BusinessException.class, () -> {
        agendamentoService.criarAgendamento(dto);
    });
    
    // Verifica que o repositório NUNCA foi chamado (validação falhou antes)
    verify(agendamentoRepository, never())
        .save(any(Agendamento.class));
}
```

**Explicação:**
- Simula uma falha de validação
- Verifica que a exceção correta foi lançada
- Garante que o processo parou antes de salvar (never())

### Exemplo 3: Teste com Múltiplas Verificações

```java
@Test
void excluirAgendamento_DeveExcluirComSucesso_QuandoAgendamentoExiste() {
    // ARRANGE
    when(agendamentoRepository.existsById(1L)).thenReturn(true);
    when(agendamentoRepository.findById(1L))
        .thenReturn(Optional.of(agendamento));
    doNothing().when(agendamentoRepository).deleteById(1L);
    when(emailService.envioEmailCancelamentoAula(
        any(), any(), any(LocalDateTime.class), any(), any()
    )).thenReturn("Email enviado");
    
    // ACT
    assertDoesNotThrow(() -> {
        agendamentoService.excluirAgendamento(1L);
    });
    
    // ASSERT: Múltiplas verificações
    verify(agendamentoRepository, times(1)).deleteById(1L);
    verify(emailService, times(1)).envioEmailCancelamentoAula(
        eq(professor.getNome()),              // Nome do professor
        eq(professor.getEmail()),             // Email do professor
        eq(agendamento.getDataHora()),        // Data/hora da aula
        eq(sala.getNome()),                   // Nome da sala
        eq(especialidade.getNome())           // Nome da especialidade
    );
}
```

**Explicação:**
- Testa um método que faz múltiplas operações
- Verifica que cada operação foi executada corretamente
- Usa `eq()` para verificar valores específicos quando há outros matchers

### Exemplo 4: Teste com Argument Matchers Complexos

```java
@Test
void criarAgendamento_DeveValidarConflitosAntesDeSalvar() {
    // ARRANGE
    when(professorRepository.findById(1L))
        .thenReturn(Optional.of(professor));
    when(salaRepository.findById(1L))
        .thenReturn(Optional.of(sala));
    // ... outras configurações
    
    // Configura verificações de conflito para retornar false (sem conflito)
    when(agendamentoRepository.existsByProfessorIdAndDataHora(any(), any()))
        .thenReturn(false);
    when(agendamentoRepository.existsBySalaIdAndDataHora(any(), any()))
        .thenReturn(false);
    when(agendamentoRepository.findAgendamentosByAlunoAndDataHora(any(), any()))
        .thenReturn(Collections.emptyList());
    
    // ACT
    Agendamento resultado = agendamentoService.criarAgendamento(dto);
    
    // ASSERT: Verifica que as validações de conflito foram chamadas
    verify(agendamentoRepository)
        .existsByProfessorIdAndDataHora(any(), any());
    verify(agendamentoRepository)
        .existsBySalaIdAndDataHora(any(), any());
}
```

**Explicação:**
- Mostra uso de múltiplos argument matchers (`any()`)
- Verifica que validações específicas foram executadas
- Garante que o fluxo correto foi seguido

### Exemplo 5: Teste de Integração

```java
@SpringBootTest                          // Carrega contexto Spring completo
@AutoConfigureMockMvc                    // Configura MockMvc para testes HTTP
@ActiveProfiles("test")                  // Usa perfil de teste
@TestPropertySource(locations = "classpath:application-test.properties")
class AgendamentoControllerIntegrationTest {
    
    @Autowired
    private MockMvc mockMvc;              // Simula requisições HTTP
    
    @Autowired
    private AgendamentoRepository repository;  // Repositório REAL (H2)
    
    @BeforeEach
    @Transactional
    void setUp() {
        // Limpa e prepara dados reais no banco de teste (H2)
        repository.deleteAll();
        // Cria entidades reais
        professor = professorRepository.save(new Professor(...));
    }
    
    @Test
    void criarAgendamento_DeveRetornar401Ou403_SemAutenticacao() throws Exception {
        AgendamentoDTO dto = new AgendamentoDTO();
        // ... configuração
        
        // Simula requisição HTTP POST
        mockMvc.perform(post("/api/agendamentos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(dto)))
            .andExpect(status().is4xxClientError());  // Verifica status HTTP
    }
}
```

**Diferenças entre Teste Unitário e Integração:**

| Aspecto | Teste Unitário | Teste de Integração |
|---------|---------------|---------------------|
| **Objetos** | Mocks | Objetos Reais |
| **Banco de Dados** | Não usa | Usa H2 (em memória) |
| **Contexto Spring** | Parcial | Completo |
| **Velocidade** | Rápido | Mais lento |
| **Isolamento** | Alto | Médio |
| **Quando usar** | Lógica de negócio | Fluxo completo |

---

## 📊 JaCoCo - Cobertura de Código

### O que é JaCoCo?

JaCoCo (Java Code Coverage) é uma ferramenta que analisa quanto do seu código fonte está sendo coberto pelos testes. Ele gera relatórios mostrando:
- **Linhas cobertas**: Quantas linhas foram executadas
- **Branches cobertos**: Quantos caminhos condicionais foram testados
- **Métodos cobertos**: Quantos métodos foram chamados
- **Classes cobertas**: Quantas classes foram testadas

### Configuração do JaCoCo no Projeto

O JaCoCo já está configurado no `pom.xml` com a seguinte estrutura:

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.9</version>
    <executions>
        <!-- Prepara o agente JaCoCo para capturar dados de cobertura -->
        <execution>
            <id>prepare-agent</id>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        
        <!-- Gera o relatório HTML após os testes -->
        <execution>
            <id>report</id>
            <phase>prepare-package</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

### Como Funciona?

1. **prepare-agent**: Configura o agente JaCoCo para monitorar a execução dos testes
   - Executado antes dos testes
   - Instrumenta o código bytecode para rastrear execução
   - Gera arquivo `.exec` com dados de cobertura

2. **report**: Gera relatórios HTML a partir dos dados coletados
   - Executado na fase `prepare-package`
   - Cria relatórios HTML em `target/site/jacoco/index.html`

### Como Usar?

#### Gerar Relatório de Cobertura

```bash
# Executa testes e gera relatório
mvn clean test

# Ou explicitamente
mvn clean test jacoco:report
```

#### Ver Relatório

Após executar os testes, abra o arquivo:
```
target/site/jacoco/index.html
```

Este relatório mostra:
- **Overview**: Visão geral da cobertura
- **Por Pacote**: Cobertura de cada pacote
- **Por Classe**: Cobertura detalhada de cada classe

### Métricas de Cobertura

#### 1. Line Coverage (Cobertura de Linhas)
- **Verde**: Linha executada
- **Vermelho**: Linha não executada
- **Amarelo**: Linha parcialmente executada (branch não completo)

#### 2. Branch Coverage (Cobertura de Branches)
- **If/else**: Ambos os caminhos foram testados?
- **Switch**: Todos os cases foram testados?
- **Operadores lógicos**: Todos os caminhos foram testados?

#### 3. Method Coverage (Cobertura de Métodos)
- Quantos métodos foram chamados durante os testes?

#### 4. Class Coverage (Cobertura de Classes)
- Quantas classes foram instanciadas durante os testes?

### Exemplo de Relatório JaCoCo

```
Total Coverage: 78%
├── Services: 85%
│   ├── AgendamentoService: 90%
│   ├── ProfessorService: 88%
│   └── AuthService: 82%
├── Controllers: 65%
└── Validators: 95%
```

### Configurações Avançadas (Implementadas)

Foram adicionadas configurações avançadas no `pom.xml`:

1. **Limites de Cobertura**: Define metas mínimas de cobertura
2. **Verificação**: Falha o build se não atingir a meta
3. **Relatórios Detalhados**: Inclui classes, métodos e branches

### Melhorias Implementadas

1. **Configuração de Limites**: Meta de 70% de cobertura mínima
2. **Verificação Automática**: Build falha se não atingir meta
3. **Exclusões**: Exclui DTOs, Exceptions, Configs da verificação
4. **Relatórios**: HTML, XML e CSV

---

## 🧪 Tipos de Testes no Projeto

### 1. Testes Unitários de Serviços

**Objetivo**: Testar a lógica de negócio isoladamente

**Exemplo**: `AgendamentoServiceTest`
- Testa criação, exclusão, validações
- Usa mocks para todas as dependências
- Focado na lógica do serviço

**Características**:
- Rápidos (milissegundos)
- Isolados
- Previsíveis
- Não dependem de recursos externos

### 2. Testes de Validação

**Objetivo**: Testar regras de validação de negócio

**Exemplo**: `AgendamentoValidatorTest`
- Testa validações de conflito
- Testa validações de capacidade
- Testa validações de equipamentos PCD

**Características**:
- Testam regras específicas
- Podem ter muitos cenários
- Importantes para garantir integridade

### 3. Testes de Integração

**Objetivo**: Testar fluxo completo incluindo banco de dados

**Exemplo**: `AgendamentoControllerIntegrationTest`
- Testa endpoints HTTP
- Usa banco H2 em memória
- Testa integração completa

**Características**:
- Mais lentos (segundos)
- Testam fluxo completo
- Usam recursos reais (H2)

---

## 📝 Boas Práticas de Testes

### 1. Nomenclatura Clara

```java
// ✅ BOM
void criarAgendamento_DeveCriarComSucesso_QuandoDadosValidos()
void excluirAgendamento_DeveLancarExcecao_QuandoNaoEncontrado()

// ❌ RUIM
void test1()
void testeCriar()
```

### 2. Um Assert por Conceito

```java
// ✅ BOM
assertNotNull(resultado);
assertEquals(1L, resultado.getId());
verify(repository).save(any(Agendamento.class));

// ❌ RUIM (múltiplas verificações em uma linha difícil de ler)
assertTrue(resultado != null && resultado.getId() == 1L);
```

### 3. Testes Independentes

```java
// ✅ BOM: Cada teste configura seu próprio cenário
@BeforeEach
void setUp() {
    // Configuração comum
}

@Test
void teste1() {
    // Configuração específica do teste1
}

// ❌ RUIM: Testes dependem uns dos outros
```

### 4. Arrange-Act-Assert (AAA)

```java
@Test
void exemplo() {
    // ARRANGE: Preparar
    when(...).thenReturn(...);
    
    // ACT: Executar
    var resultado = service.metodo();
    
    // ASSERT: Verificar
    assertNotNull(resultado);
}
```

### 5. Testes Focados

```java
// ✅ BOM: Um teste, um comportamento
@Test
void criar_QuandoDadosValidos_DeveSalvar()
@Test
void criar_QuandoDadosInvalidos_DeveLancarExcecao()

// ❌ RUIM: Múltiplos comportamentos em um teste
@Test
void criar_VariosCenarios() {
    // Testa criação válida
    // Testa criação inválida
    // Testa atualização
}
```

---

## 🎯 Resumo dos Conceitos

### Mockito em 3 Passos

1. **Criar Mocks** (`@Mock`)
   ```java
   @Mock
   private Repository repository;
   ```

2. **Configurar Comportamento** (`when().thenReturn()`)
   ```java
   when(repository.findById(1L)).thenReturn(Optional.of(entidade));
   ```

3. **Verificar Interações** (`verify()`)
   ```java
   verify(repository).save(any(Entidade.class));
   ```

### Fluxo de um Teste

```
1. @BeforeEach: Prepara dados
2. @Test: Executa teste
   ├── ARRANGE: Configura mocks
   ├── ACT: Executa método
   └── ASSERT: Verifica resultado
3. Mockito valida interações
```

### JaCoCo em 3 Passos

1. **Executar Testes**: `mvn test`
2. **Gerar Relatório**: `mvn jacoco:report`
3. **Visualizar**: `target/site/jacoco/index.html`

---

## 🔗 Referências

- [JUnit 5 Documentation](https://junit.org/junit5/docs/current/user-guide/)
- [Mockito Documentation](https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html)
- [JaCoCo Documentation](https://www.jacoco.org/jacoco/trunk/doc/)
- [Spring Boot Testing](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.testing)

---

**Documento criado em**: 2025-01-22
**Versão**: 1.0
**Autor**: Análise Automática dos Testes

