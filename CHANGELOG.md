## UNRELEASED

- Override `ResponseDumper#inspect` to just the class name without listing its
  methods.

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
