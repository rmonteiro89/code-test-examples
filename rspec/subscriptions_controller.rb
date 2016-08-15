# Subscription API for Jobo
class Api::V1::SubscriptionsController < Api::V1::BaseController
  before_action :authenticate_user!

  def create
    account = current_user.account
    plan = account.plans.find_by!(uuid: permitted_params.fetch(:plan_uuid))
    subscription = plan.subscriptions.build(metadata_params)
    subscription.client =
      account.clients.find_by!(uuid: permitted_params.fetch(:client_uuid))
    subscription.gateway =
      plan.find_active_gateway_by_name(permitted_params[:gateway_name])

    subscription.create_via_gateway(process_subscription_options)
    subscription.save!

    render json: subscription.reload,
           serializer: Api::V1::SubscriptionSerializer,
           status: :created
  rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing,
         ProcessSubscriptionViaGatewayError => e
    render_errors(422, e.message)
  end

  def update
    account = current_user.account
    plan = account.plans.find_by!(uuid: permitted_params[:plan_uuid])
    subscription = Subscription.find_by!(uuid: params[:uuid])
    subscription.plan = plan
    gateway = plan.find_active_gateway_by_name(permitted_params[:gateway_name])
    subscription.gateway = gateway if gateway.present?

    subscription.update_via_gateway(process_subscription_options)
    subscription.save!

    render json: subscription.reload,
           serializer: Api::V1::SubscriptionSerializer,
           status: :ok
  rescue ActiveRecord::RecordInvalid, ProcessSubscriptionViaGatewayError,
         ActionController::ParameterMissing => e
    render_errors(422, e.message)
  end

  def show
    subscription = Subscription.find_by!(uuid: params[:uuid])

    render json: subscription, serializer: Api::V1::SubscriptionSerializer,
           status: 200
  end

  private

  def process_subscription_options
    {}.merge(redirect_urls_params.to_h[:redirect_urls] || {})
      .merge(billing_params.to_h[:billing] || {})
  end

  def permitted_params
    params.permit(:plan_uuid, :client_uuid, :gateway_name)
  end

  def metadata_params
    metadata_keys = params[:metadata].try(:keys)
    params.permit(metadata: metadata_keys)
  end

  def billing_params
    params.permit(billing: [:number, :cvc, :exp_month, :exp_year])
  end

  def redirect_urls_params
    params.permit(redirect_urls: [:cancel_url, :return_url])
  end
end
