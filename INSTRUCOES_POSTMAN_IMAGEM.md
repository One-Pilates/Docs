# 📸 Como Testar Visualização de Imagem no Postman

## 🎯 Requisições para Professor ID 3

### **Token JWT (já configurado):**
```
eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbkBvbmVwaWxhdGVzLmNvbSIsInJvbGUiOiJBRE1JTklTVFJBRE9SIiwiaWF0IjoxNzYzNDExNTY3LCJleHAiOjE3NjM0OTc5Njd9.nLBDj1aliBZaf7d6hna5wFhMlopy78eqaCpcFNA8eCs
```

---

## 📋 **PASSO 1: Buscar Dados do Professor (obter caminho da foto)**

### Configuração da Requisição:

**Método:** `GET`

**URL:**
```
http://localhost:8080/api/professores/3
```

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbkBvbmVwaWxhdGVzLmNvbSIsInJvbGUiOiJBRE1JTklTVFJBRE9SIiwiaWF0IjoxNzYzNDExNTY3LCJleHAiOjE3NjM0OTc5Njd9.nLBDj1aliBZaf7d6hna5wFhMlopy78eqaCpcFNA8eCs
```

**Como fazer no Postman:**
1. Crie uma nova requisição
2. Selecione método `GET`
3. Cole a URL acima
4. Vá na aba `Headers`
5. Adicione:
   - Key: `Authorization`
   - Value: `Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbkBvbmVwaWxhdGVzLmNvbSIsInJvbGUiOiJBRE1JTklTVFJBRE9SIiwiaWF0IjoxNzYzNDExNTY3LCJleHAiOjE3NjM0OTc5Njd9.nLBDj1aliBZaf7d6hna5wFhMlopy78eqaCpcFNA8eCs`
6. Clique em `Send`

**Resposta esperada:**
```json
{
  "id": 3,
  "nome": "Nome do Professor",
  "email": "email@exemplo.com",
  "foto": "imagens/professor_3_1234567890.jpg",
  ...
}
```

**⚠️ IMPORTANTE:** Copie o valor do campo `"foto"` (ex: `"imagens/professor_3_1234567890.jpg"`)

---

## 🖼️ **PASSO 2: Visualizar a Imagem**

### Configuração da Requisição:

**Método:** `GET`

**URL:**
```
http://localhost:8080/api/imagens/{CAMINHO_COMPLETO_DA_FOTO}
```

**Substitua `{CAMINHO_COMPLETO_DA_FOTO}` pelo valor copiado no Passo 1**

**Exemplo:**
Se o campo `foto` retornou `"imagens/professor_3_1234567890.jpg"`, a URL será:
```
http://localhost:8080/api/imagens/imagens/professor_3_1234567890.jpg
```

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbkBvbmVwaWxhdGVzLmNvbSIsInJvbGUiOiJBRE1JTklTVFJBRE9SIiwiaWF0IjoxNzYzNDExNTY3LCJleHAiOjE3NjM0OTc5Njd9.nLBDj1aliBZaf7d6hna5wFhMlopy78eqaCpcFNA8eCs
```

**Como fazer no Postman:**
1. Crie uma nova requisição
2. Selecione método `GET`
3. Cole a URL completa (com o caminho da foto)
4. Vá na aba `Headers`
5. Adicione o header `Authorization` com o Bearer token
6. Clique em `Send`
7. **A imagem será exibida na aba "Preview"** do Postman!

**💡 Dica:** Se a imagem não aparecer:
- Verifique se o caminho está correto
- Verifique se o arquivo existe na pasta `imagens/` do backend
- Tente clicar em "Send and Download" para baixar a imagem

---

## 📤 **PASSO 3 (OPCIONAL): Fazer Upload de Nova Foto**

### Configuração da Requisição:

**Método:** `POST`

**URL:**
```
http://localhost:8080/api/professores/3/uploadFoto
```

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbkBvbmVwaWxhdGVzLmNvbSIsInJvbGUiOiJBRE1JTklTVFJBRE9SIiwiaWF0IjoxNzYzNDExNTY3LCJleHAiOjE3NjM0OTc5Njd9.nLBDj1aliBZaf7d6hna5wFhMlopy78eqaCpcFNA8eCs
```

**Body:**
1. Selecione a aba `Body`
2. Escolha `form-data`
3. Adicione um campo:
   - Key: `file` (selecione tipo `File`)
   - Value: Clique em "Select Files" e escolha uma imagem do seu computador

**Como fazer no Postman:**
1. Crie uma nova requisição
2. Selecione método `POST`
3. Cole a URL acima
4. Vá na aba `Headers` e adicione o `Authorization`
5. Vá na aba `Body`
6. Selecione `form-data`
7. Adicione campo `file` do tipo `File`
8. Selecione uma imagem (JPEG, PNG, GIF ou WEBP, máximo 5MB)
9. Clique em `Send`

**Resposta esperada:**
```
Foto salva com sucesso: imagens/professor_3_1234567890.jpg
```

---

## 🔍 **Troubleshooting**

### ❌ Erro 404 (Not Found)
- Verifique se o caminho da imagem está correto
- Verifique se o arquivo existe na pasta `imagens/` do backend
- Certifique-se de que o backend está rodando

### ❌ Erro 401 (Unauthorized)
- Verifique se o token JWT está correto
- Verifique se o token não expirou
- Certifique-se de que o header `Authorization` está no formato: `Bearer {token}`

### ❌ Imagem não aparece no Preview
- Tente clicar em "Send and Download"
- Verifique o tipo de arquivo (deve ser JPEG, PNG, GIF ou WEBP)
- Verifique se o Content-Type está correto na resposta

---

## 📝 **Resumo Rápido**

1. **Buscar professor:** `GET http://localhost:8080/api/professores/3`
2. **Copiar o campo `foto`** da resposta
3. **Visualizar imagem:** `GET http://localhost:8080/api/imagens/{caminho_completo}`
4. **Ver a imagem na aba "Preview"** do Postman

---

## 🎨 **Exemplo Visual da URL**

Se o campo `foto` retornou:
```
"imagens/professor_3_1704115567890.jpg"
```

A URL para visualizar será:
```
http://localhost:8080/api/imagens/imagens/professor_3_1704115567890.jpg
```

**⚠️ ATENÇÃO:** O caminho completo (incluindo "imagens/") deve ser adicionado após `/api/imagens/`

