# Diagnóstico: ERR_CONNECTION_REFUSED - Backend não está acessível

## Data do Diagnóstico
2024-11-15

## Erro Reportado
```
GET http://localhost:8080/api/agendamentos/professorId/10 net::ERR_CONNECTION_REFUSED
```

---

## 🔴 PROBLEMA PRINCIPAL: Backend não está rodando ou não está acessível

### O que significa ERR_CONNECTION_REFUSED?

O erro `ERR_CONNECTION_REFUSED` indica que o navegador **não conseguiu estabelecer uma conexão TCP** com o servidor na porta 8080. Isso significa que:

1. **O backend não está rodando** (mais provável)
2. **O backend está rodando em uma porta diferente** de 8080
3. **O backend está rodando, mas há um problema de rede/firewall**
4. **O backend está rodando, mas travou/crashou durante a inicialização**

---

## 1. Verificações Imediatas

### 1.1 Verificar se o Backend está Rodando

**No terminal onde o backend deveria estar rodando:**

1. **Verificar se há um processo Java rodando:**
   ```bash
   # Windows (PowerShell ou CMD)
   netstat -ano | findstr :8080
   
   # Ou verificar processos Java
   jps -l
   ```

2. **Verificar logs do Spring Boot:**
   - Deve aparecer: `Started AgendamentoApplication in X.XXX seconds`
   - Se não aparecer, o backend não iniciou corretamente

3. **Verificar se há erros no console:**
   - Erros de conexão com banco de dados
   - Erros de configuração
   - Erros de dependências faltando

### 1.2 Verificar Porta do Backend

**Arquivo:** `backend/agendamento/src/main/resources/application.properties`

**Status Atual:**
- ❌ **NÃO há configuração de porta** no arquivo
- O Spring Boot usa a porta padrão: **8080**

**Se o backend estiver rodando em outra porta, você verá nos logs:**
```
Tomcat started on port(s): 8081 (http) with context path ''
```

**Solução:**
- Se o backend estiver em outra porta, atualizar a variável `VITE_BASE_URL_API` no frontend
- Ou adicionar `server.port=8080` no `application.properties` para garantir a porta 8080

---

## 2. Problemas Comuns e Soluções

### 🔴 PROBLEMA #1: Backend não foi iniciado

**Sintomas:**
- Nenhum processo na porta 8080
- Nenhum log do Spring Boot no console
- Erro `ERR_CONNECTION_REFUSED` no navegador

**Solução:**
1. **Navegar até a pasta do backend:**
   ```bash
   cd backend/agendamento
   ```

2. **Iniciar o backend:**
   ```bash
   # Com Maven
   ./mvnw spring-boot:run
   
   # Ou com Maven instalado globalmente
   mvn spring-boot:run
   
   # Ou executar o JAR (se já foi compilado)
   java -jar target/agendamento-0.0.1-SNAPSHOT.jar
   ```

3. **Aguardar inicialização completa:**
   - Deve aparecer: `Started AgendamentoApplication`
   - Não deve haver erros de conexão com banco

---

### 🔴 PROBLEMA #2: Backend travou durante inicialização

**Sintomas:**
- Logs do Spring Boot aparecem, mas para antes de "Started"
- Erro de conexão com banco de dados
- Erro de configuração

**Possíveis Causas:**

#### A. Erro de Conexão com Banco de Dados

**Erro típico:**
```
com.mysql.cj.jdbc.exceptions.CommunicationsException: Communications link failure
```

**Solução:**
1. **Verificar se o MySQL está rodando:**
   ```bash
   # Windows
   netstat -ano | findstr :3306
   
   # Ou verificar serviços
   services.msc (procurar por MySQL)
   ```

2. **Verificar credenciais no `application.properties`:**
   ```properties
   spring.datasource.url=jdbc:mysql://localhost:3306/onePilates?useSSL=false&serverTimezone=UTC
   spring.datasource.username=root
   spring.datasource.password=#Gf1540092a215434
   ```

3. **Verificar se o banco `onePilates` existe:**
   ```sql
   -- Conectar ao MySQL
   mysql -u root -p
   
   -- Verificar se o banco existe
   SHOW DATABASES;
   
   -- Se não existir, criar
   CREATE DATABASE onePilates;
   ```

