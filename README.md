# Boo CLI

Boo CLI é um assistente de terminal em Ruby que interpreta comandos em linguagem natural e os transforma em comandos do seu Linux/macOS.
Ele permite executar tarefas comuns como listar pastas, commitar código, gerenciar processos ou abrir aplicativos, apenas descrevendo o que deseja fazer, sem precisar decorar comandos complexos.

## Funcionalidades

- Traduz instruções em linguagem natural para comandos shell.
- Funciona com Gemini, OpenAI, Anthropic (Claude) ou DeepSeek — você escolhe.
- Pergunta o provedor e a chave de API na primeira execução, se não houver nada configurado.
- Suporta ferramentas como `ls`, `git` e gerenciamento de processos.
- Mostra o plano de ação antes de executar e solicita confirmação.
- Bloqueia comandos perigosos via regras de segurança.

## Pré-requisitos

- Ruby 3.x
- Bundler
- Uma chave de API de um dos provedores suportados (Gemini, OpenAI, Anthropic ou DeepSeek)

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
3. Configure o provedor e a chave de API:

Na primeira execução, se nenhuma chave for encontrada, o Boo pergunta qual modelo você quer usar e pede a chave (digitada sem eco na tela):

```
👻 Qual modelo de IA você quer usar?
  1) Google Gemini
  2) OpenAI
  3) Anthropic (Claude)
  4) DeepSeek
Escolha [1-4]: 3
🔑 Informe a chave de API do Anthropic (Claude) (https://console.anthropic.com/settings/keys)
ANTHROPIC_API_KEY:
💾 Salvar em /caminho/boo-cli/.env? (s/N): s
✅ Conectado ao Anthropic (Claude) — modelo: claude-sonnet-5
```

Se você responder `s`, a chave e o provedor escolhido são gravados no `.env` (permissão `600`) e nas próximas execuções nada é perguntado.

Você também pode configurar tudo manualmente, por variável de ambiente ou pelo `.env` na raiz do projeto:

```
BOO_PROVIDER=anthropic
ANTHROPIC_API_KEY=sua_chave_aqui
```

### Provedores suportados

| Provedor | `BOO_PROVIDER` | Variável da chave | Modelo padrão | Onde gerar a chave |
| --- | --- | --- | --- | --- |
| Google Gemini | `gemini` | `GEMINI_API_KEY` | `gemini-3.1-flash` | https://aistudio.google.com/apikey |
| OpenAI | `openai` | `OPENAI_API_KEY` | `gpt-4.1-mini` | https://platform.openai.com/api-keys |
| Anthropic (Claude) | `anthropic` | `ANTHROPIC_API_KEY` | `claude-sonnet-5` | https://console.anthropic.com/settings/keys |
| DeepSeek | `deepseek` | `DEEPSEEK_API_KEY` | `deepseek-chat` | https://platform.deepseek.com/api_keys |

### Variáveis de ambiente

- `BOO_PROVIDER` — provedor a usar. Se não estiver definida e existir apenas **uma** chave de API no ambiente, o Boo usa aquele provedor automaticamente. Se houver mais de uma (ou nenhuma), ele pergunta.
- `BOO_MODEL` — sobrescreve o modelo padrão do provedor. Ex.: `BOO_MODEL=claude-opus-5`.
- `<PROVEDOR>_API_KEY` — a chave, conforme a tabela acima.

Fora de um terminal interativo (pipe, CI), o Boo não fica esperando input: ele avisa quais variáveis definir e sai com código `1`.

## Uso

Você pode rodar o Boo CLI de duas formas:

1. Direto com Ruby:
```
ruby boo.rb "liste as pastas do diretório /tmp"
```

2. Criando um alias para facilitar no terminal:
```
alias boo="ruby /caminho/boo-cli/boo.rb"
source ~/.bashrc   # ou ~/.zshrc
boo "commite todo o código com uma mensagem útil"
```

Para trocar de provedor ou de modelo em uma execução pontual, use as variáveis de ambiente:
```
BOO_PROVIDER=openai boo "liste as pastas do diretório /tmp"
BOO_MODEL=claude-opus-5 boo "mostre os processos rodando"
```

## Segurança

- Comandos potencialmente perigosos (como rm -rf /) são bloqueados automaticamente.

- Antes de executar qualquer comando, o Boo CLI pede confirmação do usuário.

- A chave de API nunca é exibida na tela ao ser digitada, e o `.env` é gravado com permissão `600`. Mantenha o `.env` fora do controle de versão (já está no `.gitignore`).

## Exemplos
```
boo "liste todas as pastas do diretório /tmp"
boo "commite todo esse código com uma descrição útil"
boo "mate a porta 3000"
```