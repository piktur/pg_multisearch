# frozen_string_literal: true

%w(
  rails
  action_controller/railtie
).each { |f| require f }

Bundler.require(*Rails.groups)

require 'securerandom'

module Test
  class Application < ::Rails::Application
    config.root                                       = ::Dir.pwd
    config.cache_classes                              = ::Rails.env.production?
    config.eager_load                                 = ::Rails.env.production?
    config.serve_static_assets                        = false
    config.consider_all_requests_local                = true
    config.action_dispatch.show_exceptions            = false
    config.action_controller.perform_caching          = false
    config.action_controller.allow_forgery_protection = false
    config.active_support.deprecation                 = :stderr

    secrets.secret_token    = ::ENV.fetch('SECRET_TOKEN') { ::SecureRandom.hex(64) }
    secrets.secret_key_base = ::ENV.fetch('SECRET_KEY_BASE') { ::SecureRandom.hex(64) }

    routes.draw do
      get '/search' => 'test/search#call'
    end
  end

  class Search < ::PgMultisearch::Search; end

  class SearchController < ::ActionController::Metal
    def call
      @search = Search.new(params[:search])
      @results = @search.to_a
    end
  end
end