#### B. Erro de Configuração

**Erro típico:**
```
org.springframework.beans.factory.BeanCreationException
```

**Solução:**
- Verificar logs completos do Spring Boot
- Verificar se todas as dependências estão instaladas
- Verificar se há erros de sintaxe no código

---

### 🟡 PROBLEMA #3: Backend está rodando em porta diferente

**Sintomas:**
- Backend inicia com sucesso
- Logs mostram: `Tomcat started on port(s): 8081` (ou outra porta)
- Frontend ainda tenta conectar em 8080

**Solução:**

**Opção A - Alterar porta do backend para 8080:**
```properties
# application.properties
server.port=8080
```

**Opção B - Atualizar URL do frontend:**
```env
# .env do frontend
VITE_BASE_URL_API=http://localhost:8081
```

---

### 🟡 PROBLEMA #4: Firewall ou Antivírus bloqueando

**Sintomas:**
- Backend está rodando
- Logs mostram que iniciou corretamente
- Ainda assim, `ERR_CONNECTION_REFUSED`

**Solução:**
1. **Verificar firewall do Windows:**
   - Permitir conexões na porta 8080
   - Ou desabilitar temporariamente para teste

2. **Verificar antivírus:**
   - Adicionar exceção para o processo Java
   - Ou desabilitar temporariamente para teste

---

## 3. Checklist de Diagnóstico

### 3.1 Verificações no Backend

- [ ] **Backend está rodando?**
  - Verificar processo na porta 8080
  - Verificar logs do Spring Boot
  
- [ ] **Backend iniciou completamente?**
  - Deve aparecer: `Started AgendamentoApplication`
  - Não deve haver erros críticos
  
- [ ] **Banco de dados está acessível?**
  - MySQL está rodando?
  - Credenciais estão corretas?
  - Banco `onePilates` existe?
  
- [ ] **Porta está correta?**
  - Backend está na porta 8080?
  - Ou está em outra porta?

### 3.2 Verificações no Frontend

- [ ] **Variável `VITE_BASE_URL_API` está configurada?**
  - Deve ser: `http://localhost:8080`
  - Verificar arquivo `.env` ou `.env.local`
  
- [ ] **Frontend está tentando conectar na URL correta?**
  - Verificar no console do navegador
  - Verificar na aba Network do DevTools

---

## 4. Testes de Verificação

### Teste 1: Verificar se Backend está Rodando

**No terminal:**
```bash
# Windows
netstat -ano | findstr :8080

# Se aparecer algo como:
# TCP    0.0.0.0:8080           0.0.0.0:0              LISTENING       12345
# Então o backend está rodando na porta 8080
```

**Ou testar com curl:**
```bash
curl http://localhost:8080/actuator/health

# Se o backend estiver rodando, deve retornar algo
# Se não estiver, dará: "Connection refused"
```

### Teste 2: Verificar Endpoint Diretamente

**No navegador:**
```
http://localhost:8080/api/agendamentos
```

**Resultado esperado:**
- Se backend estiver rodando: Pode retornar 401 (sem autenticação) ou 200 (se autenticado)
- Se backend não estiver rodando: `ERR_CONNECTION_REFUSED` ou página não carrega

### Teste 3: Verificar Logs do Backend

**Procurar por:**
```
Started AgendamentoApplication in X.XXX seconds (JVM running for Y.YYY)
```

**Se não aparecer:**
- Backend não iniciou completamente
- Verificar erros anteriores nos logs

---

## 5. Soluções Passo a Passo

### Solução 1: Iniciar o Backend (se não estiver rodando)

1. **Abrir terminal na pasta do backend:**
   ```bash
   cd backend/agendamento
   ```

2. **Verificar se Maven está instalado:**
   ```bash
   mvn --version
   ```

3. **Compilar e executar:**
   ```bash
   mvn clean install
   mvn spring-boot:run
   ```

4. **Aguardar mensagem:**
   ```
   Started AgendamentoApplication in X.XXX seconds
   ```

5. **Testar no navegador:**
   ```
   http://localhost:8080/api/agendamentos
   ```

