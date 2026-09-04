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
end
