# Payment Serializer
class Api::V1::PaymentSerializer < ActiveModel::Serializer
  attributes :id, :uuid, :amount, :currency_code, :status, :metadata,
             :paypal_payment_url, :gateway_transaction_id, :period_start,
             :period_end, :next_payment_attempt, :paid_at,
             :created_at, :updated_at, :gateway, :client, :subscription,
             :request, :plan, :credit_card_brand, :credit_card_last4

  def status
    object.status_humanize
  end

  def client
    Api::V1::ClientSerializer.new(object.client).attributes
  end

  def gateway
    Api::V1::GatewaySerializer.new(object.gateway).attributes
  end

  def gateway_transaction_id
    object.user_transaction_id
  end

  def subscription
    if object.subscription.present?
      Api::V1::SubscriptionSerializer.new(object.subscription).attributes
    end
  end

  def plan
    Api::V1::PlanSerializer.new(object.plan).attributes if object.plan.present?
  end

  def request
    if object.request.present?
      Api::V1::RequestSerializer.new(object.request).attributes
    end
  end
end
