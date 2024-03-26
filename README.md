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
directory, create the file `dumpers_helper.rb` that loads the Rails
environment.

```ruby
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
```

Next, define classes that extend `ResponseDumper`. Each method that starts with
`dump_` will generate a dump file in the `dumps` directory. Rails path methods
are available.

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
        └── 0.json
        └── 0.request_body
        └── 0.response_body
```

The content of each `#.json` dump file is a JSON object with attributes that contain
information about the HTTP request and response. For example:

```json
{
  "request": {
    "url": "http://www.example.com/test",
    "env": {
      "REQUEST_METHOD": "GET",
      ...
    }
  },
  "response": {
    "status": 200,
    "statusText": "OK",
    "headers": {
      "Content-Type": "text/html; charset=utf-8",
      ...
    }
  }
}
```

The content of `#.request_body` and `#.response_body` are the request and
response body contents. For example:

`#.request_body`:

```
foo[bar]=baz
```

`#.response_body`:

```
<p>Hello World!</p>
```

Or, for a multipart/form-data request which contains a submitted file:

`#.request_body` (binary):

```
------------XnJLe9ZIbbGUYtzPQJ16u1
content-disposition: form-data; name="file"; filename="image.png"
content-type: image/png
content-length: 21

<file data content appears here>
------------XnJLe9ZIbbGUYtzPQJ16u1--
```

Request and response bodies are held in separate files because multipart forms
may contain binary data which cannot be safely passed through the JSON formatter.

Just like tests, the dump methods can include setup code to add records to the
database or include other side effects to build a more interesting dump. Dumps
run in a transaction that always rollsback at the end.

### Running Dumps for Specific Files

To generate dumps for only specific files or globs, specify them while running
the `rails-response-dumper` command as follows:

```console
$ rails-response-dumper path/to/a/file.rb
```

### HTTP Status Codes

By default, Rails Response Dumper will raise an exception if the response does
not have a single HTTP status code 200. If you expect a different status code,
or multiple status codes, use the keyword argument `status_codes` to `dump`.

```ruby
# dumpers/users_response_dumper.rb

ResponseDumper.define 'Users' do
  dump 'show_does_not_exist', status_codes: [:not_found] do
    get user_path(0)
  end
end
```

If your dumper makes multiple requests you will have to specify each expected response

```ruby
# dumpers/users_response_dumper.rb

ResponseDumper.define 'Users' do
  dump 'show_does_not_exist', status_codes: [:ok, :not_found] do
    user User.create!(name: 'Alice')
    get user_path(user)
    get user_path(0)
  end
end
```

## Before/After Hooks

The methods `before` and `after` can be used to run arbitrary code before and
after each dump, allowing you to set up the specific environment for
your dumpers to run.

```ruby
# dumpers/users_response_dumper.rb

ResponseDumper.define 'Users' do
  before do
    ENV[API_KEY] = 'test_key'
  end

  after do
    ENV[API_KEY] = nil
  end

  dump 'index' do
    User.create!(name: 'Alice')
    get users_index_path
  end
end
```

## `reset_models`

_NOTE: This feature is only supported on PostgreSQL._

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
