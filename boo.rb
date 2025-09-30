require_relative "lib/config"
require_relative "lib/cli"
require_relative "lib/boo/error"

if ARGV.empty?
  puts "📖 Uso: boo \"seu comando em linguagem natural\""
  exit 1
end

begin
  client = Boo::Config.setup_gemini
  cli = Boo::CLI.new(client)

  command_data = cli.parse_command(ARGV.join(" "))
  cli.execute_safely(command_data["command"], command_data["description"])
rescue JSON::ParserError => e
  warn "❌ Erro ao interpretar resposta do Gemini: #{e.message}"
  exit 1
rescue => e
  warn "❌ Erro inesperado: #{e.message}"
  exit 1
end
