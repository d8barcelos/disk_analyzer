require "file"

module DiskUsageAnalyzer
  class Analyzer
    def initialize(@path : String)
    end

    # Calcula o tamanho total de um diretório ou arquivo
    def calculate_size(path : String) : Int64
      begin
        if File.directory?(path)
          size = 0_i64
          Dir.children(path).each do |child|
            size += calculate_size(File.join(path, child))
          end
          size
        else
          File.size(path)
        end
      rescue File::NotFoundError
        # Ignora arquivos/diretórios que não existem mais
        0_i64
      rescue File::AccessDeniedError
        # Ignora arquivos/diretórios sem permissão de leitura
        puts "Aviso: Acesso negado a '#{path}'"
        0_i64
      end
    end

    # Lista os maiores arquivos/diretórios
    def analyze(top_n : Int32 = 10)
      entries = [] of Tuple(String, Int64)

      # Varre o diretório
      Dir.children(@path).each do |entry|
        full_path = File.join(@path, entry)
        size = calculate_size(full_path)
        entries << {full_path, size}
      end

      # Ordena pelo tamanho (decrescente)
      entries.sort_by! { |_, size| -size }

      # Exibe os maiores
      puts "\nTop #{top_n} maiores consumidores de espaço em '#{@path}':"
      entries.first(top_n).each_with_index do |(path, size), index|
        puts "#{index + 1}. #{path} - #{format_size(size)}"
      end
    end

    # Formata o tamanho em bytes para uma string legível
    private def format_size(size : Int64) : String
      if size >= 1_000_000_000
        "#{size / 1_000_000_000} GB"
      elsif size >= 1_000_000
        "#{size / 1_000_000} MB"
      elsif size >= 1_000
        "#{size / 1_000} KB"
      else
        "#{size} bytes"
      end
    end
  end
end

# Interface de linha de comando
if ARGV.size == 0
  puts "Uso: disk_usage_analyzer <diretório> [top_n]"
  exit(1)
end

path = ARGV[0]
top_n = ARGV.size > 1 ? ARGV[1].to_i : 10

if !Dir.exists?(path)
  puts "Erro: O diretório '#{path}' não existe."
  exit(1)
end

analyzer = DiskUsageAnalyzer::Analyzer.new(path)
analyzer.analyze(top_n)