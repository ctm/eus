# frozen_string_literal: true

module Eus
  class Board
    # Can read in what Board.to_s writes
    class Parser
      def initialize(string_or_io)
        @lines = string_or_io.instance_eval do
          respond_to?(:readlines) ? readlines : lines
        end.map(&:rstrip)
        decompose
      end

      def parse
        [columns, cells, foundation]
      end

      private

      BLANK_ROW_SIZE = Presenter::BLANK_ROW.size

      attr_reader :lines, :cells, :foundation, :columns

      def decompose # rubocop:disable MethodLength, AbcSize
        # This method mutates lines as it goes.  As such, I prefer to not
        # split it into smaller methods, so that all the line mutating can
        # be done here.
        @cells = cards_from_line(lines.pop)
        blank = lines.pop
        raise "Expected #{blank.inspect} to be empty" unless blank.empty?

        # Now pull off the foundation cards, because we need them and
        # they also get in the way.  Beware: this step mutates lines.
        @foundation = lines[Presenter::FOUNDATION_ROW_OFFSET,
                            Card::N_SUITS].map do |line|
          if (extra = line.slice!(BLANK_ROW_SIZE..-1)&.strip) && !extra.empty?
            Card.new(extra.downcase)
          end
        end

        @columns = lines.map { |line| cards_from_line(line) }
                        .transpose.map(&:compact)
      end

      def cards_from_line(line)
        Array.new(Board::N_COLUMNS) do
          card = line.slice!(0, 3).strip
          card.empty? ? nil : Card.new(card.downcase)
        end
      end
    end
  end
end
