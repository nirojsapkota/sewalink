MoneyRails.configure do |config|
  # To set the default currency
  config.default_currency = :npr

  # Set default bank to central bank of Nepal (manual/fixed for now)
  # config.default_bank = Money::Bank::VariableExchange.new

  # To handle rounding
  config.rounding_mode = BigDecimal::ROUND_HALF_UP

  # Register a custom currency
  config.register_currency = {
    priority:            1,
    iso_code:            "NPR",
    name:                "Nepalese Rupee",
    symbol:              "रू",
    symbol_first:        true,
    subunit:             "Paisa",
    subunit_to_unit:     100,
    thousands_separator: ",",
    decimal_mark:        "."
  }
end
