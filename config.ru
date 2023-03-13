# frozen_string_literal: true

require 'bundler/setup'
Bundler.require

app = Hanami::Router.new do
  get '/', to: ->(_env) { [200, {}, ['Hello World']] }
end

run app
