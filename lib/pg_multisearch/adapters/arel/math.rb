# frozen_string_literal: true

module PgMultisearch::Adapters::Arel::Math
  def *(left, right)
    ::Arel::Nodes::Multiplication.new(left, right)
  end

  def +(left, right)
    ::Arel::Nodes::Grouping.new(::Arel::Nodes::Addition.new(left, right))
  end

  def -(left, right)
    ::Arel::Nodes::Grouping.new(::Arel::Nodes::Subtraction.new(left, right))
  end

  def /(left, right)
    ::Arel::Nodes::Division.new(left, right)
  end

  def eq(left, right)
    ::Arel::Nodes::Equality.new(left, right)
  end

  def gt(left, right)
    ::Arel::Nodes::GreaterThan.new(left, right)
  end

  def avg(*args)
    args.reduce(&:+) / args.length
  end

  def fn?(other)
    public_methods.include?(other)
  end
end
