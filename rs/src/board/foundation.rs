use card;
use card::Card;
use board;
use board::Column;
use board::column;

pub const SEPARATOR: &str = "  ";

pub const FOUNDATION_ROW_OFFSET: usize = 1;
pub const N_CARDS: usize = card::N_SUITS;

#[derive(Debug, Clone, Copy)]
pub struct Foundation {
    pub cards: [Card; N_CARDS],
}

impl Foundation {
    pub fn new() -> Self {
        Self { cards: [Card::blank(); card::N_SUITS] }
    }

    pub fn is_solved(&self) -> bool {
        self.cards.iter().all (|c| c.is_highest_rank())
    }

    pub fn with_columns_to_s(&self, columns: &[Column; board::N_COLUMNS]) -> String {
        let mut s = String::with_capacity(256);
        let mut i = 0;
        let mut done = false;

        while !done {
            if i == column::MAX_COLUMN_SIZE {
                done = true;
            } else {
                {
                    let cards = columns.iter().map(|column| column.cards[i]).collect::<Vec<Card>>();
                    
                    done = i >= FOUNDATION_ROW_OFFSET + N_CARDS &&
                          cards.iter().all(|card| card.is_blank());
                    if !done {
                        s.push_str(&cards.iter()
                                         .map(|card| format!("{}", card))
                                         .collect::<Vec<String>>()
                                         .join(" "));
                        self.optionally_add_foundation_card(&mut s, i);
                        s.push('\n')
                    }
                }
                i += 1;
            }
        }
        s
    }

    fn optionally_add_foundation_card(&self, s: &mut String, i: usize) {
        if i >= FOUNDATION_ROW_OFFSET {
            let i = i - FOUNDATION_ROW_OFFSET;
            if i < N_CARDS {
                let card = self.cards[i];

                if !card.is_blank() {
                    s.push_str(SEPARATOR);
                    s.push_str(&format!("{}", card));
                }
            }
        }
    }
}
