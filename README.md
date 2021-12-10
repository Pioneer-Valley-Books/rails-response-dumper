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

class UsersResponseDumper < ResponseDumper
  def dump_index
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
└── users_response_dumper
    └── dump_index.html
```

Just like tests, the dump methods can include setup code to add records to the
database or include other side effects to build a more interesting dump. Dumps
run in a transaction that always rollsback at the end.

## `ResponseDumper::reset_models`

*NOTE: This feature is only supported on PostgreSQL.*

The class method `ResponseDumper::reset_models` can be used to reset database
sequences between runs. If a model ID value is included in the dump and it is
important that this value is reproducible on each run, use this method.


```ruby
# dumpers/users_response_dumper.rb

class UsersResponseDumper < ResponseDumper
  reset_models User

  def dump_index
    User.create!(name: 'Alice')
    get users_index_path
  end
end
```
