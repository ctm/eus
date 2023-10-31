use std::fmt;
use std::io;
use std::io::BufRead;

use crate::card::Card;

mod foundation;
use self::foundation::Foundation;

mod cells;
use self::cells::Cells;

mod column;
use self::column::Column;

pub const N_COLUMNS: usize = 8;
pub const N_CELLS: usize = cells::N_CELLS;

const FOUNDATION_RANK_OFFSET: usize = N_COLUMNS * 3 + 1;
const FOUNDATION_SUIT_OFFSET: usize = FOUNDATION_RANK_OFFSET + 1;

trait HashValue {
    fn hash_value(&self) -> u8;
}

impl HashValue for Option<Card> {
    fn hash_value(&self) -> u8 {
        match self {
            None => 255,
            Some(card) => card.value.get(),
        }
    }
}

#[derive(Debug, Clone, Copy)]
pub struct Board {
    pub foundation: Foundation,
    pub cells: Cells,
    columns: [Column; N_COLUMNS],
}

impl Board {
    fn check(&self) {
        // I never got around to implementing this, because I was able
        // to put in some println!s here and there and compare what
        // was happening to the ruby version.
    }

    // NOTE: putting this into a Parser class might be a little cleaner
    pub fn parse() -> Self {
        let mut foundation = Foundation::new();
        let mut cells = Cells::new();
        let mut columns = [Column::new(); N_COLUMNS];

        let stdin = io::stdin();
        let mut lines = stdin
            .lock()
            .lines()
            .map(|l| l.unwrap())
            .collect::<Vec<String>>();

        let cell_line = lines.pop().unwrap();
        lines.pop();

        for (row_number, line) in lines.iter().enumerate() {
            for (column_number, column) in columns.iter_mut().enumerate().take(N_COLUMNS) {
                column.cards[row_number] =
                    Self::card_from_line_indexed_by_column(line, column_number);
            }
            Self::optionally_add_foundation_card(&mut foundation, row_number, line);
        }
        Self::set_cells(&mut cells, &cell_line);

        Self {
            foundation,
            cells,
            columns,
        }
    }

    pub fn make_automatic_moves(&mut self) {
        while self.column_automatic_move() || self.cell_automatic_move() {}
    }

    fn column_automatic_move(&mut self) -> bool {
        for column_index in 0..N_COLUMNS {
            let (from_card, from_index) = self.columns[column_index].top_card_and_index();

            if self.play_on_foundation(from_card) {
                self.columns[column_index].cards[from_index] = None;
                return true;
            }
        }
        false
    }

    fn cell_automatic_move(&mut self) -> bool {
        for cell_index in 0..N_CELLS {
            let from_card = self.cells.cards[cell_index];

            if self.play_on_foundation(from_card) {
                self.cells.cards[cell_index] = None;
                return true;
            }
        }
        false
    }

    fn play_on_foundation(&mut self, from_ocard: Option<Card>) -> bool {
        match from_ocard {
            None => false,
            Some(from_card) => {
                let suit = from_card.suit();
                let to_card = self.foundation.cards[suit];

                match to_card {
                    None => {
                        if !from_card.is_lowest_rank() {
                            return false;
                        }
                    }
                    Some(to_card) => {
                        if !to_card.plays_on_top_of(from_ocard) {
                            return false;
                        }
                    }
                }
                self.foundation.cards[suit] = from_ocard;
                true
            }
        }
    }

    pub fn is_solved(&self) -> bool {
        self.foundation.is_solved()
    }

    pub fn column_to_card_column(&self, from: usize, to: usize) -> Option<Self> {
        let (from_ocard, from_index) = self.columns[from].top_card_and_index();
        from_ocard.and_then(|from_card| {
            let (to_card, to_index) = self.columns[to].top_card_and_index();

            if to_card.is_none() || !from_card.plays_on_top_of(to_card) {
                return None;
            }

            let mut board = *self;

            board.columns[from].cards[from_index] = None;
            board.columns[to].cards[to_index + 1] = from_ocard;

            Some(board)
        })
    }

