# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :roles do
      primary_key :id
      column :user_id, :bigint
      column :title, :text
    end
  end

  down do
    drop_table :roles
  end
end
