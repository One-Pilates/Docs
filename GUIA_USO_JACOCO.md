# 🎯 Guia Rápido de Uso do JaCoCo

## 📋 O que é JaCoCo?

JaCoCo (Java Code Coverage) é uma ferramenta que analisa a cobertura de código dos seus testes. Ele mostra:
- ✅ Quais linhas foram executadas pelos testes
- ✅ Quais branches (ifs, switches) foram testados
- ✅ Quais métodos foram chamados
- ✅ Quais classes foram instanciadas

## 🚀 Como Usar

### 1. Executar Testes e Gerar Relatório

```bash
# Executa os testes e gera o relatório automaticamente
mvn clean test

# Ou explicitamente
mvn clean test jacoco:report
```

### 2. Visualizar Relatório HTML

Após executar os testes, o relatório HTML será gerado em:

```
agendamento/target/site/jacoco/index.html
```

**Como abrir:**
1. Navegue até a pasta `target/site/jacoco/`
2. Abra o arquivo `index.html` no seu navegador
3. Explore a cobertura por pacote, classe e linha

### 3. Verificar Cobertura Mínima

O JaCoCo está configurado para verificar automaticamente se a cobertura mínima foi atingida:

```bash
# Executa testes e verifica cobertura (falha o build se não atingir meta)
mvn clean test jacoco:check
```

**Metas Configuradas:**
- ✅ **Linhas**: Mínimo 70% de cobertura
- ✅ **Branches**: Mínimo 60% de cobertura

Se a cobertura não atingir essas metas, o build falhará com uma mensagem detalhada.

## 📊 Entendendo o Relatório

### Cores no Relatório

- 🟢 **Verde**: Código completamente coberto pelos testes
- 🟡 **Amarelo**: Código parcialmente coberto (alguns branches não testados)
- 🔴 **Vermelho**: Código não coberto pelos testes

### Métricas Exibidas

1. **Missed**: Quantidade não coberta
2. **Covered**: Quantidade coberta
3. **Total**: Total de linhas/branches/métodos
4. **CIC**: Cobertura de instruções (Instruction Coverage)
5. **Branch**: Cobertura de branches condicionais
6. **Line**: Cobertura de linhas
7. **Method**: Cobertura de métodos

### Exemplo de Interpretação

```
com.onePilates.agendamento.service
├── AgendamentoService: 85% coverage
│   ├── criarAgendamento(): ✅ 100% covered
│   ├── excluirAgendamento(): ✅ 90% covered
│   └── atualizarAgendamento(): ⚠️ 60% covered (precisa mais testes)
└── ProfessorService: 78% coverage
```

## 🎯 Melhorando a Cobertura

### Identificando Gaps

1. **Abra o relatório HTML**
2. **Navegue até as classes com baixa cobertura**
3. **Clique na classe para ver linhas não cobertas** (marcadas em vermelho)
4. **Identifique métodos/branches não testados**

### Criando Testes para Gaps

**Exemplo: Método não coberto**

```java
// Código no Service
public void metodoImportante(int valor) {
    if (valor > 0) {  // ✅ Testado
        fazerAlgo();
    } else {          // ❌ NÃO testado
        fazerOutraCoisa();
    }
}
```

**Teste para cobrir o gap:**

```java
@Test
void metodoImportante_DeveFazerOutraCoisa_QuandoValorMenorOuIgualZero() {
    // Testa o branch não coberto
    service.metodoImportante(0);
    // Adicione verificações apropriadas
}
```

## 📝 Classes Excluídas da Verificação

As seguintes classes são automaticamente excluídas da verificação de cobertura (mas ainda aparecem no relatório):

- ✅ **DTOs** (`**/dto/**`) - Classes de transferência de dados
- ✅ **Exceptions** (`**/exception/**`) - Classes de exceção customizadas
- ✅ **Configs** (`**/config/**`) - Classes de configuração Spring
- ✅ **Response DTOs** (`**/response/**`) - DTOs de resposta
- ✅ **Application Main** (`AgendamentoApplication.class`) - Classe principal

Essas classes são excluídas porque:
- DTOs são simples POJOs sem lógica complexa
- Exceptions são estruturas de dados simples
- Configs são configurações, não lógica de negócio
- A cobertura se concentra em Services, Validators e Controllers

## 🔧 Comandos Úteis

### Gerar apenas relatório (sem executar testes)

```bash
mvn jacoco:report
```

### Limpar relatórios anteriores

```bash
mvn clean
```

### Executar testes e verificar cobertura em um comando

```bash
mvn clean test jacoco:check
```

### Ver relatório no console

```bash
mvn test jacoco:report
# O resumo aparece no console ao final
```

## 📈 Metas de Cobertura

### Atual (Configurado)

| Métrica | Mínimo | Meta Ideal |
|---------|--------|------------|
| **Linhas** | 70% | 80%+ |
| **Branches** | 60% | 70%+ |
| **Métodos** | - | 80%+ |
| **Classes** | - | 85%+ |

### Ajustando Metas

Para ajustar as metas, edite o `pom.xml`:

```xml
<limit>
    <counter>LINE</counter>
    <value>COVEREDRATIO</value>
    <minimum>0.80</minimum> <!-- Altere aqui -->
</limit>
```

## ⚠️ Troubleshooting

### Build falhando por cobertura baixa

**Solução**: 
1. Veja o relatório para identificar gaps
2. Crie testes para os métodos/classes com baixa cobertura
3. Execute `mvn test jacoco:report` para verificar melhorias

### Relatório não aparece

**Solução**:
```bash
# Garanta que os testes foram executados
mvn clean test

# Gere o relatório explicitamente
mvn jacoco:report

# Verifique se o arquivo existe
ls -la target/site/jacoco/index.html
```

### Cobertura sempre 0%

**Possíveis causas**:
1. Testes não foram executados: execute `mvn test`
2. Classe não está sendo instrumentada: verifique exclusões no pom.xml
3. Testes não chamam o código: verifique se os testes realmente executam o código

## 📚 Recursos Adicionais

### Documentação Oficial
- [JaCoCo Documentation](https://www.jacoco.org/jacoco/trunk/doc/)
- [JaCoCo Maven Plugin](https://www.jacoco.org/jacoco/trunk/doc/maven.html)

### Integração CI/CD

O JaCoCo pode ser integrado em pipelines CI/CD:

```yaml
# Exemplo GitHub Actions
- name: Run tests with coverage
  run: mvn clean test jacoco:report
  
- name: Upload coverage report
  uses: actions/upload-artifact@v2
  with:
    name: coverage-report
    path: target/site/jacoco/
```

## 🎓 Dicas Finais

1. **Foque em qualidade, não quantidade**: 100% de cobertura não significa código bem testado
2. **Teste comportamentos, não implementação**: Teste o que o código faz, não como faz
3. **Use o relatório como guia**: Identifique gaps, mas não obceque com números
4. **Priorize código crítico**: Foque em testar lógica de negócio importante
5. **Mantenha testes simples**: Testes complexos são difíceis de manter

---

**Última atualização**: 2025-01-22
**Versão**: 1.0