### Solução 2: Verificar e Corrigir Conexão com Banco

1. **Verificar se MySQL está rodando:**
   ```bash
   # Windows - verificar serviço
   services.msc
   # Procurar por "MySQL" e verificar se está "Em execução"
   ```

2. **Testar conexão manual:**
   ```bash
   mysql -u root -p
   # Inserir senha: #Gf1540092a215434
   ```

3. **Verificar se banco existe:**
   ```sql
   SHOW DATABASES;
   -- Deve aparecer "onePilates"
   ```

4. **Se banco não existir, criar:**
   ```sql
   CREATE DATABASE onePilates;
   ```

5. **Reiniciar backend**

### Solução 3: Garantir Porta Correta

1. **Adicionar configuração explícita:**
   ```properties
   # application.properties
   server.port=8080
   ```

2. **Ou verificar qual porta está sendo usada:**
   - Verificar logs do Spring Boot
   - Procurar por: `Tomcat started on port(s):`

3. **Atualizar frontend se necessário:**
   ```env
   # .env do frontend
   VITE_BASE_URL_API=http://localhost:8080
   ```

---

## 6. Diagnóstico Rápido

### Comando para Verificar Tudo de Uma Vez

**No terminal (Windows PowerShell):**
```powershell
# Verificar se porta 8080 está em uso
netstat -ano | findstr :8080

# Verificar processos Java
jps -l

# Testar conexão HTTP
curl http://localhost:8080/actuator/health
```

**Resultados Esperados:**

1. **Se porta 8080 está em uso:**
   - Backend provavelmente está rodando
   - Problema pode ser CORS ou autenticação

2. **Se porta 8080 NÃO está em uso:**
   - Backend não está rodando
   - Iniciar backend

3. **Se curl retorna algo:**
   - Backend está respondendo
   - Problema pode ser no frontend (URL, CORS, autenticação)

4. **Se curl retorna "Connection refused":**
   - Backend não está rodando
   - Iniciar backend

---

## 7. Resumo Executivo

### Problema Mais Provável
**Backend não está rodando** (95% de probabilidade)

### Ação Imediata Recomendada
1. ✅ **Verificar se backend está rodando:**
   ```bash
   netstat -ano | findstr :8080
   ```

2. ✅ **Se não estiver rodando, iniciar:**
   ```bash
   cd backend/agendamento
   mvn spring-boot:run
   ```

3. ✅ **Aguardar mensagem de sucesso:**
   ```
   Started AgendamentoApplication
   ```

4. ✅ **Testar no navegador:**
   ```
   http://localhost:8080/api/agendamentos
   ```

5. ✅ **Se funcionar, testar frontend novamente**

### Próximos Passos (se backend estiver rodando)
1. Verificar configuração de CORS (já foi adicionada)
2. Verificar se variável `VITE_BASE_URL_API` está configurada
3. Verificar se token está sendo enviado
4. Verificar logs do backend para erros específicos

---

## 8. Informações Técnicas

### Porta Padrão do Spring Boot
- **Porta padrão:** 8080
- **Configuração:** `server.port` no `application.properties`
- **Se não configurado:** Spring Boot usa 8080

### Como o Spring Boot Inicia
1. Carrega `application.properties`
2. Conecta ao banco de dados
3. Inicializa contexto Spring
4. Inicia servidor Tomcat na porta configurada
5. Exibe: `Started AgendamentoApplication`

### Sinais de que Backend Está Rodando
- ✅ Processo na porta 8080
- ✅ Logs mostram "Started AgendamentoApplication"
- ✅ Responde a requisições HTTP
- ✅ Não há erros críticos nos logs

### Sinais de que Backend NÃO Está Rodando
- ❌ Nenhum processo na porta 8080
- ❌ `ERR_CONNECTION_REFUSED` no navegador
- ❌ Nenhum log do Spring Boot
- ❌ Backend travou durante inicialização

---

**Data do Diagnóstico:** 2024-11-15  
**Erro:** `ERR_CONNECTION_REFUSED`  
**Porta Esperada:** 8080  
**Status:** Backend provavelmente não está rodando

