require "ruby_llm"
require "dotenv/load"

module Boo
  class Config
    def self.setup_gemini
      validate_api_key!
      configure_ruby_llm!
      create_client_instance
    end

    private

    def self.validate_api_key!
      if ENV['GEMINI_API_KEY'].nil? || ENV['GEMINI_API_KEY'].empty?
        puts "⚠️ GEMINI_API_KEY não encontrada no arquivo .env"
        exit 1
      end
    end

    def self.configure_ruby_llm!
      RubyLLM.configure do |config|
        config.gemini_api_key = ENV['GEMINI_API_KEY']
        config.default_model =  "gemini-2.5-flash"
      end
    rescue => e
      puts "❌ Erro ao configurar RubyLLM: #{e.message}"
      exit 1
    end

    def self.create_client_instance
      chat = RubyLLM.chat
      puts "✅ Conectado ao modelo: Gemini 2.5 Flash"
      chat
    rescue => error
      puts "❌ Erro ao conectar com Gemini: #{error.message}"
      exit 1
    end
  end
end
