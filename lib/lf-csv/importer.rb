require 'csv'
module LFCSV
  class Importer
    attr_accessor :rows_count, :file

    class << self
      def setup_header_containers
        @header_symbols = [] unless @header_symbols
        @header_aliases = {} unless @header_aliases
      end

      def column(symbol, aliases=nil, required: false)
        setup_header_containers
        @header_symbols << symbol unless @header_symbols.include?(symbol)
        attach_aliases(symbol, aliases, required)
        attach_required_status(symbol, required)
      end

      def attach_aliases(symbol, aliases, required)
        if aliases
          aliases.map! { |a| a.strip.downcase }
          add_aliases_to_column symbol, aliases
        else
          @header_aliases[symbol] = {aliases: [symbol.to_s]}
        end
      end

      def attach_required_status(symbol, required)
        @header_aliases[symbol][:required] = required
      end

      def add_aliases_to_column symbol, aliases
        if @header_aliases[symbol]
          @header_aliases[symbol] = {aliases: (@header_aliases[symbol][:aliases] + aliases).uniq}
        else
          @header_aliases[symbol] = {aliases: aliases}
        end
      end
      attr_reader :header_symbols, :header_aliases
    end


    def initialize(data)
      @file             = data[:file]
      @column_seperator = data[:column_seperator] || ','
      @quote_char       = data[:quote_char]       || '"'
      @use_quotes       = data[:use_quotes]       || true
    end

    def process
      rows = CSV.parse(stringify_input(@file),
        force_quotes: @use_quotes,
        headers:      true,
        col_sep:      @column_seperator,
        quote_char:   @quote_char,
        skip_blanks:  false)
      @rows_count = rows.count
      header_index = parse_headers(rows.headers)
      return if missing_required_headers?(rows.headers)
      rows.each {|row| process_csv_row(row, header_index)}
    end

    private
    def stringify_input(file)
      if file.class.name != "String"
        file.read
      else
        file
      end
    end

    def parse_headers(header_strings)
      @header_index = {}
      unmatched = []
      header_strings.each_with_index do |header_string, index|
        matched = parse_header(header_string, index)
        unmatched << header_string unless matched
      end
      @header_index
    end

    def parse_header header_string, index
      return false unless header_string
      search_string = header_string.strip.downcase
      matched = false
      self.class.header_symbols.each do |header_symbol|
        if self.class.header_aliases[header_symbol][:aliases].include?(search_string)
          matched = true
          @header_index[header_symbol] = index
          break
        end
      end
      matched
    end

    def missing_required_headers?(file_headers)
      missing_headers = required_headers - file_headers
      if missing_headers.any?
        missing_column_headers(missing_headers)
        true
      else
        false
      end
    end

    def required_headers
      required = []
      self.class.header_aliases.each do |symbol, info|
        required << symbol if info[:required] == true
      end
      required
    end

    def process_csv_row(row, header_index)
      handle_row(convert_row_to_hash(row, header_index))
    end

    def convert_row_to_hash(row, header_index)
      hash = {}
      self.class.header_symbols.each do |header_symbol|
        if header_index[header_symbol]
          hash[header_symbol] = clean_encode(row[header_index[header_symbol]])
        end
      end
      hash
    end

    def clean_encode(string)
      if string
        string.encode('utf-8', :invalid => :replace, :undef => :replace, :replace => '_')
      else
        string
      end
    end

    def handle_row(row)
      raise "No method has been defined for handling this file.
             You must define a method in the class inheriting from LSCSV::Importer."
    end

    def missing_column_header
      raise "Required columns are missing from this file."
    end

  end
end
