# frozen_string_literal: true

ENV['DATABASE_URL'] ||= 'postgres://localhost/pg_multisearch_test'

%w(
  rails
  action_controller/railtie
  active_record/railtie
).each { |f| require f }

Bundler.require(*Rails.groups)

require 'securerandom'

module Test
  class Application < ::Rails::Application
    config.action_controller.allow_forgery_protection = false
    config.action_controller.perform_caching          = false
    config.action_dispatch.show_exceptions            = false
    config.active_support.deprecation                 = :stderr
    config.cache_classes                              = ::Rails.env.production?
    config.consider_all_requests_local                = true
    config.eager_load                                 = ::Rails.env.production?
    config.root                                       = ::Dir.pwd
    config.secret_key_base                            = ::SecureRandom.hex(64)
    config.secret_token                               = ::SecureRandom.hex(64)
    config.serve_static_assets                        = false

    routes.draw do
      get '/search' => 'test/search#call'
    end
  end
end

Test::Application.initialize!
