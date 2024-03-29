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

    def reset_models!
      reset_models.each do |model|
        model.connection.exec_query <<~SQL.squish
          TRUNCATE #{model.quoted_table_name} RESTART IDENTITY CASCADE
        SQL
      end
    end
  end
end
