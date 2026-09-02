require "ruby_llm"
require "dotenv/load"
require "io/console"
require_relative "boo/error"

module Boo
  class Config
    ENV_FILE = File.expand_path("../.env", __dir__)

    PROVIDER_ENV = "BOO_PROVIDER".freeze
    MODEL_ENV    = "BOO_MODEL".freeze

    PROVIDERS = {
      "gemini" => {
        label:         "Google Gemini",
        env_key:       "GEMINI_API_KEY",
        config_key:    :gemini_api_key,
        default_model: "gemini-3.1-flash",
        keys_url:      "https://aistudio.google.com/apikey"
      },
      "openai" => {
        label:         "OpenAI",
        env_key:       "OPENAI_API_KEY",
        config_key:    :openai_api_key,
        default_model: "gpt-4.1-mini",
        keys_url:      "https://platform.openai.com/api-keys"
      },
      "anthropic" => {
        label:         "Anthropic (Claude)",
        env_key:       "ANTHROPIC_API_KEY",
        config_key:    :anthropic_api_key,
        default_model: "claude-sonnet-5",
        keys_url:      "https://console.anthropic.com/settings/keys"
      },
      "deepseek" => {
        label:         "DeepSeek",
        env_key:       "DEEPSEEK_API_KEY",
        config_key:    :deepseek_api_key,
        default_model: "deepseek-chat",
        keys_url:      "https://platform.deepseek.com/api_keys"
      }
    }.freeze

    def self.setup
      provider = resolve_provider
      api_key  = resolve_api_key(provider)
      model    = resolve_model(provider)

      configure_ruby_llm!(provider, api_key, model)
      create_client_instance(provider, model)
    end

    def self.provider_settings(provider)
      PROVIDERS.fetch(provider)
    end

    def self.resolve_provider
      from_env = ENV[PROVIDER_ENV].to_s.strip.downcase
      return from_env if PROVIDERS.key?(from_env)

      unless from_env.empty?
        puts "⚠️ Provedor \"#{from_env}\" em #{PROVIDER_ENV} é inválido. Opções: #{PROVIDERS.keys.join(', ')}"
      end

      configured = PROVIDERS.keys.select { |key| present?(ENV[PROVIDERS[key][:env_key]]) }
      return configured.first if configured.size == 1

      ask_provider(configured)
    end

    def self.ask_provider(configured = [])
      require_interactive!("Nenhuma chave de API encontrada e o terminal não é interativo.")

      puts "👻 Qual modelo de IA você quer usar?"
      keys = PROVIDERS.keys
      keys.each_with_index do |key, index|
        marker = configured.include?(key) ? " (chave já configurada)" : ""
        puts "  #{index + 1}) #{PROVIDERS[key][:label]}#{marker}"
      end

      loop do
        print "Escolha [1-#{keys.size}]: "
        answer = $stdin.gets
        raise Boo::Error, "Entrada encerrada. Nenhum provedor selecionado." if answer.nil?

        answer = answer.strip.downcase
        return answer if PROVIDERS.key?(answer)

        index = Integer(answer, exception: false)
        return keys[index - 1] if index && index.between?(1, keys.size)

        puts "❌ Opção inválida."
      end
    end


    def self.resolve_api_key(provider)
      settings = provider_settings(provider)
      key = ENV[settings[:env_key]]
      return key.strip if present?(key)

      ask_api_key(provider)
    end

    def self.ask_api_key(provider)
      settings = provider_settings(provider)
      require_interactive!("#{settings[:env_key]} não encontrada e o terminal não é interativo.")

      puts "🔑 Informe a chave de API do #{settings[:label]} (#{settings[:keys_url]})"

      key = read_secret("#{settings[:env_key]}: ")
      raise Boo::Error, "Chave de API vazia para #{settings[:label]}." unless present?(key)

      ENV[settings[:env_key]] = key
      offer_to_persist(provider, key)
      key
    end

    def self.read_secret(prompt)
      print prompt
      value =
        if $stdin.respond_to?(:noecho) && $stdin.tty?
          begin
            $stdin.noecho(&:gets).tap { puts }
          rescue IOError, Errno::EBADF
            $stdin.gets
          end
        else
          $stdin.gets
        end

      value.to_s.strip
    end

    def self.offer_to_persist(provider, api_key)
      settings = provider_settings(provider)
      print "💾 Salvar em #{ENV_FILE}? (s/N): "
      answer = $stdin.gets
      return unless answer&.strip&.downcase == "s"

      write_env!(settings[:env_key] => api_key, PROVIDER_ENV => provider)
      puts "✅ Salvo em #{ENV_FILE}"
    rescue => e
      warn "⚠️ Não foi possível salvar o .env: #{e.message}"
    end

    def self.write_env!(pairs)
      lines = File.exist?(ENV_FILE) ? File.readlines(ENV_FILE, chomp: true) : []

      pairs.each do |name, value|
        entry = "#{name}=#{value}"
        index = lines.index { |line| line.start_with?("#{name}=") }
        index ? lines[index] = entry : lines << entry
      end

      File.write(ENV_FILE, lines.join("\n") + "\n")
      File.chmod(0o600, ENV_FILE)
    end


    def self.resolve_model(provider)
      model = ENV[MODEL_ENV].to_s.strip
      model.empty? ? provider_settings(provider)[:default_model] : model
    end


    def self.configure_ruby_llm!(provider, api_key, model)
      settings = provider_settings(provider)

      RubyLLM.configure do |config|
        config.public_send("#{settings[:config_key]}=", api_key)
        config.default_model = model
      end
    rescue => e
      puts "❌ Erro ao configurar RubyLLM: #{e.message}"
      exit 1
    end

    def self.create_client_instance(provider, model)
      settings = provider_settings(provider)
      chat = RubyLLM.chat(model: model, provider: provider.to_sym)
      puts "✅ Conectado ao #{settings[:label]} — modelo: #{model}"
      chat
    rescue => error
      puts "❌ Erro ao conectar com #{settings[:label]}: #{error.message}"
      exit 1
    end

    def self.present?(value)
      !value.nil? && !value.to_s.strip.empty?
    end

    def self.require_interactive!(message)
      return if $stdin.tty?

      puts "⚠️ #{message}"
      puts "   Defina #{PROVIDERS.values.map { |s| s[:env_key] }.join(' ou ')} no .env, ou rode em um terminal interativo."
      exit 1
    end

    private_class_method :resolve_provider, :ask_provider, :resolve_api_key,
                         :ask_api_key, :read_secret, :offer_to_persist,
                         :write_env!, :resolve_model, :configure_ruby_llm!,
                         :create_client_instance, :present?, :require_interactive!
  end
end
