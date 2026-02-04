# Solução: ClassNotFoundException - AgendamentoRepository

## Erro
```
Caused by: java.lang.ClassNotFoundException: AgendamentoRepository
at org.springframework.boot.devtools.restart.classloader.RestartClassLoader.loadClass
```

## Causa
O Spring DevTools não está conseguindo carregar a classe `AgendamentoRepository` através do `RestartClassLoader`, mesmo que o arquivo `.class` exista no diretório `target/classes`.

Este é um problema conhecido do Spring DevTools relacionado ao classloader.

## Soluções (em ordem de prioridade)

### ✅ Solução 1: Rebuild Completo do Projeto (RECOMENDADO)

**No IntelliJ IDEA:**
1. **Build > Rebuild Project** (ou `Ctrl+Shift+F9`)
2. Aguarde a compilação completa
3. Execute a aplicação novamente

**Via Terminal (se tiver Maven):**
```bash
cd backend/agendamento
mvn clean install
```

### ✅ Solução 2: Invalidar Cache e Rebuild

**No IntelliJ IDEA:**
1. **File > Invalidate Caches...**
2. Marque todas as opções:
   - Clear file system cache and Local History
   - Clear downloaded shared indexes
   - Clear VCS Log caches and indexes
3. Clique em **Invalidate and Restart**
4. Após reiniciar: **Build > Rebuild Project**

### ✅ Solução 3: Desabilitar Spring DevTools Temporariamente

Se as soluções acima não funcionarem, desabilite o DevTools temporariamente:

**No `pom.xml`:**
```xml
<!-- Comentar temporariamente -->
<!--
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <scope>runtime</scope>
    <optional>true</optional>
</dependency>
-->
```

Depois:
1. **Build > Rebuild Project**
2. Execute a aplicação
3. Se funcionar, reative o DevTools e tente novamente

### ✅ Solução 4: Limpar Diretório Target Manualmente

Já foi feito! O diretório `target` foi removido. Agora:
1. **Build > Rebuild Project** no IntelliJ
2. Execute a aplicação

### ✅ Solução 5: Verificar Estrutura do Projeto

Certifique-se de que:
- O arquivo está em: `src/main/java/com/onePilates/agendamento/repository/AgendamentoRepository.java`
- O package está correto: `package com.onePilates.agendamento.repository;`
- Não há erros de sintaxe no arquivo

## Verificação

Após aplicar as soluções, verifique:

1. **O arquivo `.class` foi gerado?**
   - Verifique em: `target/classes/com/onePilates/agendamento/repository/AgendamentoRepository.class`

2. **Não há erros de compilação?**
   - Verifique a aba "Build" no IntelliJ

3. **A aplicação inicia?**
   - Execute e verifique se o erro desapareceu

## Status Atual

- ✅ Diretório `target` removido
- ⏳ **Próximo passo:** Rebuild do projeto no IntelliJ

## Comandos Úteis

```bash
# Limpar e recompilar (se tiver Maven)
mvn clean compile

# Verificar se o arquivo .class existe
ls -la target/classes/com/onePilates/agendamento/repository/AgendamentoRepository.class
```

