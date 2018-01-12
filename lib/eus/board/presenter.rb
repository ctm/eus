# frozen_string_literal: true

module Eus
  class Board
    # Provides a nice string representation of a board.
    class Presenter
      FOUNDATION_ROW_OFFSET = 1
      BLANK_ROW = ' ' * (Board::N_COLUMNS * 3 - 1)

      def initialize(board)
        @board = board
      end

      def to_s
        rows.join("\n")
      end

      private

      attr_reader :board

      def rows
        column_rows + [''] + [cells_row]
      end

      def column_rows
        board_rows = max_len_zip(*board.columns).map! do |row|
          row.map { |card| card&.to_s || '  ' }.join(' ')
        end

        max_len_zip(board_rows, foundation_strings).map do |(br, fs)|
          [(br || BLANK_ROW), fs].join(FOUNDATION_SEPARATOR)
        end
      end

      FOUNDATION_SEPARATOR = '  '
      private_constant :FOUNDATION_SEPARATOR

      def cells_row
        board.cells.map { |card| card ? card.to_s : '  ' }.join(' ')
      end

      # Returns an array of strings suitable for pairing up with each of
      # the board rows.  No cards on the foundation will result in an
      # empty array being returned.
      def foundation_strings
        (Array.new(FOUNDATION_ROW_OFFSET, '') +
         board.foundations.map(&:to_s)).tap { |a| a.pop while a.last&.empty? }
      end

      # NOTE: this is not at all Presenter specific.  It implements zip
      # for an arbitrary number of arrays, but always returns arrays whose
      # length is the length of the largest of the arrays passed in.
      #
      # For example,
      #
      #   a = [1, 2]
      #   b = [3, 4, 5]
      #   c = [7]
      #   a.zip(b, c)
      #   => [[1, 3, 7], [2, 4, nil]]
      #   max_zip(a, b, c)
      #   => [[1, 3, 7], [2, 4, nil], [nil, 5, nil]]

      def max_len_zip(*arrays)
        max_array = arrays.inject([]) { |max, a| a.size > max.size ? a : max }
        max_array.zip(*arrays).tap { |a| a.each(&:shift) }
      end
    end
  end
end
