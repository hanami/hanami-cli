#!/bin/bash
set -euo pipefail

JRUBY=false
if [ "$(ruby -e 'print RUBY_ENGINE')" = "jruby" ]; then
  JRUBY=true
  export DATABASE_URL="${E2E_JDBC_DATABASE_URL:?E2E_JDBC_DATABASE_URL must be set on JRuby}"
else
  export DATABASE_URL="${E2E_DATABASE_URL:?E2E_DATABASE_URL must be set}"
fi

list_tables() {
  case "$E2E_DB" in
    mysql|mariadb)
      MYSQL_PWD=password mysql --host=127.0.0.1 --port="${E2E_DB_PORT:?E2E_DB_PORT must be set for $E2E_DB}" \
        --user=root --batch --execute="SHOW TABLES FROM $E2E_DB_NAME" | tee tables.log
      ;;
    postgres)
      psql "${E2E_DATABASE_URL:?E2E_DATABASE_URL must be set for $E2E_DB}" --command="\dt" | tee tables.log
      ;;
    sqlite)
      sqlite3 "${E2E_DB_FILE:?E2E_DB_FILE must be set for sqlite}" ".tables" | tee tables.log
      ;;
  esac
}

# Generate a new app
bundle exec exe/hanami new testapp --database="$E2E_DATABASE_FLAG" --skip-assets --skip-install
test -d testapp/config/db/migrate

echo "gem \"hanami-cli\", path: \"$GITHUB_WORKSPACE\"" >> testapp/Gemfile
grep -q 'gem "hanami-cli", path:' testapp/Gemfile

# Currently we need hanami-reloader from main and dry-cli from main for app to work
sed -i 's|^\([[:space:]]*\)gem "hanami-reloader".*|\1gem "hanami-reloader", github: "hanami/hanami-reloader", branch: "main"|' testapp/Gemfile
echo 'gem "dry-cli", github: "dry-rb/dry-cli", branch: "main"' >> testapp/Gemfile

if [ "$JRUBY" = "true" ]; then
  case "$E2E_DATABASE_FLAG" in
    sqlite)
      original_gem="sqlite3"
      jdbc_gem="jdbc-sqlite3"
      ;;
    postgres)
      original_gem="pg"
      jdbc_gem="jdbc-postgres"
      ;;
    mysql)
      original_gem="mysql2"
      jdbc_gem="jdbc-mysql"
      ;;
  esac

  sed -i "s#^gem \"${original_gem}\"#gem \"${jdbc_gem}\"#" testapp/Gemfile
  grep -q "gem \"${jdbc_gem}\"" testapp/Gemfile
fi

cd testapp
bundle install

# Create database
bundle exec hanami db create | tee create.log
grep -q "database $E2E_DB_NAME created" create.log

# Generate migration
bundle exec hanami generate migration create_posts | tee generate.log
grep -q "Created config/db/migrate/.*_create_posts.rb" generate.log
MIGRATION=$(ls config/db/migrate/*_create_posts.rb)
printf '%s\n' \
  'ROM::SQL.migration do' \
  '  change do' \
  '    create_table :posts do' \
  '      primary_key :id' \
  '      column :title, :text, null: false' \
  '    end' \
  '  end' \
  'end' > "$MIGRATION"
cat "$MIGRATION"

# Migrate
bundle exec hanami db migrate --no-dump | tee migrate.log
grep -q "database $E2E_DB_NAME migrated" migrate.log

# Check posts table exists
list_tables
grep -q "posts" tables.log
grep -q "schema_migrations" tables.log

# Dump structure
bundle exec hanami db structure dump | tee dump.log
grep -q "structure dumped to config/db/structure.sql" dump.log
grep -qi "CREATE TABLE.*posts" config/db/structure.sql

# Rollback
bundle exec hanami db rollback --no-dump | tee rollback.log
grep -q "rolled back" rollback.log

# Check posts table is gone
list_tables
if grep -qw "posts" tables.log; then
  echo "ERROR: posts table still exists after rollback"
  exit 1
fi

# Drop and recreate the database, so the structure dump loads into an empty database
# (sqlite and postgres dumps contain plain CREATE TABLE statements, unlike mysqldump output,
# so loading over existing tables would fail)
bundle exec hanami db drop | tee drop.log
grep -q "database $E2E_DB_NAME dropped" drop.log
bundle exec hanami db create | tee create.log
grep -q "database $E2E_DB_NAME created" create.log

# Load structure dump
bundle exec hanami db structure load | tee load.log
grep -q "structure loaded from config/db/structure.sql" load.log

# Check posts table is back
list_tables
grep -qw "posts" tables.log
