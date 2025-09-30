require "shellwords"
require "time"

module Boo
  module Security
    LOG_PATH = File.expand_path("~/.boo_security.log")

    BANNED_PATTERNS = [
      /\brm\s+-rf\b/,        # rm -rf
      /\brm\s+\/\b/,         # rm / (explicit)
      /\b(sudo\s+)?rm\s+(-[rf]+\s+)?\//,  # sudo rm
      /\bdd\b/,              # dd
      /\bformat\b/,          # format
      /\bmkfs\b/,            # mkfs
      /\bshutdown\b/,        # shutdown
      /\breboot\b/,          # reboot
      /\bhalt\b/,            # halt
      /\bpoweroff\b/,        # poweroff
      /\binit\s+0\b/,        # init 0
      /\b:>\b/,              # truncate weird ops
      /\btruncate\b/,        # truncate
      /\b>:|\:\>\b/,         # redirection that truncates
      /\bcurl\s+.*\|\s*sh\b/, # download and pipe to sh
      /\bwget\s+.*\|\s*sh\b/, # download and pipe to sh
      /\bbase64\b.*-d\b.*\|\s*sh\b/, # decode and execute
      /\bchmod\s+.*777\b/,   # overly permissive chmod
      /\bkill(all)?\s+(-9\s+)?-1/, # kill -1
      /\bchown\s+root\b/,    # chown to root
      /\bscp\s+.*:/,         # copy to remote (could be sensitive)
    ].freeze

    SAFE_PREFIXES = [
      "ls", "cd", "cat", "less", "head", "tail",
      "find", "grep", "mkdir", "ps", "top", "lsof",
      "open", "xdg-open", "explorer.exe", "start", "git", "kill -9"
    ].freeze

    SENSITIVE_TOKENS = %w[
      install apt yum pacman apk brew pip npm npm install gem install make
      systemctl enable systemctl start systemctl stop service
    ].freeze

    module_function

    def normalize(command)
      command.to_s.strip.gsub(/\s+/, " ").downcase
    end

    def safe?(command)
      cmd = normalize(command)

      return false if cmd.empty?

      return false if BANNED_PATTERNS.any? { |pat| cmd.match?(pat) }
      if SENSITIVE_TOKENS.any? { |t| cmd.include?(t) }
        return SAFE_PREFIXES.any? { |p| cmd.start_with?(p) }
      end

      SAFE_PREFIXES.any? { |p| cmd.start_with?(p) }
    end


    def validate!(command, context: nil)
      cmd = command.to_s
      log_entry = {
        timestamp: Time.now.iso8601,
        command: cmd,
        normalized: normalize(cmd),
        context: context
      }

      unless safe?(cmd)
        log_entry[:result] = "blocked"
        append_log(log_entry)
        raise Boo::Error, "Comando bloqueado por regras de segurança: \"#{cmd}\""
      end

      log_entry[:result] = "allowed"
      append_log(log_entry)
      true
    end

    def append_log(payload)
      File.open(LOG_PATH, "a") do |f|
        f.puts(payload.to_json)
      end
    rescue => e
      warn "⚠️ Falha ao gravar log de segurança: #{e.message}"
    end
  end
end
