module LFCSV
  class BatchImporter < Importer
    def initialize(data={})
      @process_que      = []
      @queued_count = 0
      @batch_size       = data[:batch_size] || 200
      super
    end

    def handle_row(row)
      queue_up row
      process_the_que!
    end

    def queue_up row
      if valid? row
        @process_que << row
      else
        @rows_count -=1
      end
    end

    def process_the_que!
      if @process_que.length > @batch_size || @process_que.length >= unprocessed_rows_remaining
        handle_batch(@process_que)
        @queued_count += @process_que.length
        puts "Importer sent batch of #{@process_que.length} records totalling #{@queued_count} this run."
        @process_que = []
      end
    end

    def unprocessed_rows_remaining
      @rows_count - @queued_count
    end

    def valid? row
      raise "No method has been defined for validating a row.
             You must define a method named `valid?` in the class inheriting from LSCSV::BatchImporter."
    end

    def handle_batch(process_que)
      raise "No method has been defined for handling the batch.
             You must define a method named `handle_batch` in the class inheriting from LSCSV::BatchImporter."
    end
  end
end
