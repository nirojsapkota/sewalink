require "csv"

module Accounting
  class EsewaSettlementImporter
    class Error < StandardError; end

    MAX_FILE_SIZE = 5.megabytes
    MAX_ROWS = 5000
    ALLOWED_CONTENT_TYPES = %w[text/csv application/csv application/vnd.ms-excel text/plain].freeze
    HEADER_ALIASES = {
      transaction_ref: %w[transaction_ref ref reference transaction_id txn_ref],
      amount: %w[amount amount_npr total],
      settled_on: %w[date settled_on settlement_date txn_date],
    }.freeze

    Result = Struct.new(:imported_count, :error_count, :errors, keyword_init: true)

    def self.call(file:, imported_by:)
      new(file, imported_by).call
    end

    def initialize(file, imported_by)
      @file = file
      @imported_by = imported_by
    end

    def call
      validate_file!
      rows = CSV.parse(@file.read, headers: true)
      raise Error, "CSV has too many rows (max #{MAX_ROWS})" if rows.size > MAX_ROWS

      column_map = build_column_map(rows.headers)
      imported = 0
      errors = []

      rows.each_with_index do |row, idx|
        ref = row[column_map[:transaction_ref]]
        amount = row[column_map[:amount]]
        date = row[column_map[:settled_on]]

        if ref.blank? || amount.blank? || date.blank?
          errors << "Row #{idx + 2}: missing required field(s)"
          next
        end

        EsewaSettlement.create!(
          transaction_ref: ref.strip,
          amount_cents: (BigDecimal(amount.to_s) * 100).to_i,
          settled_on: Date.parse(date),
          raw_row: row.to_h.to_json,
          imported_by: @imported_by,
          status: "unmatched"
        )
        imported += 1
      rescue ArgumentError, TypeError => e
        errors << "Row #{idx + 2}: #{e.message}"
      end

      Result.new(imported_count: imported, error_count: errors.size, errors: errors)
    end

    private

    def validate_file!
      raise Error, "File too large (max #{MAX_FILE_SIZE / 1.megabyte}MB)" if @file.size > MAX_FILE_SIZE

      filename = @file.respond_to?(:original_filename) ? @file.original_filename.to_s : ""
      content_type = @file.respond_to?(:content_type) ? @file.content_type.to_s : ""
      return if filename.downcase.end_with?(".csv") || ALLOWED_CONTENT_TYPES.include?(content_type)

      raise Error, "Unsupported file type; please upload a .csv file"
    end

    def build_column_map(headers)
      map = HEADER_ALIASES.transform_values do |aliases|
        headers.find { |h| aliases.include?(h.to_s.strip.downcase) }
      end
      missing = map.select { |_, v| v.nil? }.keys
      raise Error, "CSV missing required columns: #{missing.join(', ')}" if missing.any?

      map
    end
  end
end
