# frozen_string_literal: true

module Scripper
  module Sequel
    module DatasetStripper
      class << self
        def strip(hsh)
          struct_klass = Struct.new(*hsh.keys)
          struct_klass.new(*hsh.transform_values { |v| ValueConverter.convert_value(v) }.values)
        end
      end
    end
  end
end
