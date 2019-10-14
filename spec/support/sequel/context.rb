# frozen_string_literal: true

require "logger"
require_relative "database.rb"

RSpec.shared_context "sequel context" do
  after(:all) { DB_HELPER.migrate_down }

  after(:example) { DB_HELPER.clear }

  DB_HELPER.migrate_up

  logger_args =
    if ENV["LOG_DB"]
      { loggers: [Logger.new($stdout)] }
    else
      {}
    end

  DB = Sequel.connect(DatabaseHelper::DATABASE_URL, **logger_args).tap do |db|
    db.extension :pg_json
    db.extension :pg_array
  end

  class User < Sequel::Model(DB[:users])
    one_to_many :cookies, class: "Cookie"
    one_to_one :role, class: "Role"
  end

  class Cookie < Sequel::Model(DB[:cookies]); end

  class Role < Sequel::Model(DB[:roles]); end

  let(:user_model) do
    User
  end

  let(:cookie_model) do
    Cookie
  end

  let(:role_model) do
    Role
  end
end
