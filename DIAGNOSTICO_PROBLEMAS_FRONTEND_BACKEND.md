# Diagnóstico de Problemas - Frontend não consegue buscar Agendamentos

## Data do Diagnóstico
2024-11-15

## Problema Reportado
O frontend não consegue buscar os agendamentos do backend.

---

## 1. Análise do Fluxo de Requisição

### 1.1 Endpoint Solicitado pelo Frontend

**Frontend (`Calendar/model.jsx` linha 37):**
```javascript
const response = await api.get(`/api/agendamentos/professorId/${user.id}`);
```

**Backend (`AgendamentoController.java` linha 90-94):**
```java
@GetMapping("/professorId/{id}")
@PreAuthorize("hasAnyAuthority('ADMINISTRADOR', 'SECRETARIA', 'PROFESSOR')")
public ResponseEntity<List<AgendamentoResponseDTO>> listarPorProfessorId(@PathVariable Long id) {
   return ResponseEntity.ok(agendamentoService.buscarAgendamentosPorIdProfessor(id));
}
```

**✅ Endpoint existe e está correto**

### 1.2 Estrutura do User Object

**Frontend armazena (`AuthProvider.jsx` linha 28):**
```javascript
localStorage.setItem("user", JSON.stringify(data.funcionario));
```

**Backend retorna (`FuncionarioLoginDTO.java` linha 13):**
```java
private Long id;
// ... outros campos
```

**✅ O campo `id` existe no DTO e deve estar disponível em `user.id`**

---

## 2. Problemas Identificados

### 🔴 PROBLEMA CRÍTICO #1: Configuração de CORS Incompleta

**Localização:** `SecurityConfig.java`

**Problema:**
- O `SecurityConfig` **NÃO** tem configuração de CORS
- Apenas o controller tem `@CrossOrigin(origins = "*")`
- Quando Spring Security está ativo, a anotação `@CrossOrigin` no controller pode não ser suficiente
- O Spring Security pode estar bloqueando requisições CORS antes de chegar ao controller

**Evidência:**
```java
// SecurityConfig.java - NÃO TEM configuração de CORS
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .csrf(csrf -> csrf.disable())
        .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        // ... SEM configuração de CORS aqui
        .addFilterBefore(jwtAuthFilter(), UsernamePasswordAuthenticationFilter.class);
    return http.build();
}
```

**Impacto:** 
- Requisições do frontend podem ser bloqueadas pelo navegador
- Erro: `CORS policy: No 'Access-Control-Allow-Origin' header is present`
- Ou: `CORS policy: The request client is not a secure context`

**Solução Necessária:**
Adicionar configuração de CORS no `SecurityConfig`:

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .cors(cors -> cors.configurationSource(corsConfigurationSource())) // ADICIONAR
        .csrf(csrf -> csrf.disable())
        // ... resto da configuração
}

@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOrigins(Arrays.asList("*")); // ou específicos
    configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
    configuration.setAllowedHeaders(Arrays.asList("*"));
    configuration.setAllowCredentials(true);
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
}
```

---

### 🟡 PROBLEMA POTENCIAL #2: Inconsistência entre hasRole e hasAnyAuthority

**Localização:** `SecurityConfig.java` vs `AgendamentoController.java`

**Problema:**
- `SecurityConfig` usa `hasRole("ADMINISTRADOR")` que adiciona prefixo "ROLE_"
- `AgendamentoController` usa `hasAnyAuthority('ADMINISTRADOR', 'SECRETARIA', 'PROFESSOR')` que NÃO adiciona prefixo
- O JWT pode estar retornando roles com ou sem prefixo "ROLE_"

**Evidência:**
```java
// SecurityConfig.java linha 46-48
.requestMatchers("/admin/**").hasRole("ADMINISTRADOR")  // Adiciona "ROLE_" automaticamente
.requestMatchers("/secretaria/**").hasRole("SECRETARIA")
.requestMatchers("/professor/**").hasRole("PROFESSOR")

// AgendamentoController.java linha 42
@PreAuthorize("hasAnyAuthority('ADMINISTRADOR', 'SECRETARIA', 'PROFESSOR')")  // SEM prefixo
```

**Verificar em `JwtAuthFilter.java` linha 60-62:**
```java
String role = jwtUtil.extractRole(token);
List<SimpleGrantedAuthority> authorities =
    List.of(new SimpleGrantedAuthority(role));  // Se role = "PROFESSOR", authority = "PROFESSOR"
