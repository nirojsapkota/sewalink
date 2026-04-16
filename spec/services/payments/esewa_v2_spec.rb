require 'rails_helper'

RSpec.describe Payments::EsewaV2 do
  let(:secret_key) { '8g8M898P8Go8atD8' }
  let(:product_code) { 'EPAYTEST' }
  let(:amount) { 100 }
  let(:transaction_uuid) { 'test-uuid-123' }

  before do
    allow(ENV).to receive(:fetch).with('ESEWA_SECRET_KEY').and_return(secret_key)
    allow(ENV).to receive(:fetch).with('ESEWA_PRODUCT_CODE').and_return(product_code)
  end

  describe '.generate_signature' do
    it 'generates a valid HMAC-SHA256 signature' do
      # Example based on research: total_amount=100,transaction_uuid=test-uuid-123,product_code=EPAYTEST
      # HMAC-SHA256 of above string with secret '8g8M898P8Go8atD8'
      # Let's calculate what it should be or just test it is reproducible and matches the logic.
      data = "total_amount=#{amount},transaction_uuid=#{transaction_uuid},product_code=#{product_code}"
      expected_hash = OpenSSL::HMAC.digest('sha256', secret_key, data)
      expected_signature = Base64.strict_encode64(expected_hash)

      expect(described_class.generate_signature(amount, transaction_uuid, product_code)).to eq(expected_signature)
    end
  end

  describe '.verify_payment' do
    let(:status_url) { 'https://uat.esewa.com.np/api/epay/main/v2/status' }

    before do
      allow(ENV).to receive(:fetch).with('ESEWA_STATUS_URL', any_args).and_return(status_url)
    end

    it 'returns success when eSewa API returns COMPLETE' do
      stub_request(:get, /#{status_url}/)
        .with(query: { product_code: product_code, total_amount: amount.to_s, transaction_uuid: transaction_uuid })
        .to_return(status: 200, body: { status: 'COMPLETE' }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = described_class.verify_payment(transaction_uuid, amount)
      expect(result).to eq(true)
    end

    it 'returns false when eSewa API returns something else' do
      stub_request(:get, /#{status_url}/)
        .to_return(status: 200, body: { status: 'PENDING' }.to_json, headers: { 'Content-Type' => 'application/json' })

      result = described_class.verify_payment(transaction_uuid, amount)
      expect(result).to eq(false)
    end

    it 'returns false when API call fails' do
      stub_request(:get, /#{status_url}/).to_return(status: 500)

      result = described_class.verify_payment(transaction_uuid, amount)
      expect(result).to eq(false)
    end
  end
end
