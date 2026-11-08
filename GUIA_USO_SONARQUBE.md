# 🎯 Guia de Configuração e Uso do SonarQube

## 📋 O que é o SonarQube?

O **SonarQube** é a principal plataforma de inspeção contínua de qualidade de código e segurança. Ele analisa estaticamente o código-fonte para detectar:
- 🐞 **Bugs**: Problemas no código que causarão comportamentos erráticos ou falhas em runtime.
- 🛡️ **Vulnerabilidades & Security Hotspots**: Falhas de segurança como SQL Injection, criptografia fraca e exposição de dados sensíveis.
- 💨 **Code Smells**: Débito técnico, código redundante, complexidade ciclomática excessiva e violações de boas práticas.
- 📊 **Cobertura de Código**: Integração direta com os relatórios gerados pelo **JaCoCo** (`jacoco.xml`).
- 👥 **Duplicações**: Blocos de código repetidos que deveriam ser refatorados.

---

## 🚀 Como Iniciar o Servidor SonarQube

O SonarQube pode ser executado facilmente via Docker ou utilizando a versão em nuvem (SonarCloud).

### Opção 1: Via Docker Compose (Recomendado)

Na raiz do projeto ou na pasta `Docker/SonarQube/`:

```bash
docker compose -f docker-compose-sonarqube.yml up -d
```

Ou no diretório de containers:
```bash
cd Docker/SonarQube
docker compose up -d
```

### Opção 2: Via Docker puro

```bash
docker run -d --name sonarqube-onepilates -p 9000:9000 sonarqube:community
```

O SonarQube estará disponível em:
👉 **http://localhost:9000**  
*(Login padrão: `admin` | Senha padrão: `admin` — o sistema pedirá para cadastrar uma nova senha no primeiro acesso)*.

---

## ⚡ Como Rodar a Análise no Backend

### 1. Utilizando o Script Automático (PowerShell)

Criamos um utilitário em `Backend/agendamento/run-sonar.ps1` que configura automaticamente o Java 21 (Corretto), verifica se o SonarQube está online e roda a suíte de testes com JaCoCo + Sonar:

```powershell
cd "Backend\agendamento"
.\run-sonar.ps1
```

Se você gerou um token no SonarQube:
```powershell
.\run-sonar.ps1 -SonarToken "seu_token_aqui"
```

Para rodar apontando para um SonarQube remoto ou SonarCloud:
```powershell
.\run-sonar.ps1 -SonarHost "https://sonarcloud.io" -SonarToken "seu_token"
```

### 2. Manualmente via Maven Wrapper

Caso prefira executar diretamente via terminal:

```bash
cd Backend/agendamento

# 1. Certifique-se de estar usando JDK 21
# 2. Executar testes, JaCoCo e enviar análise ao SonarQube:
./mvnw clean verify sonar:sonar -Dsonar.host.url=http://localhost:9000
```

Se gerou token:
```bash
./mvnw clean verify sonar:sonar -Dsonar.host.url=http://localhost:9000 -Dsonar.token=seu_token
```

---

## ⚙️ Configurações Aplicadas no `pom.xml`

As propriedades já estão pré-configuradas no `pom.xml` da aplicação:

```xml
<properties>
    <sonar.projectKey>OnePilates_Backend</sonar.projectKey>
    <sonar.projectName>OnePilates Backend - Agendamento</sonar.projectName>
    <sonar.host.url>http://localhost:9000</sonar.host.url>
    <sonar.java.coveragePlugin>jacoco</sonar.java.coveragePlugin>
    <sonar.coverage.jacoco.xmlReportPaths>${project.basedir}/target/site/jacoco/jacoco.xml</sonar.coverage.jacoco.xmlReportPaths>
    <sonar.coverage.exclusions>
        **/dto/**,
        **/entity/**,
        **/model/**,
        **/config/**,
        **/exception/**,
        **/enums/**,
        **/AgendamentoApplication.java
    </sonar.coverage.exclusions>
    <sonar.exclusions>
        **/target/**,
        **/*.xml,
        **/*.yml,
        **/*.yaml
    </sonar.exclusions>
</properties>
```

---

## 🌐 Integração Contínua (CI / GitHub Actions)

O repositório já inclui a pipeline pronta em `.github/workflows/sonar.yml`:
- Executa a cada `push` e `pull request` nas branches principais e de features (`feat/**`).
- Roda os testes com JDK 21 Corretto.
- Gera o relatório JaCoCo e envia automaticamente ao SonarCloud/SonarQube.

### Secrets Necessários no GitHub:
1. `SONAR_TOKEN`: Token de autenticação gerado no SonarQube / SonarCloud.
2. `SONAR_HOST_URL` *(opcional, se não usar SonarCloud)*: URL do seu servidor SonarQube.