```

**Impacto:**
- Se o JWT retornar "ROLE_PROFESSOR" mas o `@PreAuthorize` esperar "PROFESSOR", a autorização falhará
- Retornará 403 (Forbidden) mesmo com token válido

**Solução Necessária:**
Garantir consistência:
- Opção 1: Usar `hasRole()` em todos os lugares (Spring adiciona "ROLE_" automaticamente)
- Opção 2: Usar `hasAnyAuthority()` em todos os lugares e garantir que o JWT retorne sem "ROLE_"

---

### 🟡 PROBLEMA POTENCIAL #3: URL Base não Configurada

**Localização:** `frontend/src/provider/api.js` linha 4

**Problema:**
- O frontend usa `import.meta.env.VITE_BASE_URL_API`
- Se essa variável não estiver configurada, a URL base será `undefined`
- A requisição será feita para `undefined/api/agendamentos/...`

**Evidência:**
```javascript
export const api = axios.create({
  baseURL: import.meta.env.VITE_BASE_URL_API,  // Pode ser undefined
  // ...
});
```

**Verificar:**
- Arquivo `.env` ou `.env.local` no frontend
- Variável `VITE_BASE_URL_API` deve estar definida
- Exemplo: `VITE_BASE_URL_API=http://localhost:8080`

**Impacto:**
- Requisições serão feitas para URL incorreta
- Erro: `Network Error` ou `Failed to fetch`

---

### 🟡 PROBLEMA POTENCIAL #4: Token não sendo Enviado Corretamente

**Localização:** `frontend/src/provider/api.js` linha 11-17

**Problema:**
- O interceptor adiciona o token apenas se existir no localStorage
- Se o token não existir ou estiver expirado, a requisição será feita sem autenticação
- O backend retornará 401 (Unauthorized)

