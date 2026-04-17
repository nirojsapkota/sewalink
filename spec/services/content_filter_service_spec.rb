# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentFilterService do
  describe '.mask' do
    let(:masked_text) { described_class::MASK_REPLACEMENT }

    it 'masks standard Nepal mobile numbers' do
      expect(described_class.mask('My number is 9841234567')).to eq("My number is #{masked_text}")
    end

    it 'masks mobile numbers with +977 country code' do
      expect(described_class.mask('Call me at +9779860987654')).to eq("Call me at #{masked_text}")
    end
    
    it 'masks mobile numbers with a space after country code' do
        expect(described_class.mask('Call me at +977 9860987654')).to eq("Call me at #{masked_text}")
    end

    it 'masks landline numbers with area code' do
      expect(described_class.mask('Office: 014567890')).to eq("Office: #{masked_text}")
    end

    it 'masks email addresses' do
      expect(described_class.mask('Email me at test@example.com')).to eq("Email me at #{masked_text}")
    end

    it 'returns the original string if it is not a PII' do
      expect(described_class.mask('This is a normal message.')).to eq('This is a normal message.')
    end

    it 'handles multiple PIIs in a string' do
      message = 'My number is 9841234567 and email is test@example.com'
      expect(described_class.mask(message)).to eq("My number is #{masked_text} and email is #{masked_text}")
    end

    it 'does not mask numbers that are not phone numbers' do
        expect(described_class.mask('The price is 9841. Not a number.')).to eq('The price is 9841. Not a number.')
    end

    it 'returns blank if the text is blank' do
      expect(described_class.mask('')).to eq('')
    end
  end
end
