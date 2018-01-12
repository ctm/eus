# frozen_string_literal: true

module Eus
  # Represents the board of 8-off, which is the type of solitaire that
  # you get on the demo version of Eric's Ultimate Solitaire, which can
  # be played at https://archive.org/details/executor
  class Board
    N_COLUMNS = 8

    # This hard-codes a game that I had trouble solving manually.
    def initialize
      # TODO
    end

    def self.parse(string_or_io)
      # TODO: get rid of this instance eval.  UGH!
      new.tap do |t|
        t.instance_eval do
          @columns, @cells, @foundations = Parser.new(string_or_io).parse
        end
      end
    end

    # This gives a value that is really a binary representation of the
    # canonical form of this Board.  Any Board that has this same hash
    # is logically the same.  In theory, any board that is logically the
    # same should also have this value, but that's a stricter constraint
    # to enforce and it's probably not needed (I'll know more when I
    # actually write the solver).
    def hash # rubocop:disable AbcSize
      foundation_values = sorted_values(foundations)
      cell_values = sorted_values(cells)
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

    def sorted_values(cards)
      cards.map { |f| f&.value || Card::BLANK_VALUE }.sort
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

    # We'll zip these into the columns so we can (numerically) keep them
    # separate.
    COLUMN_SEPARATORS = Array.new(N_COLUMNS - 1, COLUMN_SEPARATOR_VALUE).freeze

    # The +2 is so we can use any Card's value as well as
    # Card::BLANK_VALUE as well as COLUMN_SEPARATOR_VALUE.  Those two
    # magic values are ugly and should go away, but it'll be easier to
    # do that after specs are written.
    CARD_BIT_WIDTH = Math.log2(Card::DECK_SIZE + 2).ceil

    def cards(arr)
      Array(arr).map { |symbol| Card.new(symbol) }
    end
  end
end

require_relative 'board/presenter'
require_relative 'board/parser'
