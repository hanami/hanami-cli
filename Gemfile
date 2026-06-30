# frozen_string_literal: true

source "https://rubygems.org"

gemspec

eval_gemfile "Gemfile.devtools"

unless ENV["CI"]
  gem "byebug", platforms: :mri
  gem "yard"
  gem "yard-junk"
end

gem "hanami", github: "hanami/hanami", branch: "main"
gem "hanami-assets", github: "hanami/hanami-assets", branch: "main"
gem "hanami-action", github: "hanami/hanami-action", branch: "main"
gem "hanami-db", github: "hanami/hanami-db", branch: "main"
gem "hanami-router", github: "hanami/hanami-router", branch: "main"
gem "hanami-utils", github: "hanami/hanami-utils", branch: "main"

gem "dry-system", github: "dry-rb/dry-system", branch: "main"

if ENV["RACK_MATRIX_VALUE"]
  gem "rack", ENV["RACK_MATRIX_VALUE"]
end

gem "puma"

# Work around RDoc/JRuby incompatibiltiy: rdoc 8 depends on rbs 4, whose native C extension can't
# build on JRuby.
#
# Remove this once https://github.com/ruby/rdoc/issues/1746 is resolved.
gem "rdoc", "< 8.0"

platforms :ruby do
  gem "mysql2"
  gem "pg"
  gem "sqlite3"
end

platforms :jruby do
  gem "jdbc-sqlite3"
  gem "jdbc-mysql"
  gem "jdbc-postgres"
end

gem "hanami-devtools", github: "hanami/devtools", branch: "main"

group :test do
  gem "pry"
  gem "readline"
  gem "rspec", "~> 3.9"
  gem "ostruct", require: false
end
