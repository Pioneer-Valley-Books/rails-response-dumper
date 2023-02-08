## UNRELEASED

- Fix `--fail-fast` CLI flag. Abort dumps for all remaining dumpers,
and not just the dumps of the current dumper in the loop.

## 5.2.0 (2023-01-24)

- Output the full backtrace when reporting errors.

- Add ability to abort after first error using `--fail-fast` CLI flag.

## 5.1.0 (2022-12-12)

- Move all CLI output to stdout.

- Colorize CLI output for TTY environments.

-  The request body and the response status text are now included in the dump.
   The new format looks like:

  ```json
  {
    "request": {
      "method": "GET",
      "url": "http://www.example.com/test",
      "body": ""
    },
    "response": {
      "status": 200,
      "status_text": "OK",
      "headers": {
        "Content-Type": "text/html; charset=utf-8",
        ...
      },
      "body": "..."
    }
  }
  ```

## 5.0.0 (2022-12-05)

- Add error aggregation. An exception raised during the dumper runtime will no
  longer halt execution. Instead, all errors are displayed after runtime.

- Display real-time dumper status during dump execution.

- The dumped responses are now serialized to a JSON object. The object uses the
  format:

  ```json
  {
    "request": {
      "method": "GET",
      "url": "http://www.example.com/test"
    },
    "response": {
      "status": 200,
      "headers": {
        "Content-Type": "text/html; charset=utf-8",
        ...
      },
      "body": "..."
    }
  }
  ```

  As the file is always JSON, the file extension is now always `.json` and the
  mime/types gem is no longer a dependency.

## 4.1.0 (2022-10-18)

- Add support for before/after hooks.

## 4.0.0 (2022-06-06)

- Add support for multiple expected status codes.
- Add support for dumped responses with no content type. The dumped filename
  will not have a file extension.

## 3.0.1 (2022-03-29)

- Fix gem to install `lib/**/*.rb`.

## 3.0.0 (2022-03-29)

- New DSL. Library users should no longer define child classes of
  `ResponseDumper`. Instead, use `ResponseDumper.define`. Inside the block, use
  the `dump` method. For example:

  ```ruby
  ResponseDumper.define 'Users' do
    dump 'index' do
      get users_index_path
    end
  end
  ```

- The output file structure has changed. Directories no longer contain the
  `dump_` prefix from methods. For the example above, the output is now:

  ```
  dumps
  └── users
      └── index
          └── 0.html
  ```

- The `dump` method has an optional keyword argument `status_code`. Use this if
  the dumped response has an HTTP status code other than 200.

- `ResponseDumper` class now includes `ActiveSupport::Testing::TimeHelpers` to
  provide methods `freeze_time`, `travel`, and `travel_to`.

- On status code failure, the error now reports the dumper class and method.

- Add mime/types as a dependency.

- The rspec-mocks dependency now requires version `~> 3.0` (or `>= 3.0, <
  4.0`).

## 2.1.0 (2022-03-03)

- Override `ResponseDumper#inspect` to just the class name without listing its
  methods.

- Add rspec-mocks as a dependency. The `ResponseDumper` class now includes
  `RSpec::Mocks::ExampleMethods`.

## 2.0.0 (2022-02-03)

- Add compatibility for Rails 7.

- Allow dumping multiple responses per `dump_*` method. Each additional call to
  `get` or `post` will dump another file. The directory structure is now:

  ```
  dumps/class_name/method_name/0.html
  dumps/class_name/method_name/1.html
  ...
  ```

## 1.1.0 (2022-01-13)

- Instantiate the dumper before each `dump_*` method rather than once before
  all `dump_*` methods.

## 1.0.0 (2021-12-17)

Initial release.
