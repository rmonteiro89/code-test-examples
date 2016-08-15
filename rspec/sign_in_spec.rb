require 'authentication/sign_in'

describe Authentication::SignIn do
  context 'when authentication is succesfull' do
    it 'generates a token' do
      token_class = token_class_double
      user = user_double(id: 123, type: 'foo')
      auth_strategy = auth_strategy_double
      allow(token_class).to receive(:create).with(token_data: {user_id: user.id, user_type: user.type}).and_return(123)

      sign_in = described_class.new(user, {}, other_strategies: {random_strategy: auth_strategy}, token_class: token_class)

      expect(auth_strategy).to receive(:validate)
      expect(sign_in.authenticate_with(:random_strategy)).to eq 123
    end
  end

  def user_double(args = {})
    double('User', args)
  end

  def token_class_double
    double('token_class')
  end

  def auth_strategy_double(args = {})
    double('auth_strategy', args)
  end
end
