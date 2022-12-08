# frozen_string_literal: true

module RailsResponseDumper
  COLORS = {
    cyan: 36,
    green: 32,
    red: 31
  }.freeze

  COLORIZE = $stdout.tty?

  def self.print_color(text, color)
    if COLORIZE
      print colorize(text, color)
    else
      print text
    end
  end

  def self.colorize(text, color)
    "\e[#{COLORS[color]}m#{text}\e[0m"
  end
end
