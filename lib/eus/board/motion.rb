# frozen_string_literal: true

module Eus
  class Board
    # All the motion-specific methods for a Board.
    module Motion # rubocop:disable ModuleLength
      def move_column_to_card_column(from, to)
        return nil unless (card = columns[from].last)
        return nil unless (to_card = columns[to].last)
        return nil unless card.plays_on_top_of?(to_card)

        new_column_to_column_board(card, from, to)
      end

      def move_column_to_empty_column(from, to)
        return nil unless (card = columns[from].last)

        new_column_to_column_board(card, from, to)
      end

      def move_column_to_cell(from, to)
        return nil unless (card = columns[from].last)

        new_board do
          unlock_columns from
          unlock_cells

          columns[from].pop
          cells[to] = card
        end
      end

      def move_cell_to_column(from, to)
        return nil unless (card = cells[from])
        return nil unless (to_card = columns[to].last)
        return nil unless card.plays_on_top_of?(to_card)

        new_board do
          unlock_columns to
          unlock_cells

          cells[from] = nil
          columns[to].push card
        end
      end

      private

      def new_column_to_column_board(card, from, to)
        new_board do
          unlock_columns from, to
          columns[from].pop
          columns[to].push card
        end
      end

      def unlock_columns(*column_indexes)
        @columns = columns.dup if columns.frozen?
        column_indexes.each do |index|
          column = columns[index]
          columns[index] = column.dup if column.frozen?
        end
      end

      def unlock_cells
        @cells = cells.dup if cells.frozen?
      end

      def unlock_foundations
        @foundations = foundations.dup if foundations.frozen?
      end

      # Creates a new board and then runs instance evals &block inside
      # it so that all the methods called inside block are done in the
      # new board.  After that, all the automatic moves are done (just
      # like in the game).
      def new_board(&block)
        dup.tap do |nb|
          nb.instance_eval do
            instance_eval &block # rubocop:disable AmbiguousOperator

            do_automatic_moves
          end
        end
      end

      # This will only be called by a board that is not frozen
      def do_automatic_moves
        while column_automatic_move || cell_automatic_move
        end
      end

      def column_automatic_move
        CARD_COLUMN_INDEXES.any? do |index|
          next false unless (card = columns[index]&.last)
          next false unless (foundation_index = foundation_map[card.value])

          unlock_columns index
          columns[index].pop
          place_foundation foundation_index, card
          true
        end
      end

      def cell_automatic_move
        CELL_INDEXES.any? do |index|
          next false unless (card = cells[index])
          next false unless (foundation_index = foundation_map[card.value])

          unlock_cells
          cells[index] = nil
          place_foundation foundation_index, card
          true
        end
      end

      def foundation_map
        @foundation_map ||= foundations.each
                                       .with_index
                                       .with_object({}) do |(card, index), h|
          h[(card&.next || Card.foundation_card_for_index(index)).value] = index
        end
      end

      def place_foundation(index, card)
        unlock_foundations
        foundations[index] = card

        unlock_foundation_map
        foundation_map.delete(card)
        return unless (next_card = card.next)
        foundation_map[next_card.value] = index
      end

      def unlock_foundation_map
        @foundation_map = @foundation_map.dup if foundation_map.frozen?
      end
    end
  end
end
