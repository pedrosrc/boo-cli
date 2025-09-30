# Boo CLI

Boo CLI é um assistente de terminal em Ruby que interpreta comandos em linguagem natural e os transforma em comandos do seu Linux/macOS.
Ele permite executar tarefas comuns como listar pastas, commitar código, gerenciar processos ou abrir aplicativos, apenas descrevendo o que deseja fazer, sem precisar decorar comandos complexos.

## Funcionalidades

- Traduz instruções em linguagem natural para comandos shell.
- Suporta ferramentas como `ls`, `git` e gerenciamento de processos.
- Mostra o plano de ação antes de executar e solicita confirmação.
- Bloqueia comandos perigosos via regras de segurança.

## Pré-requisitos

- Ruby 3.x
- Bundler
- API Key do Gemini (Google AI) para interpretação de linguagem natural

## Instalação

1. Clone o repositório:
```
git clone https://github.com/pedrosrc/boo-cli.git
cd boo-cli
```
2. Instale as dependências:
```
bundle install
```
3. Configure a chave do Gemini:

Via variável de ambiente global:
```
export GEMINI_API_KEY="sua_chave_aqui"
```
Ou via arquivo .env na raiz do projeto:
```
GEMINI_API_KEY=sua_chave_aqui
```
Se usar `.env`, instale a gem dotenv

## Uso

Você pode rodar o Boo CLI de duas formas:

1. Direto com Ruby:
```
ruby boo.rb "liste as pastas do diretório /tmp"
```

2. Criando um alias para facilitar no terminal:
```
alias boo="ruby /caminho/para/boo.rb"
source ~/.bashrc   # ou ~/.zshrc
boo "commite todo o código com uma mensagem útil"
```
## Segurança

- Comandos potencialmente perigosos (como rm -rf /) são bloqueados automaticamente.

- Antes de executar qualquer comando, o Boo CLI pede confirmação do usuário.

## Exemplos
```
boo "liste todas as pastas do diretório /tmp"
boo "commite todo esse código com uma descrição útil"
boo "mate a porta 3000"
```