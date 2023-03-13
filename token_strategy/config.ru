# frozen_string_literal: true

require 'bundler/setup'
Bundler.require

require 'json'

module Session
  class SignIn
    def self.call(env)
      request = Rack::Request.new(env)
      params = request.params

      user = User.authenticate(params['email'], params['password'])

      if user
        env['warden'].set_user(user, store: false)

        response = { ok: true }

        [200, { 'content-type' => 'application/json' }, ["#{response.to_json}\n"]]
      else
        [403, {}, ["Erro no login\n"]]
      end
    end
  end

  class SignOut
    def self.call(_env)
      response = { ok: true }
      [200, { 'content-type' => 'application/json' }, ["#{response.to_json}\n"]]
    end
  end

  class Fail
    def self.call(_env)
      [401, {}, ['Fail']]
    end
  end
end

module Dashboard
  class Index
    def self.call(env)
      env['warden'].authenticate!

      user = env['warden'].user

      response = {
        user: {
          id: user.id,
          name: user.name,
          email: user.email
        }
      }

      [200, {}, ["#{response.to_json}\n"]]
    end
  end
end

class User
  LIST = [
    {
      id: 1,
      name: 'Developer',
      email: 'developer@developer.com',
      password: '12345678'
    }
  ].freeze

  attr_accessor :id, :name, :email

  def self.authenticate(email, password)
    user = LIST.find do |u|
      u[:email] == email && u[:password] == password
    end

    new(id: user[:id], name: user[:name], email: user[:email]) if user
  end

  def self.get(id)
    user = LIST.find { |u| u[:id] == id }
    new(id: user[:id], name: user[:name], email: user[:email])
  end

  def initialize(id:, name:, email:)
    @id = id
    @name = name
    @email = email
  end

  def jwt_subject
    id
  end
end

class UserRepo
  def self.find_for_jwt_authentication(sub)
    User.get(sub.to_i)
  end
end

class RevocationStrategy
  def self.revoke_jwt(payload, user)
    # TODO: Do something to revoke a JWT token
  end

  def self.jwt_revoked?(payload, user)
    # TODO: Do something to check whether a JWT token is revoked
  end
end

Warden::JWTAuth.configure do |config|
  config.secret = '7Uoq3bzrXnJVMK.9a-AVCubg!ZN!D2FhT@y*MWpsdrhtcrT@ngi!c-dKM!GL4_wK'
  config.mappings = { default: UserRepo }
  config.dispatch_requests = [['POST', %r{^/sign_in$}]]
  config.revocation_requests = [['DELETE', %r{^/sign_out$}]]
  config.revocation_strategies = { default: RevocationStrategy }
end

Warden::Strategies.add(:jwt) do
  def valid?
    !token.nil?
  end

  def store?
    false
  end

  def authenticate!
    aud = Warden::JWTAuth::EnvHelper.aud_header(env)
    user = Warden::JWTAuth::UserDecoder.new.call(token, scope, aud)
    success!(user)
  rescue JWT::DecodeError => e
    fail!(e.message)
  end

  private

  def token
    @token ||= Warden::JWTAuth::HeaderParser.from_env(env)
  end
end

use Warden::JWTAuth::Middleware

use Warden::Manager do |config|
  config.default_strategies :jwt
  config.failure_app = Session::Fail
end

app = Hanami::Router.new do
  post '/sign_in', to: Session::SignIn
  delete '/sign_out', to: Session::SignOut
  get '/user_info', to: Dashboard::Index
end

run app
