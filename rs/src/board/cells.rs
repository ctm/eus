use std::fmt;

use crate::board;
use crate::card::Card;

pub const N_CELLS: usize = board::N_COLUMNS;

#[derive(Debug, Clone, Copy)]
pub struct Cells {
    pub cards: [Option<Card>; N_CELLS],
}

impl Cells {
    pub fn new() -> Self {
        Self {
            cards: [None; N_CELLS],
        }
    }

    pub fn empty_cell_index(self) -> Option<usize> {
        for (i, card) in self.cards.iter().enumerate() {
            if card.is_none() {
                return Some(i);
            }
        }
        None
    }
}

impl fmt::Display for Cells {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        // This leaves trailing spaces.
        write!(
            f,
            "{}",
            self.cards
                .iter()
                .map(|c| match c {
                    None => "  ".to_string(),
                    Some(card) => format!("{}", card),
                })
                .collect::<Vec<String>>()
                .join(" ")
        )
    }
}
