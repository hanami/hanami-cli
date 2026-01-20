# frozen_string_literal: true

require_relative "mysql"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Utils
            class JdbcMysql < Mysql
              # @api private
              # @since 2.4.0
              def name
                # For JDBC MySQL URIs like "jdbc:mysql://localhost/mydb",
                # we need to extract the database name from the path
                # The standard URI.parse doesn't handle JDBC URIs well, so we parse manually
                database_url.sub(%r{^jdbc:mysql://[^/]*/?}, "").sub(%r{^/}, "")
              end
            end
          end
        end
      end
    end
  end
end
