# Contributing

If you're going to report an issue or submit a pull requrest, please follow these guidelines.

## Reporting an Issue

* Provide the problematic code or the project's URL.
* Include the version of Ruby you're using (`ruby --version`).
* Include the version of Transpec you're using (`transpec --version`).
* Include complete command-line options you passed to `transpec`.

## Pull Requests

* Add tests for your change unless it's a refactoring.
* Run `bundle exec rake`. If any failing test or code style issue is reported, fix it.
* If you're going to modify the content of `README.md`:
    * Edit `README.md.erb` instead.
    * Run `bundle exec rake readme`. This will generate `README.md` from `README.md.erb`.
    * Commit both files.
