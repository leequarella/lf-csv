module LFCSV
  class Importer
    @@header_symbols   = []
    @@header_aliases   = {}
    attr_accessor :rows_count

    def initialize(data)
      @file             = data[:file]
      @column_seperator = data[:column_seperator] || ','
      @quote_char       = data[:quote_char]       || '"'
      @use_quotes       = data[:use_quotes]       || true
    end

    def process
      rows = CSV.parse(@file.read,
        force_quotes: @use_quotes,
        headers:      true,
        col_sep:      @column_seperator,
        quote_char:   @quote_char,
        skip_blanks:  false)
      @rows_count = rows.count
      header_index = parse_headers(rows.headers)
      puts header_index
      rows.each {|row| process_csv_row(row, header_index)}
    end

    private
    def self.column(symbol, aliases=nil)
      @@header_symbols << symbol unless @@header_symbols.include?(symbol)
      if aliases
        add_aliases_to_column symbol, aliases
      else
        @@header_aliases[symbol] = [symbol.to_s]
      end
    end

    def self.add_aliases_to_column symbol, aliases
      aliases.map! { |a| a.strip.downcase }
      if @@header_aliases[symbol]
        @@header_aliases[symbol] = (@@header_aliases[symbol] + aliases).uniq
      else
        @@header_aliases[symbol] = aliases
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
      @@header_symbols.each do |header_symbol|
        if @@header_aliases[header_symbol].include?(search_string)
          matched = true
          @header_index[header_symbol] = index
          break
        end
      end
      matched
    end

    def process_csv_row(row, header_index)
      handle_row(convert_row_to_hash(row, header_index))
    end

    def convert_row_to_hash(row, header_index)
      hash = {}
      @@header_symbols.each do |header_symbol|
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
  end
end
