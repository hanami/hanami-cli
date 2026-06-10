# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Break Versioning](https://www.taoensso.com/break-versioning).

## [Unreleased]

### Added

- Include `hanami-mailer` in the default `Gemfile`, and generate a base `Mailer` class for the app and each slice (`app/mailer.rb` and `mailer.rb` in slices). Use `hanami new --skip-mailer` to opt out. (@timriley in #420)
- Add `generate provider` command. (@timriley in #419)
- Add `i18n` gem to the default `Gemfile`, and generate a placeholder `config/i18n/en.yml` for the app and each generated slice. (@timriley)
- Add `--name` option to `hanami new`, to specify a custom module namespace while using the positional argument as the directory path. For example, `hanami new my_bookshelf --name=bookshelf` creates the app in `my_bookshelf/` with `Bookshelf` as the module name. (@aaronmallen in #387)
- Add `--template-engine` option to `hanami generate` and `hanami new` to specify which template engine should be used for generated template files. Supports `erb`, `haml` and `slim`. (@katafrakt in #280, #389, #390)
- Add `--test` option to `hanami new` to specify which test framework to use. Supports `rspec` (default) and `minitest`. (@timriley in #399)
- Add `--force` option to all generators (except migration), which will override existing files instead of exiting early (@katafrakt in #397)

### Changed

- `hanami new` puts `dry-validation` in the app's `Gemfile` instead of `hanami-validations`. Hanami Validations will no longer be used; Hanami Action now checks for Dry Validation directly. (@timriley)
- Update for `hanami-controller` gem rename to `hanami-action`. (@cllns in #402)
- When `--gem-source=gem.coop` is used, Hanami and Dry gems are installed from their respective namespaces on gem.coop (@katafrakt in #424)

### Deprecated

### Removed

### Fixed

- Don't overwrite libpq ENV vars with empty strings (@StantonMatt in #414).
- Skip generating duplicate routes when running `generate action`. (@sandbergja in #417)

### Security

[Unreleased]: https://github.com/hanami/cli/compare/v2.3.5...HEAD

## [2.3.5] - 2026-02-06

### Changed

- In `assets` commands, provide the node command with the assets config path _relative to app root_ instead of an absolute path (`config/assets.js` instead of `/full/path/to/config/assets.js`). This allows the assets commands to work in environments where Node.js is "sandboxed" in such a way that it doesn't share the same absolute path. (@haileys in #381).

[2.3.4]: https://github.com/hanami/cli/compare/v2.3.4...v2.3.5

## [2.3.4] - 2026-01-23

### Fixed

- Avoid an unhandled exception in the "are we inside a Hanami app?" check that happens at the beginning of every CLI invocation. This would occur when a bundled gem is already activated (from our testing: bigdecimal) but in conflict with the required version of that gem by a Hanami dependency. (@timriley in #380).

[2.3.4]: https://github.com/hanami/cli/compare/v2.3.3...v2.3.4

## [2.3.3] - 2025-12-04

### Changed

- Support the newly released Bundler v4 by removing the upper version bound from our dependency. (@timriley in #373)

[2.3.3]: https://github.com/hanami/cli/compare/v2.3.2...v2.3.3

## [2.3.2] - 2025-11-16

### Fixed

- Fix potential deadlocks with `db structure dump` for large structure files. (@timriley in #370, report from @pat in #369)
- Decouple the hanami-assets npm package version from the current Hanami version in generated `package.json`, using the stable minor version (e.g. `^2.3.0`) instead of the exact version (e.g. `^2.3.1`). This allows Hanami patch releases without requiring a corresponding hanami-assets npm package release. (@timriley in #270)

[2.3.2]: https://github.com/hanami/cli/compare/v2.3.1...v2.3.2

## [2.3.1] - 2025-11-14

### Fixed

- Fix stray wording in `README.md` in new apps. (@davidcelis in #368)

[2.3.1]: https://github.com/hanami/cli/compare/v2.3.0...v2.3.1

## [2.3.0] - 2025-11-12

### Added

- Generate a `bin/setup` when generating new apps. (@davidcelis in #359)
- Generate `bin/hanami` and `bin/rake` binstubs when generating new apps. (@jaredcwhite in #344)
- Generate a view context class when generating new apps or slices. (@afomera in #350)
- Add `--gem-source` option to `hanami new`, to specify the gem source for your `Gemfile`. For example: `hanami new my_app --gem-source=gem.coop`. (@svooop in #356)

### Changed

- Print a one-time warning when accessing an un-booted slice’s `keys` in the console. (@timriley in #349)
- Add `--boot` flag to `console` command, which boots the Hanami app before loading the console. (@kyleplump in #331)
- In new apps, require dry-operation v1.0.1 in the generated `Gemfile`. This is necessary to pull in a fix required for Hanami’s automatic integration of Dry Operation with the database layer. (@timriley in #351)
- When generating new apps with `--head`, use the new GitHub repo names in the `Gemfile` (`"hanami/hanami-view"` instead of `"hanami/view"`). (@afomera in #354)
- When generating new apps with `--head`, add `"hanami-utils"` to the `Gemfile`. (@timriley in #362)
- In new apps, include a patch-level version (e.g. "~> 2.3.0") for Hanami gems in generated `Gemfile`, ensuring updates to the next minor version are only done intentionally. (@timriley in #367)

### Fixed

- When running `db rollback` in development, also rollback the test database. (@timriley in #355)
- Remove "restrict" and "unrestrict" statements (which constantly change, even if there are no structure changes) from Postgres structure dumps. (@rickenharp in #336)
- Remove "-- Dumped from" version comments from Postgres dumps (which will change based on the local client version). (@davidcelis in #358)
- Check for Postgres database existence in a more robust way. The previous method could fail if both the Postgres username and database name were the same. (@rickenharp in #332)
- Fix structure dump and load for MySQL 9.5.0. (@timriley in #348)
- Preserve Bundler environment variables when commands make system calls. (@robyurkowski in 346)

[2.3.0]: https://github.com/hanami/cli/compare/v2.3.0.beta2...v2.3.0

## [2.3.0.beta2] - 2025-10-17

### Added

- Add `hanami run` command, to run your own code. For example, `hanami run path/to/script.rb` or `hanami run 'puts Hanami.app["repos.user_repo"].all.count'`. (@afomera in #338)

### Changed

- Add `--skip-tests` flag to `generate action` command. (@kyleplump in #335)
- In new apps, updated generated types module to `Dry.Types(default: :strict)`. (@minaslater in #323)
- When generators add routes, add those routes to per-slice routes files (`config/routes.rb` within slice directories) if they exist. (@stephannv in #342)
- Drop support for Ruby 3.1

### Fixed

- Handle mixed case names given to `generate` subcommands. (@cllns in #327)

[2.3.0.beta2]: https://github.com/hanami/cli/compare/v2.3.0.beta1...v2.3.0.beta2

## [2.3.0.beta1] - 2025-10-03

### Added

- Running `hanami generate` commands within a slice directory will generate the file in that slice. (@krzykamil in #298)
- Add `db rollback` command, supporting rolling back a single database at a time. (@krzykamil in #300)
- `console` command loads configured extensions from app config. Add these using e.g. `config.console.include MyModule, AnotherModule`. (@alassek in #324)
- `console` command uses REPL engine configured in app config. Set this using e.g. `config.console.engine = :pry`; valid options are `:irb` (default) and `:pry`. (@alassek in #324)

### Changed

- Prevent `hanami new` from creating apps with confusing names (currently: "app" or "slice"). (@seven1m in #272)
- Provide more helpful instructions in generated app README. (@hanarimawi in #273)
- Prevent generators from overwriting files. (@maxemitchell in #274, @stephannv in #319)
- Add irb as a gem dependency to avoid default gem warnings. (@y-yagi in #294)
- Expand on comments `config/assets.js` and enable customization function by default. (@robyurkowski in #293)
- Run `git init` at the end of `hanami new`. (@krzykamil in #295)
- Prevent blank lines from showing when generating classes without deep module nesting. (@cllns)
- Add `--skip-view` flag to `hanami new`. (@kyleplump in #308)
- Support Rack 3 in addition to Rack 2 (for `hanami server` command). (@kyleplump in #289)
- Ensure compatibility with MySQL 9.4's CLI tools in `db structure load` command. (@timriley in #315)
- Generated `Rakefile` will load tasks defined in `lib/tasks/`. (@AlexanderZagaynov in #318)

### Fixed

- Allow generated `public/400.html` and `public/500.html` to go into source control. (@kyleplump in #290)
- Properly show database errors from failed `db drop` commands. (@katafrakt in #281)
- Ensure consistent env var loading by disallowing Foreman's own env processing in generated `bin/dev` script. (@cflipse in #305)
- Use the configured app inflector (and any custom inflections) for all commands. (@timriley in #312)
- For app generated with `hanami new` with `--head`, include `hanami-cli` in the `Gemfile`. (@afomera in #328)

[2.3.0.beta1]: https://github.com/hanami/cli/compare/v2.2.1...v2.3.0.beta1

## [2.2.1] - 2024-11-12

### Changed

- Run a bundle install inside `hanami install`. Combined with first-party extension gems modifying the new app's `Gemfile` via a `before "install"` command hook, this ensures that all necessary gems are installed during the `hanami new` command. (@timriley in #269)

### Fixed

- Allow `hanami new` to be called with `--skip-db`. (@timriley in #266)

[2.2.1]: https://github.com/hanami/cli/compare/v2.2.0...v2.2.1

## [2.2.0] - 2024-11-05

### Changed

- Add `--gateway` option to `generate relation`. (@kyleplump in #261)
- Depend on stable release of dry-operation in new app `Gemfile`. (@timriley in #262)
- Depend on newer dry-types with a simpler version constraint in new app `Gemfile`. (@timriley in #263)
- Point to Hanami's own migrations guide from generated migration files. (@alassek in #264)

[2.2.0]: https://github.com/hanami/cli/compare/v2.2.0.rc1...v2.2.0

## [2.2.0.rc1] - 2024-10-29

### Added

- Generate a `config/db/seeds.rb` file in new apps. (@timriley, @fbeausoleil in #255, #256)

### Changed

- Add `--env` and `-e` options to all app commands, for setting the Hanami env. (@timriley in #246)
- Keep test database in sync by applying `hanami db` commands to both development and test databases when invoked in development environment. (@timriley in #247)
- Add `--skip-route` flag to `generate action` and `generate slice` commands. (@kyleplump in #227)
- Include a `change do` block in generated migrations. (@timriley in #254)
- Generate MySQL database URL in `.env` that works with standard Homebrew MySQL installation. (@timriley in #249)
- Remove ROM extension boilerplate in operations generated by `hanami new` and `generate operation` (this is now applied automatically). (@timriley, @alassek in #240, #252)
- Print a warning when running `db seed` but expected seeds files could not be found. (@fbeausoleil in #256)
- Only register `generate` subcommands if the relevant gems are bundled. (@swilgosz in #242)
- When both IRB and pry are loaded, use IRB as the default engine for `hanami console`. (@asaunders in #182)

### Fixed

- Fix error dumping structure when there are no migrations. (@timriley in #244)
- Stop erroneous misconfigured DB warnings from `hanami db` commands when a database is configured once but shared across slices. (@timriley in #253)

[2.2.0.rc1]: https://github.com/hanami/cli/compare/v2.2.0.beta2...v2.2.0.rc1

## [2.2.0.beta2] - 2024-09-25

### Added

- MySQL support for `db` commands. (@timriley in #226)
- Support for multiple gateways in `db` commands. (@timriley in #232, #234, #237, #238)

### Changed

- Delete `.keep` files when generating new files into previously empty directory. (@kyleplump, @timriley in #224)
- Add `db/*.sqlite` to the `.gitignore` in new apps. (@cllns in #210)
- Print warnings for misconfigured databases when running `db` commands. (@cllns in #211)

[2.2.0.beta2]: https://github.com/hanami/cli/compare/v2.2.0.beta1...v2.2.0.beta2

## [2.2.0.beta1] - 2024-07-16

### Added

- Generate db files in `hanami new` and `generate slice`. (@cllns)
- Add `db` commands: `create`, `drop`, `migrate`, `structure dump` `structure load`, `seed` `prepare`, `version`. (@timriley)
- Support SQLite and Postgres for `db` commands. (@timriley)
- Add `generate` commands for db components: `generate migration`, `generate relation`, `generate repo`, `generate struct`. (@cllns)
- Add `generate component` command. (@krzykamil)
- Add `generate operation` command. (@cllns)

### Changed

- Drop support for Ruby 3.0

[2.2.0.beta1]: https://github.com/hanami/cli/compare/v2.1.1...v2.2.0.beta1

## [2.1.1] - 2024-03-19

### Fixed

- Properly pass INT signal to child processes when interrupting `hanami assets watch` command. (@ryanbigg)

[2.1.1]: https://github.com/hanami/cli/compare/v2.1.0...v2.1.1

## [2.1.0] - 2024-02-27

### Changed

- Underscore slice names in `public/assets/` to avoid naming conflicts with nested asset entry points. In this arrangement, an "admin" slice will have its assets compiled into `public/assets/_admin/`. (@timriley)

[2.1.0]: https://github.com/hanami/cli/compare/v2.1.0.rc3...v2.1.0

## [2.1.0.rc3] - 2024-02-16

### Changed

- For `hanami assets` commands, run a separate assets compilation process per slice (in parallel). (@timriley)
- Generate compiled assets into separate folders per slice, each with its own `assets.js` manifest file: `public/assets/` for the app, and `public/assets/[slice_name]/` for each slice. (@timriley)
- For `hanami assets` commands, directly detect and invoke the `config/assets.js` files. Look for this file within each slice, and fall back to the app-level file. (@timriley)
- Do not generate `"scripts": {"assets": "..."}` section in new app's `package.json`. (@timriley)
- Subclasses of `Hanami::CLI::Command` receive default args to their `#initialize` methods, and do not need to re-declare default args themselves. (@timriley)
- Alphabetically sort hanami gems in the new app `Gemfile`. (@parndt)

### Fixed

- Strip invalid characters from module name when generating new app. (@nishiki)

[2.1.0.rc3]: https://github.com/hanami/cli/compare/v2.1.0.rc2...v2.1.0.rc3

## [2.1.0.rc2] - 2023-11-08

### Added

- Add `--skip-tests` for `hanami generate` commands. This CLI option will skip tests generation. (@timriley)

### Changed

- Set `"type": "module"` in package.json, enabling ES modules by default. (@timriley)
- Rename `config/assets.mjs` to `config/assets.js` (use a plain `.js` file extension). (@timriley)

### Fixed

- Use correct helper names in generated app layout. (@timriley)
- Ensure to generate apps with correct pre-release version of `hanami-assets` NPM package. (@lucaguidi)
- Print to stderr NPM installation errors when running `hanami install`. (@cllns)
- Ensure to install missing gems after `hanami install` is ran. (@cllns)

[2.1.0.rc2]: https://github.com/hanami/cli/compare/v2.1.0.rc1...v2.1.0.rc2

## [2.1.0.rc1] - 2023-11-01

### Added

- `hanami new` to generate `bin/dev` as configuration for `hanami dev`. (@timriley)
- Introducing `hanami generate part` to generate view parts. (@lucaguidi)

### Changed

- `hanami new` generates a `config/assets.mjs` as Assets configuration. (@timriley)
- `hanami new` generates a leaner `package.json`. (@timriley)
- `hanami new` doesn't generate a default root route anymore. (@timriley)
- `hanami new` to generate a redesigned 404 and 500 error pages. (@aaronmoodie, @timriley)
- `hanami new` generates a fully documented Puma configuration in `config/puma.rb`. (@lucaguidi)
- When generating a RESTful action, skip `create`, if `new` is present, and `update`, if `edit` is present. (@lucaguidi)

[2.1.0.rc1]: https://github.com/hanami/cli/compare/v2.1.0.beta2...v2.1.0.rc1

## [2.1.0.beta2] - 2023-10-04

### Added

- `hanami new` generates `Procfile.dev`. (@lucaguidi)
- `hanami new` generates basic app assets, if `hanami-assets` is bundled by the app. (@lucaguidi)
- `hanami new` accepts `--head` to generate the app using Hanami HEAD version from GitHub. (@lucaguidi)
- `hanami generate slice` generates basic slice assets, if `hanami-assets` is bundled by the app. (@lucaguidi)
- `hanami generate action` generates corresponding view, if `hanami-view` is bundled by the app. (@ryanbigg)
- `hanami assets compile` to compile assets at the deploy time. (@lucaguidi)
- `hanami assets watch` to watch and compile assets at the development time. (@lucaguidi)
- `hanami dev` to start the processes in `Procfile.dev`. (@lucaguidi)

### Fixed

- `hanami new` generates a `Gemfile` with `hanami-webconsole` in `:development` group. (@lucaguidi)
- `hanami new` generates a `Gemfile` with versioned `hanami-webconsole`, `hanami-rspec`, and `hanami-reloader`. (@lucaguidi)

[2.1.0.beta2]: https://github.com/hanami/cli/compare/v2.1.0.beta1...v2.1.0.beta2

## [2.1.0.beta1] - 2023-06-29

### Added

- `hanami new` to generate default views, templates, and helpers. (@timriley)
- `hanami generate slice` to generate default views, templates, and helpers. (@timriley)
- `hanami generate action` to generate associated view and template. (@timriley)
- Introduced `hanami generate view`. (@timriley)
- `hanami new` to generate `Gemfile` with `hanami-view` and `hanami-webconsole` gems. (@timriley)
- `hanami new` to generate default error pages for `404` and `500` HTTP errors. (@timriley)

### Fixed

- `hanami server` to start only one Puma worker by default. (@parndt)

[2.1.0.beta1]: https://github.com/hanami/cli/compare/v2.0.3...v2.1.0.beta1

## [2.0.3] - 2023-02-01

### Added

- Generate a default `.gitignore` when using `hanami new`. (@lucaguidi)

### Fixed

- Ensure to run automatically bundle gems when using `hanami new` on Windows. (@dsisnero)
- Ensure to generate the correct action identifier in routes when using `hanami generate action` with deeply nested action name. (@lucaguidi)

[2.0.3]: https://github.com/hanami/cli/compare/v2.0.2...v2.0.3

## [2.0.2] - 2022-12-25

### Added

- Official support for Ruby 3.2. (@lucaguidi)

[2.0.2]: https://github.com/hanami/cli/compare/v2.0.1...v2.0.2

## [2.0.1] - 2022-12-06

### Fixed

- Ensure to load `.env` files during CLI commands execution. (@lucaguidi)
- Ensure `hanami server` to respect HTTP port used in `.env` or the value given as CLI argument (`--port`). (@lucaguidi)

[2.0.1]: https://github.com/hanami/cli/compare/v2.0.0...v2.0.1

## [2.0.0] - 2022-11-22

### Added

- Use Zeitwerk to autoload the gem. (@timriley)

### Fixed

- In case of internal exception, don't print the stack trace to stderr, print the error message, exit with 1. (@lucaguidi)
- Ensure to be able to run `hanami` CLI in Hanami app subdirectories. (@timriley)
- Return an error when trying to run `hanami new` with an existing target path (file or directory). (@cllns)

[2.0.0]: https://github.com/hanami/cli/compare/v2.0.0.rc1...v2.0.0

## [2.0.0.rc1] - 2022-11-08

[2.0.0.rc1]: https://github.com/hanami/cli/compare/v2.0.0.beta4...v2.0.0.rc1

## [2.0.0.beta4] - 2022-10-24

### Changed

- Show output when generating files (e.g. in `hanami new`). (@cllns in #49)
- Advertise Bundler and Hanami install steps when running `hanami new`. (@lucaguidi in #54)

[2.0.0.beta4]: https://github.com/hanami/cli/compare/v2.0.0.beta3...v2.0.0.beta4

## [2.0.0.beta3] - 2022-09-21

### Added

- New applications to support Puma server out of the box. Add the `puma` gem to `Gemfile` and generate `config/puma.rb`. (@lucaguidi)
- New applications to support code reloading for `hanami server` via `hanami-reloader`. This gem is added to app's `Gemfile`. (@lucaguidi)
- Introduce code reloading for `hanami console` via `#reload` method to be invoked within the console context. (@mbusque)

### Changed

- `hanami generate action` to add routes to `config/routes.rb` without the `define` block context. See https://github.com/hanami/hanami/pull/1208. (@solnic)

### Fixed

- Respect plural when generating code via `hanami new` and `hanami generate`. Example: `hanami new code_insights` => `CodeInsights` instead of `CodeInsight`. (@lucaguidi)
- Ensure `hanami generate action` to not crash when invoked with non-RESTful action names. Example: `hanami generate action talent.apply`. (@lucaguidi)

[2.0.0.beta3]: https://github.com/hanami/cli/compare/v2.0.0.beta2...v2.0.0.beta3

## [2.0.0.beta2] - 2022-08-16

### Added

- Added `hanami generate slice` command, for generating a new slice. (@lucaguidi in #32)
- Added `hanami generate action` command, for generating a new action in the app or a slice. (@lucaguidi in #33)
- Added `hanami middlewares` command, for listing middleware configured in app and/or in `config/routes.rb`. (@mbusque in #30)

### Changed

- `hanami` command will detect the app even when called inside nested subdirectories. (@mbusque, @timriley in #34)
- Include hanami-validations in generated app's `Gemfile`, allowing action classes to specify `.params`. (@swilgosz in #31)
- Include dry-types in generated app's `Gemfile`, which is used by the types module defined in `lib/[app_name]/types.rb` (dry-types is no longer a hard dependency of the hanami gem as of 2.0.0.beta2). (@timriley in #29)
- Include dotenv in generated app's `Gemfile`, allowing `ENV` values to be loaded from `.env*` files. (@timriley in #29)

[2.0.0.beta2]: https://github.com/hanami/cli/compare/v2.0.0.beta1...v2.0.0.beta2

## [2.0.0.beta1] - 2022-07-20

### Added

- Implemented `hanami new` to generate a new Hanami app. (@lucaguidi)
- Implemented `hanami console` to start an interactive console (REPL). (@solnic)
- Implemented `hanami server` to start a HTTP server based on Rack. (@mbusque)
- Implemented `hanami routes` to print app routes. (@mbusque)
- Implemented `hanami version` to print app Hanami version. (@lucaguidi)

[2.0.0.beta1]: https://github.com/hanami/cli/compare/v2.0.0.alpha8.1...v2.0.0.beta1

## [2.0.0.alpha8.1] - 2022-05-23

### Fixed

- Ensure CLI starts properly by fixing use of `Slice.slice_name`. (@timriley)

[2.0.0.alpha8.1]: https://github.com/hanami/cli/compare/v2.0.0.alpha8...v2.0.0.alpha8.1

## [2.0.0.alpha8] - 2022-05-19

### Fixed

- Respect HANAMI_ENV env var to set Hanami env if no `--env` option is supplied. (@croomes)
- Ensure Sequel migrations extension is loaded before related `db` commands are run. (@waiting-for-dev)

[2.0.0.alpha8]: https://github.com/hanami/cli/compare/v2.0.0.alpha7...v2.0.0.alpha8

## [2.0.0.alpha7] - 2022-03-11

### Changed

- [Internal] Update console slice readers to work with new `Hanami::Application.slices` API. (@timriley)

[2.0.0.alpha7]: https://github.com/hanami/cli/compare/v2.0.0.alpha6.1...v2.0.0.alpha7

## [2.0.0.alpha6.1] - 2022-02-11

### Fixed

- Ensure `hanami db` commands to work with `hanami` `v2.0.0.alpha6`. (@vietqhoang)

[2.0.0.alpha6.1]: https://github.com/hanami/cli/compare/v2.0.0.alpha6...v2.0.0.alpha6.1

## [2.0.0.alpha6] - 2022-02-10

### Added

- Official support for Ruby: MRI 3.1. (@lucaguidi)

### Changed

- Drop support for Ruby: MRI 2.6, and 2.7. (@lucaguidi)

[2.0.0.alpha6]: https://github.com/hanami/cli/compare/v2.0.0.alpha4...v2.0.0.alpha6

## [2.0.0.alpha4] - 2021-12-07

### Added

- Display a custom prompt when using irb-based console (consistent with pry-based console). (@timriley)
- Support `postgresql://` URL schemes (in addition to existing `postgres://` support) for `db` subcommands. (@parndt)

### Fixed

- Ensure slice helper methods work in console (e.g. top-level `main` method will return `Main::Slice` if an app has a "main" slice defined). (@timriley)

[2.0.0.alpha4]: https://github.com/hanami/cli/compare/v2.0.0.alpha3...v2.0.0.alpha4

## [2.0.0.alpha3] - 2021-11-09

[2.0.0.alpha3]: https://github.com/hanami/cli/compare/v2.0.0.alpha2...v2.0.0.alpha3

## [2.0.0.alpha2] - 2021-05-04

### Added

- Official support for Ruby: MRI 3.0. (@lucaguidi)
- Dynamically change the set of available commands depending on the context (outside or inside an Hanami app). (@lucaguidi)
- Dynamically change the set of available commands depending on Hanami app architecture. (@lucaguidi)
- Implemented `hanami version` (available both outside and inside an Hanami app). (@lucaguidi)
- Implemented `db *` commands (available both outside and inside an Hanami app) (sqlite and postgres only for now). (@solnic)
- Implemented `console` command with support for `IRB` and `Pry` (`pry` is auto-detected). (@solnic)

### Changed

- Changed the purpose of this gem: the CLI Ruby framework has been extracted into `dry-cli` gem. `hanami-cli` is now the `hanami` command line. (@lucaguidi)
- Drop support for Ruby: MRI 2.5. (@lucaguidi)

[2.0.0.alpha2]: https://github.com/hanami/cli/compare/v1.0.0.alpha1...v2.0.0.alpha2

## [1.0.0.alpha1] - 2019-01-30

### Added

- Inheriting from subclasses of `Hanami::CLI::Command`, allows to inherit arguments, options, description, and examples. (@lucaguidi)
- Allow to use `super` from `#call`. (@lucaguidi)

### Changed

- Drop support for Ruby: MRI 2.3, and 2.4. (@lucaguidi)

[1.0.0.alpha1]: https://github.com/hanami/cli/compare/v0.3.1...v1.0.0.alpha1

## [0.3.1] - 2019-01-18

### Added

- Official support for Ruby: MRI 2.6. (@lucaguidi)
- Support `bundler` 2.0+. (@lucaguidi)

[0.3.1]: https://github.com/hanami/cli/compare/v0.3.0...v0.3.1

## [0.3.0] - 2018-10-24

[0.3.0]: https://github.com/hanami/cli/compare/v0.3.0.beta1...v0.3.0

## [0.3.0.beta1] - 2018-08-08

### Added

- Introduce array type for arguments (`foo exec test spec/bookshelf/entities spec/bookshelf/repositories`). (@davydovanton, @AlfonsoUceda)
- Introduce array type for options (`foo generate config --apps=web,api`). (@davydovanton, @AlfonsoUceda)
- Introduce variadic arguments (`foo run ruby:latest -- ruby -v`). (@AlfonsoUceda)
- Official support for JRuby 9.2.0.0. (@lucaguidi)

### Fixed

- Print informative message when unknown or wrong option is passed (`"test" was called with arguments "--framework=unknown"`). (@davydovanton)

[0.3.0.beta1]: https://github.com/hanami/cli/compare/v0.2.0...v0.3.0.beta1

## [0.2.0] - 2018-04-11

[0.2.0]: https://github.com/hanami/cli/compare/v0.2.0.rc2...v0.2.0

## [0.2.0.rc2] - 2018-04-06

[0.2.0.rc2]: https://github.com/hanami/cli/compare/v0.2.0.rc1...v0.2.0.rc2

## [0.2.0.rc1] - 2018-03-30

[0.2.0.rc1]: https://github.com/hanami/cli/compare/v0.2.0.beta2...v0.2.0.rc1

## [0.2.0.beta2] - 2018-03-23

### Added

- Support objects as callbacks. (@davydovanton, @lucaguidi)

### Fixed

- Ensure callbacks' context of execution (aka `self`) to be the command that is being executed. (@davydovanton, @lucaguidi)

[0.2.0.beta2]: https://github.com/hanami/cli/compare/v0.2.0.beta1...v0.2.0.beta2

## [0.2.0.beta1] - 2018-02-28

### Added

- Register `before`/`after` callbacks for commands. (@davydovanton)

[0.2.0.beta1]: https://github.com/hanami/cli/compare/v0.1.1...v0.2.0.beta1

## [0.1.1] - 2018-02-27

### Added

- Official support for Ruby: MRI 2.5. (@lucaguidi)

### Fixed

- Ensure default values for arguments to be sent to commands. (@AlfonsoUceda)
- Ensure to fail when a missing required argument isn't provided, but an option is provided instead. (@AlfonsoUceda)

[0.1.1]: https://github.com/hanami/cli/compare/v0.1.0...v0.1.1

## [0.1.0] - 2017-10-25

[0.1.0]: https://github.com/hanami/cli/compare/v0.1.0.rc1...v0.1.0

## [0.1.0.rc1] - 2017-10-16

[0.1.0.rc1]: https://github.com/hanami/cli/compare/v0.1.0.beta3...v0.1.0.rc1

## [0.1.0.beta3] - 2017-10-04

[0.1.0.beta3]: https://github.com/hanami/cli/compare/v0.1.0.beta2...v0.1.0.beta3

## [0.1.0.beta2] - 2017-10-03

### Added

- Allow default value for arguments. (@AlfonsoUceda)

[0.1.0.beta2]: https://github.com/hanami/cli/compare/v0.1.0.beta1...v0.1.0.beta2

## [0.1.0.beta1] - 2017-08-11

### Added

- Commands banner and usage. (@AlfonsoUceda, @lucaguidi)
- Added support for subcommands. (@AlfonsoUceda)
- Validations for arguments and options. (@AlfonsoUceda)
- Commands arguments and options. (@AlfonsoUceda)
- Commands description. (@AlfonsoUceda)
- Commands aliases. (@AlfonsoUceda, @oana-sipos)
- Exit on unknown command. (@lucaguidi)
- Command lookup. (@lucaguidi, @AlfonsoUceda, @oana-sipos)
- Trie based registry to register commands and allow third-parties to override/add commands. (@lucaguidi, @timriley)

[0.1.0.beta1]: https://github.com/hanami/cli/releases/tag/v0.1.0.beta1
