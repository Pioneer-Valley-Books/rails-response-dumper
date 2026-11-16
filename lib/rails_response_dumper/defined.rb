# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require_relative 'dump_block'

module RailsResponseDumper
  class Defined
    attr_accessor :name, :klass
    attr_reader :before_block, :after_block

    delegate :include, to: :klass

    def self.dumpers
      @dumpers ||= []
    end

    def initialize(name, &block)
      self.name = name
      self.klass = Class.new(ResponseDumper)

      instance_eval(&block)

      self.class.dumpers << self
    end

    def dump(name, status_codes: [:ok], &block)
      blocks << DumpBlock.new(
        name,
        status_codes.map { |status_code| Rack::Utils::SYMBOL_TO_STATUS_CODE[status_code] },
        block
      )
    end

    def before(&block)
      @before_block = block
    end

    def after(&block)
      @after_block = block
    end

    def blocks
      @blocks ||= []
    end

    def reset_models(*models)
      @reset_models ||= []
      @reset_models += models
    end

    # Set the sequences to their start values. The sequences are the same as
    # the sequences that TRUNCATE ... RESTART IDENTITY CASCADE restarts, but
    # the rows stay in the tables. Each dump runs in a transaction, and so the
    # rollback removes the rows, but a rollback does not reset the sequences.
    #
    # For each connection, one query does these steps:
    #
    # 1. Find the tables of the models and the tables that inherit from them.
    #    TRUNCATE uses inheritance only for the tables that you name. It does
    #    not use inheritance for the tables that it finds through CASCADE.
    # 2. Find all tables that refer to these tables through a foreign key.
    #    Do this step again for each table that the query finds.
    # 3. Find the sequences that these tables own. A serial column owns its
    #    sequence with deptype 'a'. An identity column owns its sequence with
    #    deptype 'i'.
    # 4. Use setval to set each sequence to its start value. The next value
    #    from the sequence is then the start value.
    #
    # The tables must be empty before each dump. If a table has rows, a new
    # row can get the same ID as an old row.
    #
    # Refer to:
    # - https://www.postgresql.org/docs/current/sql-truncate.html
    # - https://www.postgresql.org/docs/current/queries-with.html
    # - https://www.postgresql.org/docs/current/catalog-pg-inherits.html
    # - https://www.postgresql.org/docs/current/catalog-pg-constraint.html
    # - https://www.postgresql.org/docs/current/catalog-pg-depend.html
    # - https://www.postgresql.org/docs/current/catalog-pg-sequence.html
    # - https://www.postgresql.org/docs/current/functions-sequence.html
    def reset_models!
      reset_models.group_by(&:connection).each do |connection, models|
        tables = models.map { |model| connection.quote(model.quoted_table_name) }
        connection.exec_query <<~SQL.squish
          WITH RECURSIVE named(oid) AS (
            SELECT unnest(ARRAY[#{tables.join(', ')}]::regclass[])
            UNION
            SELECT pg_inherits.inhrelid FROM pg_inherits JOIN named ON pg_inherits.inhparent = named.oid
          ), tables(oid) AS (
            SELECT oid FROM named
            UNION
            SELECT pg_constraint.conrelid
            FROM pg_constraint
            JOIN tables ON pg_constraint.confrelid = tables.oid
            WHERE pg_constraint.contype = 'f'
          )
          SELECT setval(pg_sequence.seqrelid, pg_sequence.seqstart, false)
          FROM tables
          JOIN pg_depend
            ON pg_depend.refclassid = 'pg_class'::regclass
            AND pg_depend.refobjid = tables.oid
            AND pg_depend.classid = 'pg_class'::regclass
            AND pg_depend.deptype IN ('a', 'i')
          JOIN pg_sequence ON pg_sequence.seqrelid = pg_depend.objid
        SQL
      end
    end
  end
end
