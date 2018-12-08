# frozen_string_literal: true

db = Gemika::Database.new
db.connect

# ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

db.rewrite_schema! do
  # @todo Define DB schema here
end
