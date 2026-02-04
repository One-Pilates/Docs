# 🔒 Solução para Erro 403 (Forbidden)

## ✅ **Correções Aplicadas:**

1. ✅ Ajustado `SecurityConfig` para permitir acesso ao endpoint `/api/imagens/**`
2. ✅ Alterado `@PreAuthorize` para `isAuthenticated()` (aceita qualquer role autenticada)

---

## 🔍 **Possíveis Causas do Erro 403:**

### **1. Token JWT Expirado** ⚠️ (Mais Provável)

O token que você está usando pode ter expirado. Tokens JWT têm um tempo de expiração.

**Como verificar:**
- O token fornecido tem expiração em: `1763497967` (timestamp Unix)
- Isso corresponde a uma data no passado se o token foi gerado há muito tempo

**Solução:**
1. Faça login novamente para obter um novo token
2. Use o endpoint de autenticação para gerar um novo token

---

## 🛠️ **Soluções Passo a Passo:**

### **Solução 1: Obter Novo Token**

**Requisição no Postman:**

```
POST http://localhost:8080/auth/login

Body (JSON):
{
  "email": "admin@onepilates.com",
  "senha": "sua_senha"
}
```

**Resposta:**
```json
{
  "token": "novo_token_aqui"
}
```

**Use o novo token no header:**
```
Authorization: Bearer {novo_token}
```

---

### **Solução 2: Verificar se o Token Está Válido**

Teste primeiro a requisição de buscar professor:

```
GET http://localhost:8080/api/professores/3

Headers:
Authorization: Bearer {seu_token}
```

**Se esta requisição funcionar:**
- O token está válido
- O problema pode ser com o padrão de URL do endpoint de imagens

**Se esta requisição também der 403:**
- O token está expirado ou inválido
- Obtenha um novo token (Solução 1)

---

### **Solução 3: Testar Endpoint de Imagens com Novo Token**

Após obter um novo token válido:

```
GET http://localhost:8080/api/imagens/imagens/professor_3_1234567890.jpg

Headers:
Authorization: Bearer {novo_token_valido}
```

---

## 📝 **Checklist de Diagnóstico:**

- [ ] Token JWT está válido? (teste com GET /api/professores/3)
- [ ] Header `Authorization` está no formato correto? (`Bearer {token}`)
- [ ] O caminho da imagem está correto? (copiado do campo `foto`)
- [ ] Backend está rodando na porta 8080?
- [ ] O arquivo de imagem existe na pasta `imagens/`?

---

## 🔄 **Passos para Testar Agora:**

1. **Obtenha um novo token:**
   ```
   POST http://localhost:8080/auth/login
   Body: {"email": "admin@onepilates.com", "senha": "sua_senha"}
   ```

2. **Teste buscar professor:**
   ```
   GET http://localhost:8080/api/professores/3
   Headers: Authorization: Bearer {novo_token}
   ```

3. **Copie o campo `foto` da resposta**

4. **Teste visualizar imagem:**
   ```
   GET http://localhost:8080/api/imagens/{caminho_completo_da_foto}
   Headers: Authorization: Bearer {novo_token}
   ```

---

## 💡 **Dica:**

Se continuar com erro 403 mesmo com token válido, verifique:
- Se o backend foi reiniciado após as alterações no código
- Se há logs de erro no console do backend
- Se o arquivo de imagem realmente existe no caminho especificado

---

## 🆘 **Se Nada Funcionar:**

1. Verifique os logs do backend para ver a mensagem de erro exata
2. Teste se outros endpoints autenticados funcionam
3. Verifique se o arquivo de imagem existe: `backend/agendamento/imagens/professor_3_*.jpg`

