class Admin::Accounting::SettlementsController < Admin::BaseController
  def index
    @from = params[:from].presence ? Date.parse(params[:from]) : 30.days.ago.to_date
    @to = params[:to].presence ? Date.parse(params[:to]) : Date.current
    @settlements = EsewaSettlement.where(settled_on: @from..@to).order(settled_on: :desc)
    @settlement_total_cents = @settlements.sum(:amount_cents)
    @escrow_deposit_total_cents = DoubleEntry::Line
                                   .where(account: "escrow", code: "deposit")
                                   .where("amount > 0")
                                   .where(created_at: @from.beginning_of_day..@to.end_of_day)
                                   .sum(:amount)
    @discrepancy_cents = @escrow_deposit_total_cents - @settlement_total_cents
  rescue ArgumentError
    redirect_to admin_accounting_settlements_path, alert: "Invalid date."
  end

  def new; end

  def create
    result = Accounting::EsewaSettlementImporter.call(file: params.require(:file), imported_by: current_user)
    Accounting::ReconciliationMatcher.call_all(EsewaSettlement.where(status: "unmatched"))
    log_admin_action!("import_esewa_settlement", nil, details: { imported_count: result.imported_count, error_count: result.error_count })

    if result.error_count.zero?
      redirect_to admin_accounting_settlements_path, notice: "Imported #{result.imported_count} settlement rows."
    else
      redirect_to admin_accounting_settlements_path, alert: "Imported #{result.imported_count} rows with #{result.error_count} errors: #{result.errors.first(3).join('; ')}"
    end
  rescue Accounting::EsewaSettlementImporter::Error => e
    redirect_to new_admin_accounting_settlement_path, alert: e.message
  end

  def show
    @settlement = EsewaSettlement.find(params[:id])
    @matched_line = DoubleEntry::Line.find_by(id: @settlement.matched_line_id) if @settlement.matched_line_id
  end
end
