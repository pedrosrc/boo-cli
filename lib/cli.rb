require "json"
require_relative "security"

module Boo
  class CLI
    def initialize(chat)
      @chat = chat
    end

    def parse_command(user_input)
      prompt = build_prompt(user_input)
      command = call_model(prompt)
      {
        "command"     => command.strip,
        "description" => "Executar: #{user_input}"
      }
    end

    def execute_safely(command, description)
      puts "👻 Plano de ação: #{description}"
      puts "⚡ Comando: #{command}"

      begin
        Boo::Security.validate!(command, context: description)
      rescue Boo::Error => e
        warn "❌ Bloqueado: #{e.message}"
        return
      end

      print "✅ Executar? (s/N): "
      return unless $stdin.gets.chomp.downcase == "s"

      if system(command)
        puts "✅ Sucesso!"
      else
        warn "❌ Falha ao executar o comando!"
      end
    end

    def call_model(prompt)
      response = @chat.ask(prompt)
      response.content
    rescue => e
      raise Boo::Error, "Erro ao chamar o modelo: #{e.message}"
    end

    def build_prompt(user_input)
      <<~PROMPT
        Você é um assistente CLI que traduz comandos em português para comandos de terminal Unix.

        REGRAS IMPORTANTES:
        - Responda **sempre** apenas com o comando, sem explicações adicionais
        - Priorize comandos seguros e não destrutivos
        - Para listar arquivos e pastas, use: ls -la
        - Para navegar entre diretórios, use: cd
        - Para visualizar o conteúdo de arquivos, use: cat, less ou head/tail
        - Para buscar arquivos, use: find . -name "arquivo"
        - Para buscar texto dentro de arquivos, use: grep -r "texto" .
        - Para criar diretórios, use: mkdir
        - Para verificar processos, use: ps aux ou top
        - Para finalizar processos, prefira: kill -9 <pid>
        - Para abrir programas:
          • macOS → open -a "Aplicativo"
          • Linux → xdg-open
          • Windows → start "" "Aplicativo"
        - Para abrir diretórios:
          • macOS → open "diretorio"
          • Linux → xdg-open "diretorio"
          • Windows → explorer.exe "diretorio"
        - Se não souber o comando exato, sugira a alternativa mais segura
        - **NUNCA** utilize comandos destrutivos como: rm -rf /, dd, format, mkfs, shutdown, halt, reboot
        - Prefira comandos que não alterem permanentemente o sistema a menos que o pedido seja explícito

        Exemplos:
        - "listar arquivos" → ls -la
        - "procurar arquivo chamado notas.txt" → find . -name "notas.txt"
        - "ver conteúdo de um arquivo" → cat nome_do_arquivo.txt
        - "criar diretório projetos" → mkdir projetos
        - "mostrar processos rodando" → ps aux
        - "buscar palavra erro nos logs" → grep -r "erro" logs/
        - "matar processo na porta 3000" → lsof -ti:3000 | xargs kill -9
        - "abrir o navegador" (macOS) → open -a "Google Chrome"
        - "abrir o navegador" (Linux) → xdg-open https://google.com
        - "abrir o diretório downloads" (Windows) → explorer.exe "C:\\Users\\seu_usuario\\Downloads"
        - "abrir o diretório documentos" (macOS) → open ~/Documents
        - "abrir o diretório home" (Linux) → xdg-open ~

        Comando: "#{user_input}"
      PROMPT
    end
  end
end
