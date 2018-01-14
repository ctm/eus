# frozen_string_literal: true

require_relative '../util'

module Eus
  class Board
    # Provides a nice string representation of a board.
    class Presenter
      FOUNDATION_ROW_OFFSET = 1
      BLANK_ROW = ' ' * (N_COLUMNS * 3 - 1)

      def initialize(board)
        @board = board
      end

      def to_s
        rows.join("\n")
      end

      private

      FOUNDATION_SEPARATOR = '  '
      private_constant :FOUNDATION_SEPARATOR

      attr_reader :board

      def rows
        column_rows + [''] + [cells_row]
      end

      def column_rows
        board_rows = Util.max_len_zip(*board.columns).map! do |row|
          row.map { |card| card&.to_s || '  ' }.join(' ')
        end

        Util.max_len_zip(board_rows, foundation_strings).map do |(br, fs)|
          [(br || BLANK_ROW), fs].join(FOUNDATION_SEPARATOR)
        end
      end

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
    end
  end
end
