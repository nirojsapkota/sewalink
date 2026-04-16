class SmsService
  def self.send_otp(phone, code)
    # Using an adapter pattern as suggested in research
    adapter = sms_adapter
    adapter.send_otp(phone, code)
  end

  private

  def self.sms_adapter
    case ENV['SMS_GATEWAY']
    when 'sparrow'
      SparrowAdapter.new
    when 'aakash'
      AakashAdapter.new
    else
      MockAdapter.new
    end
  end

  class MockAdapter
    def send_otp(phone, code)
      message = "Your sewaLink OTP is: #{code}"
      Rails.logger.info " [SMS MOCK] To: #{phone} | Message: #{message}"
      # In development/test we can also write to a file or just log
      true
    end
  end

  class SparrowAdapter
    def send_otp(phone, code)
      # Implementation for Sparrow SMS
      # This is a stub for now as we don't have credentials
      Rails.logger.warn "Sparrow SMS adapter not fully implemented"
      false
    end
  end

  class AakashAdapter
    def send_otp(phone, code)
      # Implementation for Aakash SMS
      # This is a stub for now as we don't have credentials
      Rails.logger.warn "Aakash SMS adapter not fully implemented"
      false
    end
  end
end
