# frozen_string_literal: true

module Eus
  # Represents a card.  All cards are frozen.  Ruby comparison works
  # as expected.  #to_s is compact, but #inspect still shows the
  # ivars.
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
      @rank_value = RANK_VALUES[rank]
      # Add one so that the value 0 can be reserved for the "blank" card
      @value = rank_value * N_SUITS + SUIT_VALUES[suit] + 1
      freeze
    end

    attr_reader :rank, :suit, :value, :rank_value

    def eql?(other)
      other.hash == hash
    end

    alias hash value
    alias == eql?

    def to_s
      "#{rank}#{suit}".upcase
    end

    def plays_on_top_of?(other)
      suit == other.suit && rank_value == other.rank_value - 1
    end

    def next
      if rank == HIGHEST_RANK
        nil
      else
        self.class.new(VALUES_RANK[rank_value + 1], suit)
      end
    end

    def self.foundation_card_for_index(index)
      new(LOWEST_RANK, VALUES_SUIT[index])
    end

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

    LOWEST_RANK = RANK_VALUES.keys.first

    HIGHEST_RANK = RANK_VALUES.keys.last

    VALUES_RANK = RANK_VALUES.invert.freeze

    # Suit order is slightly important.  We want the values to represent
    # the foundation suits from top to bottom.
    SUIT_VALUES = frozen_value_hash_factory['suit', 'scdh']
    N_SUITS = SUIT_VALUES.size

    VALUES_SUIT = SUIT_VALUES.invert.freeze
    private_constant :VALUES_SUIT

    DECK_SIZE = N_RANKS * N_SUITS # does not include the blank card
  end
end
