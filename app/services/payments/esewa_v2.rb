module Payments
  class EsewaV2
    include HTTParty

    def self.generate_signature(total_amount, transaction_uuid, product_code)
      secret = ENV.fetch('ESEWA_SECRET_KEY')
      data = "total_amount=#{total_amount},transaction_uuid=#{transaction_uuid},product_code=#{product_code}"
      
      hash = OpenSSL::HMAC.digest('sha256', secret, data)
      Base64.strict_encode64(hash)
    end

    def self.verify_payment(transaction_uuid, total_amount)
      status_url = ENV.fetch('ESEWA_STATUS_URL', 'https://uat.esewa.com.np/api/epay/main/v2/status')
      product_code = ENV.fetch('ESEWA_PRODUCT_CODE')

      response = get(status_url, query: {
        product_code: product_code,
        total_amount: total_amount.to_s,
        transaction_uuid: transaction_uuid
      })

      return false unless response.success?

      response.parsed_response['status'] == 'COMPLETE'
    rescue StandardError => e
      Rails.logger.error "eSewa Verification Error: #{e.message}"
      false
    end
  end
end
