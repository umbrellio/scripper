# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :payments do
      primary_key :id
      column :actor_id, :bigint
      column :amount, :numeric
    end
  end

  down do
    drop_table :payments
  end
end
