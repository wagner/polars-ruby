module Polars
  module IO
    def read_csv(
      file,
      has_header: true,
      columns: nil,
      new_columns: nil,
      sep: ",",
      comment_char: nil,
      quote_char: '"',
      skip_rows: 0,
      dtypes: nil,
      null_values: nil,
      ignore_errors: false,
      parse_dates: false,
      n_threads: nil,
      infer_schema_length: 100,
      batch_size: 8192,
      n_rows: nil,
      encoding: "utf8",
      low_memory: false,
      rechunk: true,
      storage_options: nil,
      skip_rows_after_header: 0,
      row_count_name: nil,
      row_count_offset: 0,
      sample_size: 1024,
      eol_char: "\n"
    )
      _check_arg_is_1byte("sep", sep, false)
      _check_arg_is_1byte("comment_char", comment_char, false)
      _check_arg_is_1byte("quote_char", quote_char, true)
      _check_arg_is_1byte("eol_char", eol_char, false)

      projection, columns = Utils.handle_projection_columns(columns)

      storage_options ||= {}

      if columns && !has_header
        columns.each do |column|
          if !column.start_with?("column_")
            raise ArgumentError, "Specified column names do not start with \"column_\", but autogenerated header names were requested."
          end
        end
      end

      if projection || new_columns
        raise "todo"
      end

      df = nil
      _prepare_file_arg(file) do |data|
        df = DataFrame._read_csv(
          data,
          has_header: has_header,
          columns: columns || projection,
          sep: sep,
          comment_char: comment_char,
          quote_char: quote_char,
          skip_rows: skip_rows,
          dtypes: dtypes,
          null_values: null_values,
          ignore_errors: ignore_errors,
          parse_dates: parse_dates,
          n_threads: n_threads,
          infer_schema_length: infer_schema_length,
          batch_size: batch_size,
          n_rows: n_rows,
          encoding: encoding == "utf8-lossy" ? encoding : "utf8",
          low_memory: low_memory,
          rechunk: rechunk,
          skip_rows_after_header: skip_rows_after_header,
          row_count_name: row_count_name,
          row_count_offset: row_count_offset,
          sample_size: sample_size,
          eol_char: eol_char
        )
      end

      if new_columns
        Utils._update_columns(df, new_columns)
      else
        df
      end
    end

    def scan_csv(
      file,
      has_header: true,
      sep: ",",
      comment_char: nil,
      quote_char: '"',
      skip_rows: 0,
      dtypes: nil,
      null_values: nil,
      ignore_errors: false,
      cache: true,
      with_column_names: nil,
      infer_schema_length: 100,
      n_rows: nil,
      encoding: "utf8",
      low_memory: false,
      rechunk: true,
      skip_rows_after_header: 0,
      row_count_name: nil,
      row_count_offset: 0,
      parse_dates: false,
      eol_char: "\n"
    )
      _check_arg_is_1byte("sep", sep, false)
      _check_arg_is_1byte("comment_char", comment_char, false)
      _check_arg_is_1byte("quote_char", quote_char, true)

      if file.is_a?(String) || (defined?(Pathname) && file.is_a?(Pathname))
        file = Utils.format_path(file)
      end

      LazyFrame._scan_csv(
        file,
        has_header: has_header,
        sep: sep,
        comment_char: comment_char,
        quote_char: quote_char,
        skip_rows: skip_rows,
        dtypes: dtypes,
        null_values: null_values,
        ignore_errors: ignore_errors,
        cache: cache,
        with_column_names: with_column_names,
        infer_schema_length: infer_schema_length,
        n_rows: n_rows,
        low_memory: low_memory,
        rechunk: rechunk,
        skip_rows_after_header: skip_rows_after_header,
        encoding: encoding,
        row_count_name: row_count_name,
        row_count_offset: row_count_offset,
        parse_dates: parse_dates,
        eol_char: eol_char,
      )
    end

    # def scan_ipc
    # end

    # def scan_parquet
    # end

    def scan_ndjson(
      file,
      infer_schema_length: 100,
      batch_size: 1024,
      n_rows: nil,
      low_memory: false,
      rechunk: true,
      row_count_name: nil,
      row_count_offset: 0
    )
      if file.is_a?(String) || (defined?(Pathname) && file.is_a?(Pathname))
        file = Utils.format_path(file)
      end

      LazyFrame._scan_ndjson(
        file,
        infer_schema_length: infer_schema_length,
        batch_size: batch_size,
        n_rows: n_rows,
        low_memory: low_memory,
        rechunk: rechunk,
        row_count_name: row_count_name,
        row_count_offset: row_count_offset,
      )
    end

    # def read_avro
    # end

    # def read_ipc
    # end

    def read_parquet(file)
      _prepare_file_arg(file) do |data|
        DataFrame._read_parquet(data)
      end
    end

    def read_json(file)
      DataFrame._read_json(file)
    end

    def read_ndjson(file)
      DataFrame._read_ndjson(file)
    end

    # def read_sql
    # end

    # def read_excel
    # end

    # def read_csv_batched
    # end

    private

    def _prepare_file_arg(file)
      if file.is_a?(String) && file =~ /\Ahttps?:\/\//
        raise ArgumentError, "use URI(...) for remote files"
      end

      if defined?(URI) && file.is_a?(URI)
        require "open-uri"

        file = URI.open(file)
      end

      yield file
    end

    def _check_arg_is_1byte(arg_name, arg, can_be_empty = false)
      if arg.is_a?(String)
        arg_byte_length = arg.bytesize
        if can_be_empty
          if arg_byte_length > 1
            raise ArgumentError, "#{arg_name} should be a single byte character or empty, but is #{arg_byte_length} bytes long."
          end
        elsif arg_byte_length != 1
          raise ArgumentError, "#{arg_name} should be a single byte character, but is #{arg_byte_length} bytes long."
        end
      end
    end
  end
end
