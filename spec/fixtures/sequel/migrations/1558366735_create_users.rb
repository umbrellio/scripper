# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :users do
      primary_key :id
      column :email, :text
      column :password, :text
      column :preferences, :jsonb, default: "{}"
      column :cars, :jsonb, default: "[]"
      column :pseudonyms, "text[]"
      column :loc_written, :numeric
    end
  end

  down do
    drop_table :users
  end
end