**Evidência:**
```javascript
api.interceptors.request.use((config) => {
  const token = localStorage.getItem("token");
  if (token) {  // Se token não existir, não adiciona header
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

**Verificar:**
- Console do navegador: verificar se o token existe no localStorage
- Network tab: verificar se o header `Authorization: Bearer <token>` está sendo enviado
- Se o token estiver expirado, o backend retornará 401

**Impacto:**
- Requisições sem token retornarão 401
- O interceptor de resposta redirecionará para `/login`

---

### 🟡 PROBLEMA POTENCIAL #5: User.id pode ser null ou undefined

**Localização:** `frontend/src/app/features/Teacher/Calendar/model.jsx` linha 36-37

**Problema:**
- Se `user` for `null` ou `user.id` for `undefined`, a URL será `/api/agendamentos/professorId/undefined`
- O backend tentará converter `"undefined"` para `Long` e falhará

**Evidência:**
```javascript
const user = JSON.parse(localStorage.getItem('user'));
const response = await api.get(`/api/agendamentos/professorId/${user.id}`);
// Se user for null ou user.id for undefined, a URL será inválida
```

**Verificar:**
- Console do navegador: verificar o valor de `user` e `user.id`
- Se `user` for `null`, `JSON.parse` lançará erro
- Se `user.id` for `undefined`, a URL será inválida

**Impacto:**
- Erro: `Cannot read property 'id' of null`
- Ou: URL inválida `/api/agendamentos/professorId/undefined`
- Backend retornará 400 (Bad Request) ou 500 (Internal Server Error)

---

## 3. Checklist de Verificação

### 3.1 Verificações no Backend

- [ ] **CORS configurado no SecurityConfig?**
  - ❌ NÃO - Problema crítico identificado
  
- [ ] **Endpoint `/api/agendamentos/professorId/{id}` existe?**
  - ✅ SIM - Endpoint existe e está correto
  
- [ ] **Autorização configurada corretamente?**
  - ⚠️ VERIFICAR - Possível inconsistência entre `hasRole` e `hasAnyAuthority`
  
- [ ] **Método `buscarAgendamentosPorIdProfessor` implementado?**
  - ✅ SIM - Método existe e está correto
  
- [ ] **Repository `findByProfessorId` existe?**
  - ✅ SIM - Método existe com `@EntityGraph`

### 3.2 Verificações no Frontend

- [ ] **Variável `VITE_BASE_URL_API` configurada?**
  - ⚠️ VERIFICAR - Pode não estar configurada
  
- [ ] **Token sendo enviado no header?**
  - ⚠️ VERIFICAR - Depende do localStorage ter token válido
  
- [ ] **User.id existe e tem valor?**
  - ⚠️ VERIFICAR - Pode ser null ou undefined
  
- [ ] **Interceptor de resposta configurado?**
  - ✅ SIM - Interceptor existe e trata 401

---

## 4. Problemas por Prioridade

### 🔴 CRÍTICO - Deve ser corrigido imediatamente

1. **CORS não configurado no SecurityConfig**
   - **Probabilidade:** 90%
   - **Impacto:** Alto - Bloqueia todas as requisições do frontend
   - **Solução:** Adicionar configuração de CORS no `SecurityConfig`

### 🟡 MÉDIO - Pode estar causando o problema

2. **Inconsistência entre hasRole e hasAnyAuthority**
   - **Probabilidade:** 60%
   - **Impacto:** Médio - Pode causar 403 mesmo com token válido
   - **Solução:** Padronizar uso de `hasRole()` ou `hasAnyAuthority()`

3. **URL Base não configurada**
   - **Probabilidade:** 40%
   - **Impacto:** Alto - Requisições para URL incorreta
   - **Solução:** Verificar e configurar `VITE_BASE_URL_API`

4. **Token não sendo enviado ou expirado**
   - **Probabilidade:** 30%
   - **Impacto:** Alto - Retorna 401
   - **Solução:** Verificar localStorage e validade do token

5. **User.id null ou undefined**
   - **Probabilidade:** 20%
   - **Impacto:** Médio - URL inválida
   - **Solução:** Adicionar validação antes de fazer requisição

---

## 5. Como Diagnosticar o Problema Específico

### 5.1 Verificar no Console do Navegador

1. **Abrir DevTools (F12)**
2. **Ir para aba "Console"**
3. **Verificar erros:**
   - `CORS policy: ...` → Problema de CORS
   - `Network Error` → URL base incorreta ou servidor offline
   - `401 Unauthorized` → Token inválido ou não enviado
   - `403 Forbidden` → Problema de autorização
   - `Cannot read property 'id' of null` → User.id não existe

### 5.2 Verificar na Aba Network

1. **Abrir DevTools (F12)**
2. **Ir para aba "Network"**
3. **Fazer a requisição que está falhando**
4. **Verificar:**
   - **Request URL:** Está correta? (ex: `http://localhost:8080/api/agendamentos/professorId/1`)
   - **Request Headers:**
     - `Authorization: Bearer <token>` está presente?
     - `Origin` está correto?
   - **Response Status:** 
     - `200` → Sucesso (mas dados podem estar vazios)
     - `401` → Token inválido ou não enviado
     - `403` → Problema de autorização
     - `404` → Endpoint não encontrado
     - `500` → Erro no servidor
   - **Response Headers:**
     - `Access-Control-Allow-Origin` está presente? (deve estar para CORS funcionar)

### 5.3 Verificar no Backend (Logs)

1. **Verificar logs do Spring Boot:**
   - Requisição chegou ao controller?
   - Erro de autenticação/autorização?
   - Erro no service/repository?

2. **Verificar logs do AgendamentoService:**
   - `logger.debug("Buscando agendamentos para professor ID: {}")` aparece?
   - `logger.debug("Encontrados {} agendamentos")` aparece?

---

## 6. Soluções Recomendadas (em ordem de prioridade)

### Solução 1: Adicionar CORS no SecurityConfig (CRÍTICO)

**Arquivo:** `backend/agendamento/src/main/java/com/onePilates/agendamento/config/SecurityConfig.java`

**Adicionar:**
```java
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.Arrays;

@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOrigins(Arrays.asList("*")); // Em produção, usar origens específicas
    configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
    configuration.setAllowedHeaders(Arrays.asList("*"));
    configuration.setAllowCredentials(true);
    configuration.setMaxAge(3600L);
    
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
}

// No método securityFilterChain, adicionar:
http
    .cors(cors -> cors.configurationSource(corsConfigurationSource()))
    .csrf(csrf -> csrf.disable())
    // ... resto
```

### Solução 2: Padronizar Autorização (MÉDIO)

**Opção A - Usar hasRole em todos os lugares:**
```java
// AgendamentoController.java
@PreAuthorize("hasAnyRole('ADMINISTRADOR', 'SECRETARIA', 'PROFESSOR')")
```

