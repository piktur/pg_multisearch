# frozen_string_literal: true

module PgMultisearch
  Type = Struct.new(:klass, :index) do
  end
  private_constant :Type
end
