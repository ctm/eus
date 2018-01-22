// FIXME: think through and/or play with and/or research various type sizes
//        We definitely want a card's value to be u8, since that means we'll
//        be able to represent a Board compactly and efficiently.  Beyond
//        that is unclear.

use std::fmt;

static SUITS: &'static str = "SCDH";
pub const N_SUITS: usize = 4; // Would like SUITS.len();

const RANKS: &'static str = "A23456789TJQK";
pub const N_RANKS: usize = 13; // Would like RANKS.len();

const HIGHEST_RANK: usize = N_RANKS - 1;

const DECK_SIZE: usize = N_SUITS * N_RANKS;

const BLANK_VALUE: u8 = DECK_SIZE as u8 + 1;

#[derive(PartialOrd, Ord, Eq, PartialEq, Debug, Clone, Copy)]
pub struct Card {
    pub value: u8,
}

impl Card {
    pub fn new_rank_suit(rank_char: char, suit_char: char) ->Self {
        if rank_char == ' ' && suit_char == ' ' {
            return Self { value: BLANK_VALUE }
        }
        let rank = RANKS.find(rank_char).unwrap();
        let suit = SUITS.find(suit_char).unwrap();

        Self { value: Self::value_for_suit_and_rank(suit, rank) }
    }

    pub fn blank() -> Self {
        Self { value: BLANK_VALUE }
    }

    pub fn is_blank(&self) -> bool {
        self.value == BLANK_VALUE
    }

    pub fn is_lowest_rank(&self) -> bool {
        self.rank() == 0
    }

    pub fn is_highest_rank(&self) -> bool {
        self.rank() == HIGHEST_RANK
    }

    pub fn plays_on_top_of(&self, other: Self) -> bool {
        other.is_blank() ||
            (self.suit() == other.suit() && self.rank() + 1 == other.rank())
    }

    pub fn suit(&self) -> usize {
        self.value as usize % N_SUITS
    }

    fn value_for_suit_and_rank(suit: usize, rank: usize) -> u8 {
        (rank * N_SUITS + suit) as u8
    }

    fn for_suit_and_rank(suit: usize, rank: usize) -> Self {
        Self { value: Self::value_for_suit_and_rank(suit, rank) }
    }

    pub fn rank(&self) -> usize {
        self.value as usize / N_SUITS
    }

    fn next_higher_card(&self) -> Option<Self> {
        if self.rank() == HIGHEST_RANK {
            None
        } else {
            Some(Self::for_suit_and_rank(self.suit(), self.rank() + 1))
        }
    }
}

impl fmt::Display for Card {
    // It's frustrating that I don't know how to precompute all the
    // strings for all possible values and then just index into them.
    //
    // Actually, I know how to do this now, but I haven't done it yet.
    // I'm going to get the parser working, first.
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}",
               if self.value == BLANK_VALUE {
                   String::from("  ")
               } else {
                   let rank = self.rank();
                   let suit = self.suit();

                   String::from(&RANKS[rank .. rank+1]) +
                       &SUITS[suit .. suit+1]
               })
    }
}
