require 'authentication/token'
require 'authentication/password_strategy'

module Authentication
  class SignIn

    def initialize(user, params, token_class: Token, other_strategies: {})
      @user = user
      @params = params
      @token_class = token_class
      @other_strategies = other_strategies
    end

    def authenticate_with(auth_strategy)
      strategies[auth_strategy].validate
      @token_class.create(token_data: {user_id: @user.id, user_type: @user.type})
    end

    private
    def strategies
      {
        password: PasswordStrategy.new(user: @user, password: @params[:password])
      }.merge(@other_strategies)
    end
  end
end
