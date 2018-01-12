#! /usr/bin/env ruby

# frozen_string_literal: true

# This is some code that's a step above hack-and-slash, but is still
# far from polished.  The idea is to solve instances of Eric's
# Ultimate Solitaire using brute force.  Really it's just a chance to
# program something slightly interesting to me and to explore various
# techniques along the way.
#
# Although I'll quite possibly give up before the end-game, it might
# be nice to eventually expand this into an app that actually *plays*
# Eric's Ultimate Solitaire running on a web browser that is visiting
# https://archive.org/details/executor That will require figuring out
# how to actually read the board and how to do input into the browser
# and I may easily lose interest before then.  Heck, if my first
# attempt to write a solver crashes and burns I may not even try
# again.  It's not like I don't have a lot of other stuff to do.
#
# Oh, this also gives me a chance to play with a representation of cards
# in Ruby, with an eye toward perhaps doing the same in Rust.  For
# example, once (if?!) I get the solver running in Ruby I might port it
# to Rust.  That would be fun, because learning Rust is fun.  It might
# also be useful to driving a web page, because Rust can be (I understand
# compiled to WebAssembly).
#
# In reality, I'll only work on this in fits and starts and may never
# do anything with it.

# TODO: consider whether I want to be super consistent and use a blank
#       card everywhere instead of nil to represent no card.  Currently
#       I don't even *have* a blank card, although I do reserve the value
#       0 for one.

require 'pry'

# Represents a card.  All cards are frozen.  Ruby comparison works as
# expected.  #to_s is compact, but #inspect still shows the ivars.
class Card
  # There is currently no way to construct a card with a 0 for its value,
  # howevever, in places where we either have a card or nil and we need
  # a value to represent it, we use 0.  This is ugly and may change.
  BLANK_VALUE = 0

  # Can pass in strings or symbols, one argument with both, e.g., 'th' for
  # ten of hearts, or two args: 't', 'h'
  def initialize(card_or_rank, optional_suit = nil)
    initial_rank, initial_suit =
      extract_rank_and_suit(card_or_rank, optional_suit)

    @rank = initial_rank.to_sym
    @suit = initial_suit.to_sym
    # Add one so that the value 0 can be reserved for the "blank" card
    @value = RANK_VALUES[rank] * N_SUITS + SUIT_VALUES[suit] + 1
    freeze
  end

  def eql?(other)
    other.hash == hash
  end

  def to_s
    "#{rank}#{suit}".upcase
  end

  attr_reader :rank, :suit, :value

  alias hash value
  alias == eql?

  private

  def extract_rank_and_suit(card_or_rank, optional_suit)
    if card_or_rank.size == 2 && optional_suit.nil?
      card_or_rank.to_s.each_char.to_a
    elsif card_or_rank.size == 1 && optional_suit&.size == 1
      [card_or_rank, optional_suit]
    else
      raise "card_or_rank: #{card_or_rank}, optional_suit: #{optional_suit}"
    end
  end

  # Uses a lambda here to make it clear that there's no other use of this
  # code than creating RANK_VALUES and SUIT_VALUES
  frozen_value_hash_factory = lambda do |kind, chars|
    chars.each_char.with_index.with_object({}) do |(char, value), h|
      h[char.to_sym] = value
    end.tap do |h| # rubocop:disable MultilineBlockChain
      h.default_proc = ->(_h, k) { raise "Unknown #{kind} #{k}" }
      h.freeze
    end
  end

  RANK_VALUES = frozen_value_hash_factory['rank', 'a23456789tjqk']
  N_RANKS = RANK_VALUES.size

  HIGHEST_RANK = RANK_VALUES.keys.last

  VALUES_RANK = RANK_VALUES.invert.freeze

  SUIT_VALUES = frozen_value_hash_factory['suit', 'cdhs']
  N_SUITS = SUIT_VALUES.size

  DECK_SIZE = N_RANKS * N_SUITS # does not include the blank card
end

# Represents the board of 8-off, which is the type of solitaire that
# you get on the demo version of Eric's Ultimate Solitaire, which can
# be played at https://archive.org/details/executor
class Board
  N_COLUMNS = 8

  # This hard-codes a game that I had trouble solving manually.
  def initialize
    @columns = [%i[qs jh 5c 7d kh 9s],
                %i[9d 5d ks ad 4d 7h],
                %i[3c 8h 4h 6s jc qd],
                %i[2c kd 7c 2d 8c 6h],
                %i[6d 7s as js qh 3h],
                %i[6c ah 5s 9c 2s th],
                %i[5h tc 3s 8s 8d 9h],
                %i[ts jd ac td 3d qc]].map { |y| cards(y) }

    @cells = cards(%i[kc 2h 4c 4s]) + [nil, nil, nil, nil]

    @foundations = [nil, nil, nil, nil]
  end

  def self.parse(string_or_io)
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
    cards.map { |f| f&.value || 0 }.sort
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
  # This will be useful in Board when we construct a hash, because
  # we can construct a perfect hash if we simply shift card values
  # by their position (i.e. in a column or foundation) and or them
  # together.  Perhaps it's premature optimization, but hey, I can't
  # help but think of things like this after all my poker work.
  #
  # The +2 is so we can use any Card's value as well as
  # Card::BLANK_VALUE as well as COLUMN_SEPARATOR_VALUE.
  # These magic values are ugly and should go away, but it'll be easier
  # to do that after specs are written.
  CARD_BIT_WIDTH = Math.log2(Card::DECK_SIZE + 2).ceil

  def cards(arr)
    Array(arr).map { |symbol| Card.new(symbol) }
  end

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

  # Reads the output of Presenter
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

b = Board.new
b.check
puts b.hash
puts b.to_s
bprime = Board.parse(StringIO.new(b.to_s))
bprime.check
raise 'b not == to bprime' unless b == bprime
raise 'b not eql? to bprime' unless b.eql?(bprime)

b2 = Board.parse(File.open('template'))
b2.check
puts b2.to_s
puts b2.hash
b2prime = Board.parse(StringIO.new(b2.to_s))
b2prime.check
raise 'b2 not == to b2prime' unless b2 == b2prime
raise 'b2 not eql? to b2prime' unless b2.eql?(b2prime)
