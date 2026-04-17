# frozen_string_literal: true

class ContentFilterService
  # Source: Nepal Telecommunications Authority (NTA) Numbering Plan 2024
  # Covers NTC, Ncell, Smart Cell mobile numbers and landlines.
  NEPAL_PHONE_REGEX = /(?<!\d)(?:(?:\+977|00977)\s*)?(?:9[678]\d{8}|0[1-9]\d{7,9})(?!\d)/
  EMAIL_REGEX = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i

  MASK_REPLACEMENT = "[CONTACT MASKED]"

  def self.mask(text)
    return text if text.blank?
    
    text.gsub(NEPAL_PHONE_REGEX, MASK_REPLACEMENT).gsub(EMAIL_REGEX, MASK_REPLACEMENT)
  end
end
