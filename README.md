# Rails Response Dumper

Rails Response Dumper is a library and command line tool to dump HTTP responses
from a Rails application to the file system. These responses can then be
consumed by other tools for testing and verification purposes.

## Installation

```console
$ bundle add rails-response-dumper --group=development,test
```

## Usage

Add the `dumpers` directory to the root of your Rails application. In this
directory, define classes that extend `ResponseDumper`. Each method that starts
with `dump_` will generate a dump file in the `dumps` directory. Rails path
methods are available.

```ruby
# dumpers/users_response_dumper.rb

ResponseDumper.define 'Users' do
  dump 'index' do
    get users_index_path
  end
end
```

Running the command `rails-response-dumper` will create the directory `dumps`
and fill it with dump files.

```console
$ rails-response-dumper
$ tree dumps
dumps
└── users
    └── index
        └── 0.html
```

Just like tests, the dump methods can include setup code to add records to the
database or include other side effects to build a more interesting dump. Dumps
run in a transaction that always rollsback at the end.

## `reset_models`

*NOTE: This feature is only supported on PostgreSQL.*

The method `reset_models` can be used to reset database sequences between runs.
If a model ID value is included in the dump and it is important that this value
is reproducible on each run, use this method.


```ruby
# dumpers/users_response_dumper.rb

ResponseDumper.define 'Users' do
  reset_models User

  dump 'index' do
    User.create!(name: 'Alice')
    get users_index_path
  end
end
```

## Creating a release

1. Create a new pull request that:

  - Bumps the version in `rails-response-dumper.gemspec`
  - Updates `CHANGELOG.md` to include all noteworthy changes, the release
    version, and the release date.

2. After the pull request lands, checkout the most up to date `main` branch and
   build the gem:

  ```console
  $ docker run --rm -it -v $(pwd):$(pwd) -w $(pwd) ruby gem build
  ```

3. Publish the gem:

   ```console
   $ docker run --rm -it -v $(pwd):$(pwd) -w $(pwd) ruby gem push rails-response-dumper-X.Y.Z.gem
   ```

4. Create and publish a git tag:

    ```console
    $ git tag X.Y.Z
    $ git push https://github.com/Pioneer-Valley-Books/rails-response-dumper.git X.Y.Z
    ```
