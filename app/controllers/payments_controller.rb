class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @task = Task.find(params[:task_id])
    # For now, we pay the full task budget.
    # In a more complex scenario, this could be partial or include fees.
    @payment = PaymentTransaction.create!(
      task: @task,
      amount: @task.budget,
      status: :pending
    )

    @esewa_data = {
      amount: @payment.amount.to_f,
      tax_amount: 0,
      total_amount: @payment.amount.to_f,
      transaction_uuid: @payment.transaction_uuid,
      product_code: ENV.fetch('ESEWA_PRODUCT_CODE', 'EPAYTEST'),
      product_service_charge: 0,
      product_delivery_charge: 0,
      success_url: success_payments_url,
      failure_url: failure_payments_url,
      signed_field_names: "total_amount,transaction_uuid,product_code"
    }

    @esewa_data[:signature] = Payments::EsewaV2.generate_signature(
      @esewa_data[:total_amount],
      @esewa_data[:transaction_uuid],
      @esewa_data[:product_code]
    )

    @esewa_url = ENV.fetch('ESEWA_PAYMENT_URL', 'https://uat.esewa.com.np/api/epay/main/v2/form')

    # We can render a view that auto-submits the form to eSewa
    render :checkout
  end

  def success
    encoded_data = params[:data]
    decoded_data = JSON.parse(Base64.decode64(encoded_data))
    
    @payment = PaymentTransaction.find_by!(transaction_uuid: decoded_data['transaction_uuid'])
    
    if @payment.completed?
      return redirect_to task_path(@payment.task), notice: "Payment already processed."
    end

    is_valid = Payments::EsewaV2.verify_payment(
      @payment.transaction_uuid,
      @payment.amount.to_f
    )

    if is_valid
      @payment.complete!
      redirect_to task_path(@payment.task), notice: "Payment successful!"
    else
      @payment.fail!
      redirect_to task_path(@payment.task), alert: "Payment verification failed."
    end
  rescue StandardError => e
    Rails.logger.error "eSewa Callback Error: #{e.message}"
    redirect_to root_path, alert: "An error occurred during payment verification."
  end

  def failure
    redirect_to root_path, alert: "Payment failed. Please try again."
  end
end
