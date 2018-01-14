# frozen_string_literal: true

require_relative 'card'
require_relative 'board/motion'

module Eus
  # Represents the board of 8-off, which is the type of solitaire that
  # you get on the demo version of Eric's Ultimate Solitaire, which can
  # be played at https://archive.org/details/executor
  class Board
    include Motion

    # It is unlikely that either N_COLUMNS or N_CELLS can be changed and
    # for the code to still work, because 8-off, largely depends on their
    # being exactly 8 columns and exactly 8 cells.
    N_COLUMNS = 8
    private_constant :N_COLUMNS

    N_CELLS = 8
    private_constant :N_CELLS

    CARD_COLUMN_INDEXES = (0...N_COLUMNS).freeze
    CELL_INDEXES = (0...N_CELLS).freeze

    # Boards are initially mutable but are deep frozen when solving to make
    # sure they're not mutated at inopportune times.
    def initialize(columns:, cells:, foundations:)
      @columns = columns
      @cells = cells
      @foundations = foundations
    end

    def self.parse(string_or_io)
      new(Parser.new(string_or_io).parse)
    end

    def deep_freeze
      columns.each(&:freeze)
      columns.freeze
      cells.freeze
      foundations.freeze
      foundation_map.freeze
      freeze
    end

    # This gives a value that is really a binary representation of the
    # canonical form of this Board.  Any Board that has this same hash
    # is logically the same.  In theory, any board that is logically the
    # same should also have this value, but that's a stricter constraint
    # to enforce and it hasn't been needed so far.
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

    private

    # This is a value that never appears as a card and also isn't the
    # value we use to represent the lack of a card.  It is used when
    # we construct the hash so we can have columns of arbitrary length.
    COLUMN_SEPARATOR_VALUE = Card::DECK_SIZE + 1

    # We zip these in between columns to (numerically) keep them separate.
    COLUMN_SEPARATORS = Array.new(N_COLUMNS - 1, COLUMN_SEPARATOR_VALUE).freeze

    # The +2 is so we can use any Card's value as well as
    # Card::BLANK_VALUE as well as COLUMN_SEPARATOR_VALUE.  Those two
    # magic values are ugly and may go away.
    CARD_BIT_WIDTH = Math.log2(Card::DECK_SIZE + 2).ceil

    def cards(arr)
      Array(arr).map { |symbol| Card.new(symbol) }
    end
  end
end

require_relative 'board/presenter'
require_relative 'board/parser'
