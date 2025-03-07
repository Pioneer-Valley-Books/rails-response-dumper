## 9.2.0 (2024-11-13)

Add support for Rails 8.

## 9.1.0 (2024-06-20)

- Make compatible with Rack 3.1 and an omitted `rack.input` value.

## 9.0.0 (2024-03-26)

- Allow the application to load Rails configuration.

## 8.0.0 (2024-03-19)

- Include CGI/HTTP request Rack environment variables in the JSON dump.

- The field `request.method` is no longer in the JSON dump.

## 7.0.0 (2024-02-29)

- Add the `--profile` CLI option. This option will print the names of the 10
  slowest dumps and their time from the run.

- Running `rails-response-dumper` with no arguments now limits discovery to
  `*_dumper.rb` files instead of all `*.rb` files.

- Add support for attaching files in multipart/form-data requests. The
  runner now places the request and response bodies in their own files outside
  of the `#.json` file.

## 6.2.0 (2023-05-31)

- Add `timestamp` property to dumps. Its value is the Rails timestamp in ISO
  8601 format.

## 6.1.0 (2023-05-24)

- Start the database transaction with the `joinable: false` argument passed.
  This allows model `after_commit` hooks to run and improves compatibility with
  ActiveStorage.

## 6.0.0 (2023-04-27)

- Add `--dumps-dir` CLI option. This option allows the user to specify a
  directory to which the dumps are saved.

- Add `--exclude-response-headers` CLI option. This option will suppress response
  headers from the dumper output.

- The dump property `response.status_text` was renamed to `response.statusText`
  to match the JavaScript `Response` constructor.

- Add option to specify dump files to run from CLI as an alternative to running all dumps.

## 5.3.0 (2023-03-07)

- Add `--verbose` CLI option. This option will print the dumper and block names.
  e.g. `bundle exec rails-response-dumper --verbose`.

- Add --order CLI option. `--order random` will run the dumps in a random
  order. If given a seed value e.g. `--order 8` it will initialize the pseudo
  random number generator with the provided seed value to run the dumps in a
  reproducible order.

- Fix `--fail-fast` CLI flag. Abort dumps for all remaining dumpers,
  and not just the dumps of the current dumper in the loop.

## 5.2.0 (2023-01-24)

- Output the full backtrace when reporting errors.

- Add ability to abort after first error using `--fail-fast` CLI flag.

## 5.1.0 (2022-12-12)

- Move all CLI output to stdout.

- Colorize CLI output for TTY environments.

- The request body and the response status text are now included in the dump.
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
