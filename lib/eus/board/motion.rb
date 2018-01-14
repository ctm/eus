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

      # define unlock_cells, unlock_foundations and unlock_foundation_map.
      %w[cells foundations foundation_map].each do |stem|
        ivar = "@#{stem}"
        method = "unlock_#{stem}"
        define_method("unlock_#{stem}") do
          if (v = send(stem)).frozen?
            instance_variable_set ivar, v.dup
          end
        end
        private method
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
          # Nothing to do here, because column_automatic_move and
          # cell_automatic_move both do work and return whether or not
          # they did work.
        end
      end

      def column_automatic_move
        CARD_COLUMN_INDEXES.any? do |index|
          next false unless (card = columns[index]&.last)
          next false unless (foundation_index = foundation_map[card])

          unlock_columns index
          columns[index].pop
          place_foundation foundation_index, card
          true
        end
      end

      def cell_automatic_move
        CELL_INDEXES.any? do |index|
          next false unless (card = cells[index])
          next false unless (foundation_index = foundation_map[card])

          unlock_cells
          cells[index] = nil
          place_foundation foundation_index, card
          true
        end
      end

      # A Hash whose keys are Cards and whose values are indexes into the
      # foundations array.  There will be at most four keys, one for each
      # suit.
      #
      # If the foundation has only the deuce of spades showing, with
      # hearts, diamonds and clubs yet unplayed, then foundation_map would
      # map the trey of spades to the spade index, the ace of hearts to the
      # hearts index, the ace of diamonds to the diamond index and the
      # ace of clubs to the clubs index.
      #
      # If a king is showing on the foundation be no key for that suit,
      # because nothing is ever played on a king.
      def foundation_map
        @foundation_map ||= foundations.each
                                       .with_index
                                       .with_object({}) do |(card, index), h|
          key = card&.next_higher_card || Card.foundation_card_for_index(index)
          h[key] = index if key
        end
      end

      def place_foundation(index, card)
        unlock_foundations
        foundations[index] = card

        unlock_foundation_map
        foundation_map.delete(card)
        return unless (next_card = card.next_higher_card)
        foundation_map[next_card] = index
      end
    end
  end
end
