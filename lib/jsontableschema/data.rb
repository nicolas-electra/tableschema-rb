module JsonTableSchema
  module Data

    attr_reader :errors

    def load_fields!
      self['fields'] = (self['fields'] || []).map { |f| JsonTableSchema::Field.new(f) }
    end

    def cast(rows, fail_fast = true)
      @errors ||= []
      rows.map! do |r|
        begin
          cast_row(r, fail_fast)
        rescue MultipleInvalid, ConversionError => e
          raise e if fail_fast == true
          @errors << e if e.is_a?(ConversionError)
        end
      end
      check_for_errors
      rows
    end

    alias_method :convert, :cast

    def cast_row(row, fail_fast = true)
      @errors ||= []
      raise_header_error(row) if row.count != fields.count
      fields.each_with_index do |field,i|
        row[i] = cast_column(field, row[i], fail_fast)
      end
      check_for_errors
      row
    end

    alias_method :convert_row, :cast_row

    private

    def raise_header_error(row)
      raise(JsonTableSchema::ConversionError.new("The number of items to convert (#{row.count}) does not match the number of headers in the schema (#{fields.count})"))
    end

    def check_for_errors
      raise(JsonTableSchema::MultipleInvalid.new("There were errors parsing the data")) if @errors.count > 0
    end

    def cast_column(field, col, fail_fast)
      field.cast_value(col)
    rescue Exception => e
      if fail_fast == true
        raise e
      else
        @errors << e
      end
    end

    alias_method :convert_column, :cast_column

  end
end
