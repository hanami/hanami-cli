# frozen_string_literal: true

require_relative "sqlite"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Utils
            class JdbcSqlite < Sqlite
              # @api private
              # @since 2.4.0
              def name
                # For JDBC SQLite URIs like "jdbc:sqlite:db/app.sqlite3",
                # we need to extract the path part after "jdbc:sqlite:"
                # The standard URI.parse doesn't handle JDBC URIs well, so we parse manually
                database_url.sub(%r{^jdbc:sqlite:}, "")
              end
            end
          end
        end
      end
    end
  end
end
