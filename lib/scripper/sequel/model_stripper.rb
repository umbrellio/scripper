# frozen_string_literal: true

module Scripper
  module Sequel
    module ModelStripper
      class << self
        def strip(object, with_associations: nil, with_attributes: nil)
          association_fields = build_association_fields(object, with_associations)
          attribute_fields = build_attribute_fields(object, with_attributes)

          attrs = {
            **convert_values(object.values),
            **association_fields,
            **attribute_fields,
          }

          struct_klass = Struct.new(*attrs.keys)
          struct_klass.new(*attrs.values)
        end

        private

        def build_association_fields(object, associations)
          return {} if associations.nil?

          if associations.is_a?(Array)
            build_association_fields_from_array(object, associations)
          else # consider associations a hash
            build_association_fields_from_hash(object, associations)
          end
        end

        def build_attribute_fields(object, attributes)
          return {} if attributes.nil?

          convert_values(attributes)
        end

        def convert_values(hsh)
          hsh.transform_values { |v| ValueConverter.convert_value(v) }
        end

        def build_association_fields_from_array(object, associations)
          associations.reduce({}) do |acc, association|
            association_value = object.public_send(association)
            stripped_association_value =
              if association_value.is_a?(Array)
                association_value.map { |obj| strip(obj) }
              else
                strip(association_value)
              end

            acc.merge(association.to_sym => stripped_association_value)
          end
        end

        def build_association_fields_from_hash(object, associations)
          associations.entries.reduce({}) do |acc, (association, condition)|
            association_ds = object.class.association_reflection(association).associated_dataset

            acc.merge(
              association.to_sym => condition.call(association_ds).all.map { |obj| strip(obj) },
            )
          end
        end
      end
    end
  end
end
