class Admin::Accounting::LedgerEntriesController < Admin::BaseController
  def index
    @from = params[:from].presence && Date.parse(params[:from])
    @to = params[:to].presence && Date.parse(params[:to])
    @account = params[:account].presence
    @code = params[:code].presence
    @user_id = params[:user_id].presence

    @lines = Accounting::LedgerQuery.call(
      from: @from, to: @to, account: @account, code: @code, user_id: @user_id
    ).page(params[:page]).per(20)
  rescue ArgumentError
    redirect_to admin_accounting_ledger_index_path, alert: "Invalid date format."
  end

  def show
    @line = DoubleEntry::Line.find(params[:id])
    @partner_line = @line.partner
    resolve_linked_context
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_accounting_ledger_index_path, alert: "Transaction not found."
  end

  private

  def resolve_linked_context
    case @line[:account]
    when "escrow"
      @linked_task = Task.find_by(id: @line[:scope])
      @dispute_logs = AdminActivityLog.where(target_type: "Task", target_id: @linked_task.id).order(created_at: :desc) if @linked_task
    when "tasker_balance"
      @linked_user = User.find_by(id: @line[:scope])
    end
  end
end
