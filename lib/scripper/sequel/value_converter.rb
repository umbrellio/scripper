# frozen_string_literal: true

module Scripper
  module Sequel
    module ValueConverter
      class << self
        def convert_value(value)
          if value.is_a?(::Sequel::Postgres::JSONHashBase)
            value.to_h
          elsif value.is_a?(::Sequel::Postgres::JSONArrayBase)
            value.to_a
          elsif value.is_a?(::Sequel::Postgres::PGArray)
            value.to_a
          elsif value.is_a?(BigDecimal)
            value.to_f
          else
            value
          end
        end
      end
    end
  end
end
