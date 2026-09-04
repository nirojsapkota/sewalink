class Admin::Accounting::ReportsController < Admin::BaseController
  VALID_PERIODS = %w[day month].freeze

  def show
    @period = VALID_PERIODS.include?(params[:period]) ? params[:period] : "day"
    grouped = @period == "month" ? :group_by_month : :group_by_day
    span = @period == "month" ? 12 : 30

    commission_scope = DoubleEntry::Line.where(account: "platform_revenue", code: ["commission", "cash_commission"]).where("amount > 0")
    refund_scope = DoubleEntry::Line.where(account: "escrow", code: "refund").where("amount < 0")

    @commission_by_period = commission_scope.public_send(grouped, :created_at, last: span).sum("amount / 100.0")
    @refunds_by_period = refund_scope.public_send(grouped, :created_at, last: span).sum("ABS(amount) / 100.0")
    @net_revenue_by_period = @commission_by_period
  end
end
