use crate::card;
use crate::card::Card;

// The largest column would be one that happens to start with a king
// and then has all the other ranks laid on top of it down to a deuce.
// It's impossible to add an ace, because exposed aces are auto-moved
// to the foundation.  So we subtract two from N_RANKS because the
// king has to already be in the starting column and we can't put an
// ace on it.
const STARTING_DEPTH: usize = 6;
pub const MAX_COLUMN_SIZE: usize = STARTING_DEPTH + card::N_RANKS - 2;

#[derive(Eq, PartialEq, Debug, Clone, Copy)]
pub struct Column {
    pub cards: [Option<Card>; MAX_COLUMN_SIZE],
}

impl Column {
    pub fn new() -> Self {
        Self {
            cards: [None; MAX_COLUMN_SIZE],
        }
    }

    pub fn top_card_and_index(&self) -> (Option<Card>, usize) {
        let mut index = 0;

        while index < MAX_COLUMN_SIZE - 1 && self.cards[index + 1].is_some() {
            index += 1
        }
        (self.cards[index], index)
    }
}

use std::cmp::Ordering;

impl Ord for Column {
    fn cmp(&self, other: &Self) -> Ordering {
        if self.cards < other.cards {
            Ordering::Less
        } else if self.cards > other.cards {
            Ordering::Greater
        } else {
            Ordering::Equal
        }
    }
}

impl PartialOrd for Column {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        self.cards.partial_cmp(&other.cards)
    }
}
