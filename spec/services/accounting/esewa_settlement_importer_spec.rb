require "rails_helper"

RSpec.describe Accounting::EsewaSettlementImporter do
  self.use_transactional_tests = false

  let(:user) { create(:user) }

  after(:each) do
    EsewaSettlement.delete_all
    User.delete_all
  end

  def build_file(content:, size: content.bytesize, filename: "settlements.csv", content_type: "text/csv")
    double(
      "UploadedFile",
      read: content,
      size: size,
      original_filename: filename,
      content_type: content_type
    )
  end

  describe ".call" do
    it "creates one EsewaSettlement per valid row" do
      content = <<~CSV
        transaction_ref,amount,date
        TXN001,100.50,2026-09-01
        TXN002,200.00,2026-09-02
      CSV

      result = described_class.call(file: build_file(content: content), imported_by: user)

      expect(result.imported_count).to eq(2)
      expect(result.error_count).to eq(0)
      expect(EsewaSettlement.count).to eq(2)
      expect(EsewaSettlement.pluck(:status).uniq).to eq(["unmatched"])
      settlement = EsewaSettlement.find_by(transaction_ref: "TXN001")
      expect(settlement.amount_cents).to eq(100_50)
      expect(settlement.settled_on).to eq(Date.parse("2026-09-01"))
    end

    it "raises and creates zero records for a file over 5MB" do
      content = "transaction_ref,amount,date\nTXN001,100.50,2026-09-01\n"
      file = build_file(content: content, size: 6.megabytes)

      expect {
        described_class.call(file: file, imported_by: user)
      }.to raise_error(Accounting::EsewaSettlementImporter::Error, /too large/i)

      expect(EsewaSettlement.count).to eq(0)
    end

    it "raises for a disallowed filename/content-type combination" do
      content = "transaction_ref,amount,date\nTXN001,100.50,2026-09-01\n"
      file = build_file(content: content, filename: "settlements.exe", content_type: "application/octet-stream")

      expect {
        described_class.call(file: file, imported_by: user)
      }.to raise_error(Accounting::EsewaSettlementImporter::Error, /unsupported file type/i)

      expect(EsewaSettlement.count).to eq(0)
    end

    it "raises when the CSV has more than 5000 data rows" do
      header = "transaction_ref,amount,date\n"
      rows = (1..5001).map { |i| "TXN#{i},#{100 + i}.00,2026-09-01" }.join("\n")
      content = header + rows + "\n"

      expect {
        described_class.call(file: build_file(content: content), imported_by: user)
      }.to raise_error(Accounting::EsewaSettlementImporter::Error, /too many rows/i)

      expect(EsewaSettlement.count).to eq(0)
    end

    it "raises when a required column is missing" do
      content = <<~CSV
        transaction_ref,date
        TXN001,2026-09-01
      CSV

      expect {
        described_class.call(file: build_file(content: content), imported_by: user)
      }.to raise_error(Accounting::EsewaSettlementImporter::Error, /missing required columns/i)

      expect(EsewaSettlement.count).to eq(0)
    end

    it "skips a row with a blank required field, recording an error, while still importing valid rows" do
      content = <<~CSV
        transaction_ref,amount,date
        TXN001,100.50,2026-09-01
        ,200.00,2026-09-02
        TXN003,300.00,2026-09-03
      CSV

      result = described_class.call(file: build_file(content: content), imported_by: user)

      expect(result.imported_count).to eq(2)
      expect(result.error_count).to eq(1)
      expect(result.errors.first).to match(/Row 3/)
      expect(EsewaSettlement.count).to eq(2)
    end
  end
end