**Opção B - Garantir que JWT retorne role sem prefixo:**
```java
// JwtAuthFilter.java - Garantir que role não tenha "ROLE_"
String role = jwtUtil.extractRole(token);
// Se role = "ROLE_PROFESSOR", remover prefixo:
if (role.startsWith("ROLE_")) {
    role = role.substring(5);
}
```

### Solução 3: Verificar Configuração do Frontend (MÉDIO)

**Criar/verificar arquivo `.env` no frontend:**
```env
VITE_BASE_URL_API=http://localhost:8080
```

**Ou verificar se está em `.env.local` ou `.env.production`**

### Solução 4: Adicionar Validação no Frontend (BAIXO)

**Arquivo:** `frontend/src/app/features/Teacher/Calendar/model.jsx`

**Adicionar validação:**
```javascript
async function fetchAgendamentos() {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    
    // VALIDAÇÃO ADICIONADA
    if (!user || !user.id) {
      console.error('User ou user.id não encontrado');
      setAgendamentos([]);
      setIsLoading(false);
      return;
    }
    
    const response = await api.get(`/api/agendamentos/professorId/${user.id}`);
    setAgendamentos(Array.isArray(response.data) ? response.data : []);
  } catch (error) {
    console.error('Erro ao buscar agendamentos:', error);
    console.error('Detalhes do erro:', error.response); // ADICIONAR para debug
    setAgendamentos([]);
  } finally {
    setIsLoading(false);
  }
}
```

---

## 7. Testes de Verificação

### Teste 1: Verificar CORS
```bash
# No terminal, testar requisição CORS:
curl -X OPTIONS http://localhost:8080/api/agendamentos/professorId/1 \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: GET" \
  -v
```

**Resultado esperado:**
- Headers `Access-Control-Allow-Origin`, `Access-Control-Allow-Methods` devem estar presentes

### Teste 2: Verificar Endpoint com Token
```bash
# Obter token do login primeiro, depois:
curl -X GET http://localhost:8080/api/agendamentos/professorId/1 \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -v
```

**Resultado esperado:**
- Status 200 com lista de agendamentos
- Ou status 401/403 se token inválido

### Teste 3: Verificar no Navegador
1. Abrir DevTools (F12)
2. Ir para Console
3. Executar:
```javascript
// Verificar se user existe
const user = JSON.parse(localStorage.getItem('user'));
console.log('User:', user);
console.log('User ID:', user?.id);

// Verificar se token existe
const token = localStorage.getItem('token');
console.log('Token existe:', !!token);
console.log('Token:', token?.substring(0, 20) + '...');

// Verificar URL base
console.log('Base URL:', import.meta.env.VITE_BASE_URL_API);
```

---

## 8. Resumo Executivo

### Problema Mais Provável
**CORS não configurado no SecurityConfig** (90% de probabilidade)

### Ação Imediata Recomendada
1. Adicionar configuração de CORS no `SecurityConfig.java`
2. Testar requisição do frontend
3. Se ainda falhar, verificar logs do backend e console do navegador

### Próximos Passos
1. Verificar se variável `VITE_BASE_URL_API` está configurada
2. Verificar se token está sendo enviado corretamente
3. Verificar se `user.id` existe e tem valor válido
4. Padronizar uso de `hasRole` vs `hasAnyAuthority`

---

## 9. Informações Técnicas Adicionais

### Estrutura da Requisição Esperada

**Request:**
```
GET /api/agendamentos/professorId/1
Headers:
  Authorization: Bearer <jwt_token>
  Content-Type: application/json
  Origin: http://localhost:5173 (ou URL do frontend)
```

**Response (Sucesso):**
```
Status: 200 OK
Headers:
  Access-Control-Allow-Origin: *
  Content-Type: application/json
Body:
  [
    {
      "id": 1,
      "dataHora": "2024-11-20T10:00:00",
      "professor": {...},
      "sala": {...},
      "especialidade": {...},
      "alunos": [...]
    }
  ]
```

**Response (Erro):**
```
Status: 401 Unauthorized
ou
Status: 403 Forbidden
ou
Status: 500 Internal Server Error
```

---

**Data do Diagnóstico:** 2024-11-15
**Versão do Backend:** Spring Boot 3.2.5
**Versão do Frontend:** React + Vite

