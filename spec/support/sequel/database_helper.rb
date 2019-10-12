# frozen_string_literal: true

class DatabaseHelper
  DATABASE_URL = ENV["DB_URL"] || "postgres://localhost/scripper_test"

  def migrate_up
    Sequel.connect(DATABASE_URL) do |db|
      Sequel::TimestampMigrator.new(db, "spec/fixtures/sequel/migrations").run
    end
  end

  def migrate_down
    Sequel.connect(DATABASE_URL) do |db|
      db.tables.each { |t| db.drop_table?(t, cascade: true) }
    end
  end

  def clear
    Sequel.connect(DATABASE_URL) do |db|
      db.tables.each { |t| db.run("DELETE FROM #{t} WHERE true") }
    end
  end
end
