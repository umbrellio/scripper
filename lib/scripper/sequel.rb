# frozen_string_literal: true

module Scripper
  module Sequel
    class << self
      def strip(object, **args)
        if object.is_a?(Hash)
          strip_dataset(object)
        else
          strip_model(object, **args)
        end
      end

      private

      def strip_model(*args)
        ModelStripper.strip(*args)
      end

      def strip_dataset(ds)
        DatasetStripper.strip(ds)
      end
    end
  end
end
