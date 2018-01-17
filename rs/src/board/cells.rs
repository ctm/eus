use std::fmt;

use card::Card;
use board;

pub const N_CELLS: usize = board::N_COLUMNS;

#[derive(Debug, Clone, Copy)]
pub struct Cells {
    pub cards: [Card; N_CELLS],
}

impl Cells {
    pub fn new() -> Self {
        Self { cards: [Card::blank(); N_CELLS] }
    }

    pub fn empty_cell_index(&self) -> Option<usize> {
        for (i, card) in self.cards.iter().enumerate() {
            if card.is_blank() {
                return Some(i)
            }
        }
        None
    }
}

impl fmt::Display for Cells {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        // This leaves trailing spaces.
        write!(f, "{}",
               self.cards
                   .iter()
                   .map(|c| format!("{}", c))
                   .collect::<Vec<String>>().join(" "))
    }
}
