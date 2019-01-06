# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/base'

%w(
  install
  migration
  install/install_generator
  migration/index_generator
  rebuild/rebuild_generator
).each { |f| require_relative "./generators/#{f}.rb" }
