# frozen_string_literal: true

require 'bundler/setup'
Bundler.require

module Home
  class Index
    def self.call(env)
      session = env['rack.session']

      template = ERB.new(File.read('app/views/index.html.erb'))
      response_body = template.result_with_hash(message: session[:message])

      session[:message] = nil

      [200, {}, [response_body]]
    end
  end
end

module Session
  class SignIn
    def self.call(env)
      env['warden'].authenticate!

      [302, { 'location' => '/dashboard' }, []]
    end
  end

  class SignOut
    def self.call(env)
      env['warden'].logout

      [302, { 'location' => '/' }, []]
    end
  end

  class Fail
    def self.call(env)
      session = env['rack.session']
      session[:message] = env['warden'].message

      [302, { 'location' => '/' }, []]
    end
  end
end

module Dashboard
  class Index
    def self.call(env)
      env['warden'].authenticate!

      current_user = env['warden'].user

      template = ERB.new(File.read('app/views/dashboard.html.erb'))
      response_body = template.result_with_hash(user: current_user)

      [200, {}, [response_body]]
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
end

Warden::Manager.serialize_into_session(&:id)

Warden::Manager.serialize_from_session do |id|
  User.get(id)
end

Warden::Strategies.add(:password) do
  def valid?
    params['email'] || params['password']
  end

  def authenticate!
    user = User.authenticate(params['email'], params['password'])
    user ? success!(user) : fail!('Could not log in')
  end
end

use Rack::Session::Cookie,
    secret: '7Uoq3bzrXnJVMK.9a-AVCubg!ZN!D2FhT@y*MWpsdrhtcrT@ngi!c-dKM!GL4_wK'

use Warden::Manager do |config|
  config.default_strategies :password
  config.failure_app = Session::Fail
end

app = Hanami::Router.new do
  get '/', to: Home::Index
  post '/sign_in', to: Session::SignIn
  get '/sign_out', to: Session::SignOut
  get '/dashboard', to: Dashboard::Index
end

run app
