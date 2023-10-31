use std::fmt;
use std::num::NonZeroU8;

const SUITS: &str = "SCDH";
pub const N_SUITS: usize = SUITS.len();

const RANKS: &str = "A23456789TJQK";
pub const N_RANKS: usize = RANKS.len();

const HIGHEST_RANK: usize = N_RANKS - 1;

const DECK_SIZE: usize = N_SUITS * N_RANKS;

#[derive(PartialOrd, Ord, Eq, PartialEq, Debug, Clone, Copy)]
pub struct Card {
    pub value: NonZeroU8,
}

impl Card {
    pub fn new_rank_suit(rank_char: char, suit_char: char) -> Option<Self> {
        if rank_char == ' ' && suit_char == ' ' {
            return None;
        }
        let rank = RANKS.find(rank_char).unwrap();
        let suit = SUITS.find(suit_char).unwrap();

        Some(Self {
            value: Self::value_for_suit_and_rank(suit, rank),
        })
    }

    pub fn is_lowest_rank(self) -> bool {
        self.rank() == 0
    }

    pub fn is_highest_rank(self) -> bool {
        self.rank() == HIGHEST_RANK
    }

    pub fn plays_on_top_of(self, other: Option<Self>) -> bool {
        match other {
            None => true,
            Some(other_value) => {
                self.suit() == other_value.suit() && self.rank() + 1 == other_value.rank()
            }
        }
    }

    pub fn suit(self) -> usize {
        (self.value.get() as usize - 1) % N_SUITS
    }

    fn value_for_suit_and_rank(suit: usize, rank: usize) -> NonZeroU8 {
        NonZeroU8::new(((rank * N_SUITS + suit) + 1) as u8).unwrap()
    }

    fn for_suit_and_rank(suit: usize, rank: usize) -> Self {
        Self {
            value: Self::value_for_suit_and_rank(suit, rank),
        }
    }

    fn rank(self) -> usize {
        (self.value.get() as usize - 1) / N_SUITS
    }

    fn next_higher_card(self) -> Option<Self> {
        if self.rank() == HIGHEST_RANK {
            None
        } else {
            Some(Self::for_suit_and_rank(self.suit(), self.rank() + 1))
        }
    }
}

impl fmt::Display for Card {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let rank = self.rank();
        let suit = self.suit();
        write!(f, "{}{}", &RANKS[rank..=rank], &SUITS[suit..=suit])
    }
}