    pub fn column_to_empty_column(&self, from: usize, to: usize) -> Option<Self> {
        let (from_card, from_index) = self.columns[from].top_card_and_index();

        from_card.map(|_| {
            let mut board = *self;

            board.columns[from].cards[from_index] = None;
            board.columns[to].cards[0] = from_card;
            board
        })
    }

    pub fn column_to_cell(&self, from: usize, to: usize) -> Option<Self> {
        let (from_card, from_index) = self.columns[from].top_card_and_index();

        from_card?;

        let mut board = *self;

        board.columns[from].cards[from_index] = None;
        board.cells.cards[to] = from_card;

        Some(board)
    }

    pub fn cell_to_card_column(&self, from: usize, to: usize) -> Option<Self> {
        let from_ocard = self.cells.cards[from];

        match from_ocard {
            None => None,
            Some(from_card) => {
                let (to_card, to_index) = self.columns[to].top_card_and_index();

                if to_card.is_none() || !from_card.plays_on_top_of(to_card) {
                    return None;
                }

                let mut board = *self;

                board.cells.cards[from] = None;
                board.columns[to].cards[to_index + 1] = from_ocard;

                Some(board)
            }
        }
    }

    pub fn cell_to_empty_column(&self, from: usize, to: usize) -> Option<Self> {
        let from_card = self.cells.cards[from];

        from_card?;

        let mut board = *self;

        board.cells.cards[from] = None;
        board.columns[to].cards[0] = from_card;

        Some(board)
    }

    pub fn empty_column(&self) -> Option<usize> {
        (0..N_COLUMNS).find(|&column_number| self.columns[column_number].cards[0].is_none())
    }

    fn card_from_line_indexed_by_column(line: &str, column: usize) -> Option<Card> {
        let offset = column * 3;

        if let Some(rank_char) = line.chars().nth(offset) {
            if let Some(suit_char) = line.chars().nth(offset + 1) {
                return Card::new_rank_suit(rank_char, suit_char);
            }
        }
        None
    }

    fn optionally_add_foundation_card(foundation: &mut Foundation, row_number: usize, line: &str) {
        if row_number >= foundation::FOUNDATION_ROW_OFFSET {
            let index = row_number - foundation::FOUNDATION_ROW_OFFSET;
            if index < foundation::N_CARDS {
                if let Some(rank_char) = line.chars().nth(FOUNDATION_RANK_OFFSET) {
                    if let Some(suit_char) = line.chars().nth(FOUNDATION_SUIT_OFFSET) {
                        foundation.cards[index] = Card::new_rank_suit(rank_char, suit_char);
                    }
                }
            }
        }
    }

    fn set_cells(cells: &mut Cells, line: &str) {
        for column_number in 0..N_COLUMNS {
            cells.cards[column_number] =
                Self::card_from_line_indexed_by_column(line, column_number);
        }
    }

    fn hash_bytes(&self) -> Vec<u8> {
        let mut bytes = self
            .foundation
            .cards
            .iter()
            .map(|c| c.hash_value())
            .collect::<Vec<u8>>();
        let mut cell_bytes = self
            .cells
            .cards
            .iter()
            .map(|c| c.hash_value())
            .collect::<Vec<u8>>();
        cell_bytes.sort();
        bytes.append(&mut cell_bytes);
        let mut columns = self
            .columns
            .iter()
            .map(|column| {
                column
                    .cards
                    .iter()
                    .map(|card| card.hash_value())
                    .collect::<Vec<u8>>()
            })
            .collect::<Vec<Vec<u8>>>();
        columns.sort();
        for mut column_bytes in columns {
            bytes.append(&mut column_bytes);
        }
        bytes
    }
}

impl fmt::Display for Board {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(
            f,
            "{}\n{}",
            self.foundation.with_columns_to_s(&self.columns),
            self.cells
        )
    }
}

use std::hash::{Hash, Hasher};

impl Hash for Board {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.hash_bytes().hash(state);
    }
}

impl PartialEq for Board {
    fn eq(&self, other: &Self) -> bool {
        self.hash_bytes() == other.hash_bytes()
    }
}

impl Eq for Board {}
