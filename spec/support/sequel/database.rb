# frozen_string_literal: true

require "sequel"
require_relative "database_helper.rb"

Sequel.extension :migration

::DB_HELPER ||= DatabaseHelper.new
