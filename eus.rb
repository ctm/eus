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

require 'pry'

# Represents a card.  All cards are frozen.  Ruby comparison works as
# expected.  #to_s is compact, but #inspect still shows the ivars.
class Card
  # Can pass in strings or symbols, one argument with both, e.g., 'th' for
  # ten of hearts, or two args: 't', 'h'
  def initialize(card_or_rank, optional_suit = nil)
    initial_rank, initial_suit =
      extract_rank_and_suit(card_or_rank, optional_suit)

    @rank = initial_rank.to_sym
    @suit = initial_suit.to_sym
    @value = RANK_VALUES[rank] * N_SUITS + SUIT_VALUES[suit]
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

  SUIT_VALUES = frozen_value_hash_factory['suit', 'cdhs']
  N_SUITS = SUIT_VALUES.size

  DECK_SIZE = N_RANKS * N_SUITS
end

# Represents the board of 8-off, which is the type of solitaire that
# you get on the demo version of Eric's Ultimate Solitaire, which can
# be played at https://archive.org/details/executor
#
# NOTE: Initially we're making the foundation be a four element array
#       where each element itself is an array of cards.  That's silly,
#       because we really only need to know the top-most card.  As such,
#       this representation should be changed fairly soon since it's
#       ugly and was only done so that we could trivialy see if we
#       had used all 52 cards as a sanity check.
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

    @cells = cards(%i[kc 2h 4c 4s])

    @foundations = [[], [], [], []]
  end

  def hash
    42 # TODO
  end

  def eql?(other)
    other.hash == hash
  end

  # This is just for consistency checking during development.
  # Currently it only verifies that each of the 52 cards is used just
  # once, although it does so based on the knowledge that there are
  # exactly Card::DECK_SIZE cards in the deck.
  def check
    unless (columns + cells + foundations).flatten.uniq.size == Card::DECK_SIZE # rubocop:disable GuardClause, LineLength
      raise 'Incorrect number of cards'
    end
  end

  def solved?
    foundations.all? { |f| f.size == Card::N_RANKS }
  end

  def to_s
    Presenter.new(self).to_s
  end

  attr_reader :columns, :cells, :foundations

  private

  def cards(arr)
    Array(arr).map { |symbol| Card.new(symbol) }
  end

  # Provides a nice string representation of a board.
  class Presenter
    def initialize(board)
      @board = board
    end

    def to_s
      rows.join("\n")
    end

    private

    attr_reader :board

    def rows
      column_rows + [''] + foundation_row
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

    BLANK_ROW = ' ' * (Board::N_COLUMNS * 3 - 1)
    private_constant :BLANK_ROW

    def foundation_row
      [''] # TODO
    end

    # Returns an array of strings suitable for pairing up with each of
    # the board rows.  No cards on the foundation will result in an
    # empty array being returned.
    def foundation_strings
      (Array.new(FOUNDATION_ROW_OFFSET, '') + board.foundations.map do |f|
        f.last.to_s
      end).tap do |a|
        a.pop while a.last&.empty?
      end
    end

    FOUNDATION_ROW_OFFSET = 1
    private_constant :FOUNDATION_ROW_OFFSET

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

b = Board.new
b.check
puts b.to_s
