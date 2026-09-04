class Admin::Accounting::DashboardsController < Admin::BaseController
  def show
    assign_date_range
    @summary = Accounting::CashFlowCategorizer.summary(from: @from.beginning_of_day, to: @to.end_of_day)
  end

  def category
    assign_date_range
    @category = params[:category].to_sym
    @label = Accounting::CashFlowCategorizer.label_for(@category)
    @lines = Accounting::CashFlowCategorizer
             .scope_for(@category, from: @from.beginning_of_day, to: @to.end_of_day)
             .page(params[:page]).per(20)
  rescue KeyError
    redirect_to admin_accounting_dashboard_path, alert: "Unknown category."
  end

  private

  def assign_date_range
    @from = params[:from].present? ? Date.parse(params[:from]) : 30.days.ago.to_date
    @to = params[:to].present? ? Date.parse(params[:to]) : Date.current
  rescue ArgumentError
    @from = 30.days.ago.to_date
    @to = Date.current
  end
end
