require 'support/api'

RSpec.describe Api::V1::SubscriptionsController, type: :controller do
  describe 'POST #create' do
    it 'returns 201 created' do
      user = FactoryGirl.build(:user_with_account)
      plan = FactoryGirl.create(:plan, account: user.account).reload
      client = FactoryGirl.create(:client, account: user.account).reload
      stub_current_user(user)

      post :create, params: params(plan, client)
        .merge(api_token: user.account.api_token)

      expect(response.status).to eq 201
      expect(user.account.plans.last.subscriptions).to_not be_empty
      expect(JSON.parse(response.body)).to include('subscription')
    end

    it 'returns unauthorized 401 when authentication fails' do
      plan = double('plan', uuid: '123')
      client = double('client', uuid: '123')
      post :create, params: params(plan, client)

      expect(response.status).to eq 401
    end

    it 'returns 404 when cant find plan by uuid' do
      user = FactoryGirl.build(:user_with_account)
      plan = double('plan', uuid: '123')
      client = FactoryGirl.create(:client, account: user.account).reload
      stub_current_user(user)

      post :create, params: params(plan, client)
        .merge(api_token: user.account.api_token)

      expect(response.status).to eq 404
    end

    it 'returns 404 when cant find client by uuid' do
      user = FactoryGirl.build(:user_with_account)
      plan = FactoryGirl.create(:plan, account: user.account).reload
      client = double('client', uuid: '123')
      stub_current_user(user)

      post :create, params: params(plan, client)
        .merge(api_token: user.account.api_token)

      expect(response.status).to eq 404
    end

    it 'returns 422 when raises ProcessSubscriptionViaGatewayError' do
      user = FactoryGirl.build(:user_with_account)
      plan = FactoryGirl.create(:plan, account: user.account).reload
      client = FactoryGirl.create(:client, account: user.account).reload
      stub_current_user(user)
      allow_any_instance_of(Subscription)
        .to receive(:create_via_gateway)
        .and_raise(ProcessSubscriptionViaGatewayError.new('Gateway error'))

      post :create, params: params(plan, client)
        .merge(api_token: user.account.api_token)

      expect(response.status).to eq 422
    end
  end

  describe 'PATCH #update' do
    it 'returns 200 ok' do
      user = FactoryGirl.build(:user_with_account)
      plan = FactoryGirl.create(:plan, account: user.account).reload
      client = FactoryGirl.create(:client, account: user.account).reload
      subscription = FactoryGirl.create(:subscription, client: client, plan: plan).reload
      stub_current_user(user)

      new_plan = FactoryGirl.create(:plan, name: 'NewPlan',
                                           account: user.account).reload

      patch :update, params: { plan_uuid: new_plan.uuid }
        .merge(api_token: user.account.api_token, uuid: subscription.uuid)

      expect(response.status).to eq 200
      expect(client.subscriptions.by_plan(new_plan)).to_not be_empty
      expect(JSON.parse(response.body)).to include('subscription')
    end

    it 'returns 404 when subscription not found' do
      user = FactoryGirl.build(:user_with_account)
      stub_current_user(user)

      patch :update, params: { api_token: user.account.api_token, uuid: '123' }

      expect(response.status).to eq 404
    end

    it 'returns 404 when plan not found by uuid' do
      user = FactoryGirl.build(:user_with_account)
      plan = FactoryGirl.create(:plan, account: user.account).reload
      client = FactoryGirl.create(:client, account: user.account).reload
      subscription = FactoryGirl.create(:subscription, client: client,
                                                       plan: plan).reload
      stub_current_user(user)

      patch :update, params: { plan_uuid: '123' }
        .merge(api_token: user.account.api_token, uuid: subscription.uuid)

      expect(response.status).to eq 404
    end

    it 'returns unauthorized 401 when authentication fails' do
      patch :update, params: { uuid: '123' }

      expect(response.status).to eq 401
    end

    it 'returns 422 when raises ProcessSubscriptionViaGatewayError' do
      user = FactoryGirl.build(:user_with_account)
      plan = FactoryGirl.create(:plan, account: user.account).reload
      client = FactoryGirl.create(:client, account: user.account).reload
      subscription = FactoryGirl.create(:subscription, client: client,
                                                       plan: plan).reload
      stub_current_user(user)
      allow_any_instance_of(Subscription)
        .to receive(:update_via_gateway)
        .and_raise(ProcessSubscriptionViaGatewayError.new('Gateway error'))
      new_plan = FactoryGirl.create(:plan, name: 'NewPlan',
                                           account: user.account).reload

      patch :update, params: { plan_uuid: new_plan.uuid }
        .merge(api_token: user.account.api_token, uuid: subscription.uuid)

      expect(response.status).to eq 422
    end
  end

  describe 'GET #show' do
    it 'returns 200 with the specific subscription' do
      user = FactoryGirl.build(:user_with_account)
      plan = FactoryGirl.create(:plan, name: 'Trial', account: user.account)
      client = FactoryGirl.create(:client, account: user.account).reload
      subscription = FactoryGirl.create(:subscription, client: client,
                                                       plan: plan).reload
      stub_current_user(user)

      get :show, params: { api_token: user.account.api_token,
                           uuid: subscription.uuid }

      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to include('subscription')
    end

    it 'returns unauthorized 401 when authentication fails' do
      get :show, params: { api_token: 'bla', uuid: '123' }

      expect(response.status).to eq 401
    end

    it 'returns 404 when plan not found by uuid' do
      user = FactoryGirl.build(:user_with_account)
      stub_current_user(user)

      get :show, params: { api_token: user.account.api_token,
                           uuid: '123' }

      expect(response.status).to eq 404
    end
  end

  def params(plan, client, options = {})
    {
      plan_uuid: plan.uuid,
      client_uuid: client.uuid,
      gateway_name: options[:gateway_name],
      metadata: { test: 'metadata123' },
      billing: {
        number: '4242424242424242',
        cvc: '123',
        exp_month: Date.today.month,
        exp_year: Date.today.year + 1
      }
    }
  end
end
