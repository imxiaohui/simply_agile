class Authorisation < ActiveRecord::Base
  include PaymentGateway
  
  attr_accessor :payment_method
  attr_accessor :response
  belongs_to :payment

  def before_create
    self.payment = create_payment
    self.response = gateway.authorize(
      amount,
      payment_method.credit_card,
      :order_id => payment.vendor_tx_code,
      :authenticate => true
    )

    self.status = response.params['Status']
    self.status_detail = response.params['StatusDetail']

    if response.success?
      self.authorisation = response.authorization
      payment.vpstxid = response.params['VPSTxId']
      payment.security_key = response.params['SecurityKey']
      payment.tx_auth_no = response.params['TxAuthNo']
      payment.save!
    end
  end

  def capture(amount = self.amount)
    Capture.create(
      :payment_id => payment.id,
      :authorization => authorisation,
      :amount => amount
    )
  end

  def void
    Void.create(
      :payment_id => payment.id,
      :authorization => authorisation
    )
  end
end
