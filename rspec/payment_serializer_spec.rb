require 'rails_helper'

RSpec.describe Api::V1::PaymentSerializer, type: :serializer do
  it 'returns the payment object with the rights attributes' do
    gateway = FactoryGirl.create(:paypal, account: Account.create)
    payment = FactoryGirl.create(:payment, :with_client, gateway: gateway)
                         .reload

    hash = JSON.parse(Api::V1::PaymentSerializer.new(payment).to_json)

    expect(hash).to eq expected_hash(payment)
  end

  def expected_hash(payment)
    JSON.parse(
      {
        payment:  {
          id: payment.id,
          uuid: payment.uuid,
          amount: payment.amount,
          currency_code: payment.currency_code,
          status: payment.status_humanize,
          metadata: payment.metadata,
          paypal_payment_url: payment.paypal_payment_url,
          gateway_transaction_id: payment.user_transaction_id,
          created_at: payment.created_at,
          updated_at: payment.updated_at,
          gateway: Api::V1::GatewaySerializer.new(payment.gateway).attributes,
          client: Api::V1::ClientSerializer.new(payment.client).attributes,
          subscription: payment.subscription,
          request: payment.request,
          plan: payment.plan,
          period_start: payment.period_start,
          period_end: payment.period_end,
          next_payment_attempt: payment.next_payment_attempt,
          paid_at: payment.paid_at,
          credit_card_brand: payment.credit_card_brand,
          credit_card_last4: payment.credit_card_last4
        }
      }.to_json
    )
  end
end
