class Admin::SettingsController < Admin::BaseController
  def show
    assign_financial_overview
  end

  def update
    rate = params[:commission_rate].to_s

    if valid_rate?(rate)
      PlatformSetting.set_commission_rate(rate)
      log_admin_action!("update_commission_rate", nil, details: { new_rate: rate })
      redirect_to admin_settings_path, notice: "Commission rate updated to #{(rate.to_f * 100).round(2)}%."
    else
      redirect_to admin_settings_path, alert: "Please provide a valid commission rate between 0 and 1 (e.g. 0.10 for 10%)."
    end
  end

  private

  def valid_rate?(rate)
    value = BigDecimal(rate)
    value >= 0 && value <= 1
  rescue ArgumentError, TypeError
    false
  end

  def assign_financial_overview
    @commission_rate = PlatformSetting.commission_rate
    @platform_revenue_balance = DoubleEntry.account(:platform_revenue).balance
    @total_escrow_held = Task.where(payment_type: :esewa, status: [:assigned, :in_progress, :pending_payment, :dispute]).sum(:budget_cents)
  end
end
