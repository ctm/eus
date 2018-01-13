# frozen_string_literal: true

require 'card'

module Eus
  # Represents the board of 8-off, which is the type of solitaire that
  # you get on the demo version of Eric's Ultimate Solitaire, which can
  # be played at https://archive.org/details/executor
  class Board # rubocop:disable ClassLength
    N_COLUMNS = 8

    # Boards are initially mutable but are deep frozen when solving to make
    # sure their not mutated at inopportune times.
    def initialize(columns, cells, foundations)
      @columns = columns
      @cells = cells
      @foundations = foundations
      check
    end

    def self.parse(string_or_io)
      new(*Parser.new(string_or_io).parse)
    end

    def deep_freeze
      columns.each(&:freeze)
      columns.freeze
      cells.freeze
      foundations.freeze
      freeze
    end

    # This gives a value that is really a binary representation of the
    # canonical form of this Board.  Any Board that has this same hash
    # is logically the same.  In theory, any board that is logically the
    # same should also have this value, but that's a stricter constraint
    # to enforce and it's probably not needed (I'll know more when I
    # actually write the solver).
    def hash # rubocop:disable AbcSize
      # We don't sort the foundation_values, because the suits (which
      # are in a fixed order) are important.
      foundation_values = values(foundations)
      # We *do* sort the cell_values, because where they are on the board
      # doesn't matter
      cell_values = values(cells).sort
      # Similarly, we sort the columns, because although the contents of
      # each individual column is important, the arrangement of the columns
      # themselves isn't.
      sorted_column_values = columns.map { |c| c.map(&:value) }.sort
      all_values = (foundation_values +
                    cell_values +
                    sorted_column_values.zip(COLUMN_SEPARATORS)).flatten
      # The pop here is because our zip is going to leave a nil at the end
      all_values.pop
      all_values.each.with_index.inject(0) do |hash, (value, index)|
        hash + (value << index * CARD_BIT_WIDTH)
      end
    end

    def values(cards)
      cards.map { |f| f&.value || Card::BLANK_VALUE }
    end

    def eql?(other)
      other.hash == hash
    end

    # This is just for consistency checking during development.
    # Currently it only verifies that each of the 52 cards is used just
    # once, although it does so based on the knowledge that there are
    # exactly Card::DECK_SIZE cards in the deck.
    def check # rubocop:disable AbcSize
      all = (columns + cells.compact + foundation_cards).flatten

      unless all.size == Card::DECK_SIZE
        raise "Expected #{Card::DECK_SIZE} cards, got #{all.size}"
      end

      raise 'At least one duplicate card' unless all.uniq.size == Card::DECK_SIZE # rubocop:disable LineLength
    end

    # This is only used in consistency checking.  It returns all the cards
    # that are in the foundation, by looking at the top card and generating
    # cards for each implied card underneath it.  This is slow, but we rarely
    # consistency check.
    def foundation_cards
      foundations.map do |foundation|
        n_to_generate = foundation ? Card::RANK_VALUES[foundation.rank] + 1 : 0
        suit = foundation&.suit
        Array.new(n_to_generate) { |rv| Card.new(Card::VALUES_RANK[rv], suit) }
      end
    end

    def solved?
      foundations.all? { |f| f&.rank == Card::HIGHEST_RANK }
    end

    def to_s
      Presenter.new(self).to_s
    end

    attr_reader :columns, :cells, :foundations

    # Two games that are logically the same, are not considered ==
    # unless they look exactly the same.  So a solved game with spades
    # as the top most foundation is going to be "eql?" to a solved games
    # with hearts as the top most foundation, the two won't be
    # considered "==".
    def ==(other)
      to_s == other.to_s
    end

    # TODO: move the motion code either to a helper class or to a module
    #       that is included, but get it out of here
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

    # This is a value that never appears as a card and also isn't the
    # value we use to represent the lack of a card.  It is used when
    # we construct the hash so we can have columns of arbitrary length.
    COLUMN_SEPARATOR_VALUE = Card::DECK_SIZE + 1

    # We'll zip these into the columns so we can (numerically) keep them
    # separate.
    COLUMN_SEPARATORS = Array.new(N_COLUMNS - 1, COLUMN_SEPARATOR_VALUE).freeze

    # The +2 is so we can use any Card's value as well as
    # Card::BLANK_VALUE as well as COLUMN_SEPARATOR_VALUE.  Those two
    # magic values are ugly and should go away, but it'll be easier to
    # do that after specs are written.
    CARD_BIT_WIDTH = Math.log2(Card::DECK_SIZE + 2).ceil

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

    def new_board(&block)
      dup.tap do |new_board|
        new_board.instance_eval do
          instance_eval &block # rubocop:disable AmbiguousOperator

          changed = true
          changed = do_automatic_moves while changed
        end
      end
    end

    # This will only be called by a board that is not frozen
    def do_automatic_moves # rubocop:disable AbcSize, MethodLength
      require 'pry'; binding.pry # rubocop:disable Semicolon, Debugger
      # TODO: rewrite this entirely.  I haven't looked at it since
      #       I rewrote the motion code.  Not only is it likely to
      #       be crazy inefficient, but it is probably not even
      #       useful as a start.
      needed = foundations.each.with_index.map do |card, index|
        if card
          suit = card.suit
          rank_value = card.rank_value + 1
        else
          suit = Card::SUIT_VALUES.keys[index]
          rank_value = 0
        end
        if rank_value < Card::N_RANKS
          Card.new(Card::RANK_VALUES.keys[rank_value], suit)
        end
      end

      Solver::SOURCE_INDEXES.any? do |from|
        next false unless (card = card_at(from))
        needed.include?(card).tap do |got_one|
          if got_one
            # TODO: move the card to the foundation, although move
            #       doesn't currently do that
            require 'pry'; binding.pry # rubocop:disable Semicolon, Debugger
          end
        end
      end
    end

    def cards(arr)
      Array(arr).map { |symbol| Card.new(symbol) }
    end

    def card_at(position)
      if position < N_COLUMNS
        columns[position]&.last
      else
        cells[position - N_COLUMNS]
      end
    end

    def playable?(card, position)
      return true unless (base_card = card_at(position))

      position < N_COLUMNS && base_card.suit == card.suit &&
        base_card.rank_value == card.rank_value + 1
    end
  end
end

require 'board/presenter'
require 'board/parser'
