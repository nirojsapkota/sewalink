class Admin::SettingsController < Admin::BaseController
  def show
    assign_financial_overview
  end

  def update
    if params.key?(:geofence_check_in_enabled)
      update_geofence_setting
    else
      update_commission_rate
    end
  end

  private

  def update_commission_rate
    rate = params[:commission_rate].to_s

    if valid_rate?(rate)
      PlatformSetting.set_commission_rate(rate)
      log_admin_action!("update_commission_rate", nil, details: { new_rate: rate })
      redirect_to admin_settings_path, notice: "Commission rate updated to #{(rate.to_f * 100).round(2)}%."
    else
      redirect_to admin_settings_path, alert: "Please provide a valid commission rate between 0 and 1 (e.g. 0.10 for 10%)."
    end
  end

  def update_geofence_setting
    enabled = ActiveModel::Type::Boolean.new.cast(params[:geofence_check_in_enabled])
    PlatformSetting.set_geofence_check_in_enabled(enabled)
    log_admin_action!("update_geofence_check_in_enabled", nil, details: { enabled: enabled })
    redirect_to admin_settings_path, notice: "Location-based check-in is now #{enabled ? 'enabled' : 'disabled'}."
  end

  def valid_rate?(rate)
    value = BigDecimal(rate)
    value >= 0 && value <= 1
  rescue ArgumentError, TypeError
    false
  end

  def assign_financial_overview
    @commission_rate = PlatformSetting.commission_rate
    @geofence_check_in_enabled = PlatformSetting.geofence_check_in_enabled?
    @platform_revenue_balance = DoubleEntry.account(:platform_revenue).balance
    @total_escrow_held = Task.where(payment_type: :esewa, status: [:assigned, :in_progress, :pending_payment, :dispute]).sum(:budget_cents)
  end
end
