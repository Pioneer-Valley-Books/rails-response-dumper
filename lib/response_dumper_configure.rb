# frozen_string_literal: true

class ResponseDumperConfigure
  attr_reader :after_all_block, :before_all_block

  def before_all(&block)
    @before_all_block = block
  end

  def after_all(&block)
    @after_all_block = block
  end
end
