# frozen_string_literal: true

require 'spec_helper'
require './lib/rails_response_dumper/colorize'

RSpec.describe 'Colorize' do
  describe '#print_color' do
    RailsResponseDumper::COLORS.each do |color, code|
      context 'when the output is sent to a TTY' do
        before { stub_const('RailsResponseDumper::COLORIZE', true) }
        let(:print_color) { RailsResponseDumper.print_color('hello!', color) }

        it 'includes color information in the output' do
          expect { print_color }.to output("\e[#{code}mhello!\e[0m").to_stdout
        end
      end

      context 'when the output is not sent to a TTY' do
        before { stub_const('RailsResponseDumper::COLORIZE', false) }
        let(:print_color) { RailsResponseDumper.print_color('hello!', color) }

        it 'does not include color information in the output' do
          expect { print_color }.to output('hello!').to_stdout
        end
      end
    end
  end
end
