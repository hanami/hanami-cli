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
gem "hanami-assets", github: "hanami/assets", branch: "main"
gem "hanami-controller", github: "hanami/controller", branch: "main"
gem "hanami-db", github: "hanami/db", branch: "main"
gem "hanami-router", github: "hanami/router", branch: "main"
gem "hanami-utils", github: "hanami/utils", branch: "main"

gem "dry-system", github: "dry-rb/dry-system", branch: "main"

if ENV["RACK_MATRIX_VALUE"]
  gem "rack", ENV["RACK_MATRIX_VALUE"]
end

gem "puma"

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
