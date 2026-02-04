# Configuração de Banco de Dados para Testes

## Como o Spring Boot Seleciona o Banco de Dados

### 1. Ordem de Precedência das Configurações

O Spring Boot segue uma ordem específica para carregar configurações:

1. **`@TestPropertySource`** (maior prioridade)
   - Configurações definidas diretamente no teste
   - Exemplo: `@TestPropertySource(locations = "classpath:application-test.properties")`

2. **`application-{profile}.properties`**
   - Arquivos específicos do perfil ativo
   - Exemplo: `application-test.properties` quando `@ActiveProfiles("test")` está ativo

3. **`application.properties`** (menor prioridade)
   - Arquivo de configuração padrão
   - Usado quando nenhuma configuração específica é encontrada

### 2. Configuração Atual do Projeto

#### Para Testes (H2 em Memória)

**Arquivo:** `src/test/resources/application-test.properties`

```properties
# Configurações para testes
spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE;MODE=MySQL
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create
spring.jpa.show-sql=true
```

**Como é ativado:**
- `@ActiveProfiles("test")` no teste ativa o perfil "test"
- `@TestPropertySource(locations = "classpath:application-test.properties")` carrega o arquivo de configuração
- O Spring Boot usa **H2** porque a URL do H2 está definida no arquivo de teste

#### Para Produção/Desenvolvimento (MySQL)

**Arquivo:** `src/main/resources/application.properties`

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/onePilates?useSSL=false&serverTimezone=UTC
spring.datasource.username=root
spring.datasource.password=#Gf1540092a215434
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.jpa.hibernate.ddl-auto=update
```

**Como é ativado:**
- Quando o perfil "test" **não** está ativo
- O Spring Boot usa **MySQL** porque a URL do MySQL está definida no arquivo principal

### 3. Por que o H2 é Usado nos Testes?

1. **Isolamento**: Cada teste executa em um banco de dados isolado em memória
2. **Performance**: H2 é muito mais rápido que MySQL para testes
3. **Simplicidade**: Não requer configuração de servidor de banco de dados
4. **Portabilidade**: Funciona em qualquer ambiente sem dependências externas

### 4. Problema Encontrado e Solução

#### Problema
O Hibernate não estava criando as tabelas antes do `@BeforeEach` executar, causando o erro:
```
Table "FUNCIONARIO" not found (this database is empty)
```

#### Causa
O Hibernate só cria o schema quando o `EntityManagerFactory` é inicializado, mas isso pode não acontecer antes do `@BeforeEach` executar.

#### Solução Aplicada

1. **Mudança de `create-drop` para `create`**:
   - `create-drop`: Cria e depois remove o schema (pode causar problemas de timing)
   - `create`: Cria o schema e mantém durante o teste

2. **Configurações adicionais**:
   ```properties
   spring.jpa.hibernate.ddl-auto=create
   spring.jpa.properties.hibernate.hbm2ddl.auto=create
   spring.jpa.properties.hibernate.hbm2ddl.create_namespaces=true
   ```

3. **URL do H2 ajustada**:
   ```properties
   spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE;MODE=MySQL
   ```
   - `DB_CLOSE_DELAY=-1`: Mantém o banco em memória mesmo após fechar conexões
   - `MODE=MySQL`: Simula comportamento do MySQL para compatibilidade

### 5. Verificação da Configuração

Para verificar qual banco está sendo usado:

1. **Verificar logs do Spring Boot**:
   ```
   Hibernate: create table funcionario ...
   ```
   - Se aparecer `Hibernate:`, está usando H2 (configurado para mostrar SQL)
   - Se aparecer `MySQL`, está usando MySQL

2. **Verificar URL de conexão**:
   - H2: `jdbc:h2:mem:testdb`
   - MySQL: `jdbc:mysql://localhost:3306/onePilates`

3. **Verificar perfil ativo**:
   - Nos logs: `The following profiles are active: test`
   - No código: `@ActiveProfiles("test")`

### 6. Boas Práticas

1. **Sempre usar `@ActiveProfiles("test")`** em testes de integração
2. **Criar `application-test.properties`** separado para configurações de teste
3. **Usar H2 em memória** para testes (não MySQL)
4. **Configurar `ddl-auto=create`** para criar schema automaticamente
5. **Não usar `@Transactional`** no `@BeforeEach` se não for necessário (pode interferir na criação do schema)

### 7. Troubleshooting

#### Se o teste ainda falhar com "Table not found":

1. **Verificar se o perfil está ativo**:
   ```java
   @ActiveProfiles("test")
   ```

2. **Verificar se o arquivo de configuração está no lugar certo**:
   - `src/test/resources/application-test.properties`

3. **Verificar se as dependências estão corretas**:
   ```xml
   <dependency>
       <groupId>com.h2database</groupId>
       <artifactId>h2</artifactId>
       <scope>runtime</scope>
   </dependency>
   ```

4. **Limpar e recompilar**:
   ```bash
   mvn clean test
   ```

5. **Verificar logs do Hibernate**:
   - Se não aparecer `create table`, o schema não está sendo criado
   - Verificar se `spring.jpa.show-sql=true` está configurado

