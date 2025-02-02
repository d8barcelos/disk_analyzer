require "file"
require "option_parser"
require "colorize"
require "time"
require "json"

module DiskUsageAnalyzer
  VERSION = "1.0.0"

  # Configuration class to store analysis settings
  class Config
    property path : String
    property top_n : Int32
    property min_size : Int64
    property show_hidden : Bool
    property sort_by : String
    property output_format : String
    property verbose : Bool

    def initialize(
      @path = ".",
      @top_n = 10,
      @min_size = 0_i64,
      @show_hidden = false,
      @sort_by = "size",
      @output_format = "human",
      @verbose = false
    )
    end
  end

  # Result class to store analysis results
  class EntryInfo
    property path : String
    property size : Int64
    property type : String
    property last_modified : Time
    property permissions : File::Permissions

    def initialize(@path, @size, @type, @last_modified, @permissions)
    end
  end

  class Analyzer
    @config : Config
    @total_size : Int64 = 0_i64
    @processed_files : Int32 = 0
    @start_time : Time

    def initialize(@config)
      @start_time = Time.local
    end

    # Main analysis method
    def analyze
      validate_path
      results = scan_directory(@config.path)
      display_results(results)
      display_summary if @config.verbose
    end

    private def validate_path
      unless Dir.exists?(@config.path)
        error "Directory '#{@config.path}' does not exist."
      end

      begin
        Dir.children(@config.path)
      rescue ex : File::AccessDeniedError
        error "Cannot read directory '#{@config.path}'. Permission denied."
      rescue ex : Exception
        error "Error accessing '#{@config.path}': #{ex.message}"
      end
    end

    # Recursively scan directory
    private def scan_directory(path : String) : Array(EntryInfo)
      entries = [] of EntryInfo

      Dir.children(path).each do |entry|
        next if skip_entry?(entry)
        
        full_path = File.join(path, entry)
        begin
          info = process_entry(full_path)
          entries << info if info.size >= @config.min_size
          @processed_files += 1
          print_progress if @config.verbose
        rescue ex : Exception
          log_error(full_path, ex)
        end
      end

      sort_entries(entries)
    end

    private def skip_entry?(entry : String) : Bool
      !@config.show_hidden && entry.starts_with?(".")
    end

    private def process_entry(path : String) : EntryInfo
      stat = File.info(path)
      size = calculate_size(path)
      @total_size += size

      EntryInfo.new(
        path: path,
        size: size,
        type: stat.directory? ? "directory" : "file",
        last_modified: stat.modification_time,
        permissions: stat.permissions
      )
    end

    # Calculate size of file or directory
    private def calculate_size(path : String) : Int64
      if File.directory?(path)
        size = 0_i64
        Dir.children(path).each do |child|
          full_path = File.join(path, child)
          size += calculate_size(full_path) rescue 0_i64
        end
        size
      else
        File.size(path)
      end
    rescue
      0_i64
    end

    private def sort_entries(entries : Array(EntryInfo)) : Array(EntryInfo)
      case @config.sort_by
      when "size"
        entries.sort_by! { |entry| -entry.size }
      when "name"
        entries.sort_by! { |entry| entry.path }
      when "modified"
        entries.sort_by! { |entry| -entry.last_modified.to_unix }
      else
        entries.sort_by! { |entry| -entry.size }
      end
    end

    # Display results based on configured format
    private def display_results(entries : Array(EntryInfo))
      case @config.output_format
      when "json"
        display_json(entries)
      when "csv"
        display_csv(entries)
      else
        display_human_readable(entries)
      end
    end

    private def display_human_readable(entries : Array(EntryInfo))
      puts "\nTop #{@config.top_n} space consumers in '#{@config.path}':".colorize.bold
      entries.first(@config.top_n).each_with_index do |entry, index|
        type_indicator = entry.type == "directory" ? "📁" : "📄"
        size_str = format_size(entry.size).rjust(10)
        puts "#{index + 1}. #{type_indicator} #{entry.path}".colorize.blue
        puts "   Size: #{size_str} | Modified: #{entry.last_modified.to_s("%Y-%m-%d %H:%M:%S")}".colorize.dim
      end
    end

    private def display_json(entries : Array(EntryInfo))
      json_entries = entries.first(@config.top_n).map do |entry|
        {
          path: entry.path,
          size: entry.size,
          size_formatted: format_size(entry.size),
          type: entry.type,
          last_modified: entry.last_modified.to_s
        }
      end
      puts JSON.build { |json| json.array { json_entries.to_json(json) } }
    end

    private def display_csv(entries : Array(EntryInfo))
      puts "Path,Size,Size (bytes),Type,Last Modified"
      entries.first(@config.top_n).each do |entry|
        puts "#{entry.path},#{format_size(entry.size)},#{entry.size},#{entry.type},#{entry.last_modified}"
      end
    end

    private def display_summary
      duration = Time.local - @start_time
      puts "\nAnalysis Summary:".colorize.bold
      puts "Total size: #{format_size(@total_size)}"
      puts "Files processed: #{@processed_files}"
      puts "Time taken: #{duration.total_seconds.round(2)} seconds"
      puts "Average processing speed: #{(@processed_files / duration.total_seconds).round(2)} files/sec"
    end

    # Format size in human-readable format
    private def format_size(bytes : Int64) : String
      units = ["B", "KB", "MB", "GB", "TB", "PB"]
      unit_index = 0
      size = bytes.to_f

      while size >= 1024 && unit_index < units.size - 1
        size /= 1024
        unit_index += 1
      end

      "#{size.round(2)} #{units[unit_index]}"
    end

    private def print_progress
      print "\rProcessed #{@processed_files} files...".colorize.dim
    end

    private def log_error(path : String, error : Exception)
      STDERR.puts "Error processing '#{path}': #{error.message}".colorize.red if @config.verbose
    end

    private def error(message : String)
      STDERR.puts "Error: #{message}".colorize.red
      exit(1)
    end
  end
end

# Command-line interface
config = DiskUsageAnalyzer::Config.new

OptionParser.parse do |parser|
  parser.banner = "Usage: disk_usage_analyzer [options] <directory>"

  parser.on("-n NUMBER", "--top=NUMBER", "Number of entries to display (default: 10)") do |n|
    config.top_n = n.to_i
  end

  parser.on("-m SIZE", "--min-size=SIZE", "Minimum size to include (in bytes)") do |size|
    config.min_size = size.to_i64
  end

  parser.on("-s SORT", "--sort-by=SORT", "Sort by: size, name, modified (default: size)") do |sort|
    config.sort_by = sort
  end

  parser.on("-f FORMAT", "--format=FORMAT", "Output format: human, json, csv (default: human)") do |format|
    config.output_format = format
  end

  parser.on("-a", "--all", "Show hidden files and directories") do
    config.show_hidden = true
  end

  parser.on("-v", "--verbose", "Show detailed progress and errors") do
    config.verbose = true
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.on("--version", "Show version") do
    puts "DiskUsageAnalyzer v#{DiskUsageAnalyzer::VERSION}"
    exit
  end

  parser.unknown_args do |args|
    if args.empty?
      STDERR.puts "Error: Directory path is required.".colorize.red
      STDERR.puts parser
      exit(1)
    end
    config.path = args[0]
  end
end

analyzer = DiskUsageAnalyzer::Analyzer.new(config)
analyzer.analyze