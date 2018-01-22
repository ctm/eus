// Hack and slash code to go through all the board locations, compute a hash
// for the rank and suit, compare it to what we've previously computed (if
// anything) and panic if there's a difference.  At the end, dump out the
// hash values for each of the ranks and suits.

// BTW, Thank you, Justin, for providing me with a link to
// https://stackoverflow.com/questions/923885/capture-html-canvas-as-gif-jpg-png-pdf
// which contains this snippet that I used to capture the board:
//
//   javascript:void(window.open().location =
//     document.getElementsByTagName("canvas")[0].toDataURL("image/‌​png"))

use board;
use board::Board;

use card;

extern crate image;

use self::image::DynamicImage;
use self::image::GenericImage;

use std::collections::hash_map::DefaultHasher;

use std::hash::{Hash, Hasher};

const COLUMNS_LEFT_TOP: (usize, usize) = (104, 44);
const COLUMN_SPACING: (usize, usize) = (56, 18);

const RANK_OFFSET: (usize, usize) = (3, 2);
const RANK_DIMENSIONS: (usize, usize) = (7, 12);

const SUIT_DIMENSIONS: (usize, usize) = (11, 12);

pub struct CardExaminer<'a> {
    board: &'a Board,
    image: DynamicImage,
    rank_hashes: [Option<u64>; card::N_RANKS],
    suit_hashes: [Option<u64>; card::N_SUITS],
}

impl<'a> CardExaminer<'a> {
    pub fn new(board: &'a Board) -> Self {
        let img = image::open("/Users/ctm/eus/boards/board.png").unwrap();
        Self {
            board: board,
            image: img,
            rank_hashes: [None; card::N_RANKS],
            suit_hashes: [None; card::N_SUITS],
        }
    }

    pub fn examine(&mut self) {
        self.examine_columns();
        self.examine_cells();
        self.examine_foundation();

        println!("Rank hashes");
        for hash in self.rank_hashes.iter() {
            println!("{:x}", hash.unwrap());
        }

        println!("Suit hashes");
        for hash in self.suit_hashes.iter() {
            println!("{:x}", hash.unwrap());
        }
        
    }
    
    fn examine_columns(&mut self) {
        for row in 0..board::column::MAX_COLUMN_SIZE {
            for column in 0..board::N_COLUMNS {
                let card = self.board.columns[column].cards[row];
                if card.is_blank() {
                    // TODO: make sure we get a blank hash
                } else {
                    let rank = card.rank();
                    let suit = card.suit();

                    let rank_hash = self.rank_hash_at(self.column_rank_location(row, column));
                    let suit_hash = self.suit_hash_at(self.column_suit_location(row, column));

                    self.note_rank_and_suit_hashes(rank, suit, rank_hash, suit_hash);
                }
            }
        }
    }

    fn examine_cells(&self) {
        // TODO
    }

    fn examine_foundation(&self) {
        // TODO
    }

    fn column_rank_location(&self, row: usize, column: usize) -> (usize, usize) {
        let (left, top) = COLUMNS_LEFT_TOP;
        let (delta_x, delta_y) = COLUMN_SPACING;
        let (rank_offset_x, rank_offset_y) = RANK_OFFSET;
        (left + column * delta_x + rank_offset_x, top + row * delta_y + rank_offset_y)
    }

    fn rank_hash_at(&self, location: (usize, usize)) -> u64 {
        let mut s = DefaultHasher::new();
        let (start_x, start_y) = location;
        let (width, height) = RANK_DIMENSIONS;
        let stop_x = start_x + width;
        let stop_y = start_y + height;
        for y in start_y..stop_y {
            for x in start_x..stop_x {
                let pixel = self.image.get_pixel(x as u32, y as u32);
                let g = pixel.data[1];
                let b = pixel.data[2];

                g.hash(&mut s);
                b.hash(&mut s);
            }
        }
        s.finish()
    }

    fn column_suit_location(&self, row: usize, column: usize) -> (usize, usize) {
        self.suit_location_from_rank_location(self.column_rank_location(row, column))
    }

    fn suit_location_from_rank_location(&self, start: (usize, usize)) -> (usize, usize) {
        let (start_x, start_y) = start;
        let (rank_width, rank_height) = RANK_DIMENSIONS;
        let mut x = start_x + rank_width + 2;
        let mut y = start_y;

        while !self.is_white_column(x-2, y, rank_height) ||
              !self.is_white_column(x-1, y, rank_height) {
            x += 1;
        }
        while !self.has_three_non_white(x, y, rank_width) {
            y += 1;
        }
        (x, y)
    }

    fn is_white_column(&self, left: usize, top: usize, height: usize) -> bool {
        // We cheat and use the green component being 255 as a proxy for white
        (top..top+height).all(|y| self.image.get_pixel(left as u32, y as u32).data[1] == 255)
    }

    fn has_three_non_white(&self, left: usize, top: usize, width: usize) -> bool {
        let mut non_white_count = 0;
        for x in left..left+width {
            let pixel = self.image.get_pixel(x as u32, top as u32);
            // We cheat and use the green component being 255 as a proxy for white
            let g = pixel.data[1];
            if g != 255 {
                non_white_count += 1;
                if non_white_count == 3 {
                    return true;
                }
            }
        }
        false
    }
    

    fn suit_hash_at(&self, location: (usize, usize)) -> u64 {
        let mut s = DefaultHasher::new();
        let (start_x, start_y) = location;
        let (width, height) = SUIT_DIMENSIONS;
        let stop_x = start_x + width;
        let stop_y = start_y + height;
        for y in start_y..stop_y {
            for x in start_x..stop_x {
                let pixel = self.image.get_pixel(x as u32, y as u32);
                let g = pixel.data[1];
                let b = pixel.data[2];

                g.hash(&mut s);
                b.hash(&mut s);
            }
        }
        s.finish()
    }

    fn note_rank_and_suit_hashes(&mut self, rank: usize, suit: usize,
                                 rank_hash: u64, suit_hash: u64) {
        Self::note_helper("rank", &mut self.rank_hashes[rank], rank_hash);
        Self::note_helper("suit", &mut self.suit_hashes[suit], suit_hash);
    }

    fn note_helper(what: &'static str, hash_ref: &mut Option<u64>, hash: u64) {
        match *hash_ref {
            Some(existing_hash) => {
                if existing_hash != hash {
                    // FWIW, we're not saying which rank or suit didn't match, but then
                    // again, I hope we never get here and if we do, I hope to learn how
                    // to use a debugger.
                    panic!("Bad hash for {}", what);
                }
            },
            None => *hash_ref = Some(hash),
        }
    }
}
