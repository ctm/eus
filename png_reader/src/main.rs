#![allow(dead_code)]

extern crate image;

use image::GenericImage;
use image::Rgba;

// NOTE: We are setting N_COLUMN_ROWS to 6 currently since I only anticipate reading in
//       starting boards during development.  Eventually we'll want to be able to read
//       in any board, but this code should be refactored before then.

const N_COLUMNS: usize = 8;
const N_COLUMN_ROWS: usize = 6;
const COLUMNS_LEFT_TOP: (usize, usize) = (104, 44);
const COLUMN_SPACING: (usize, usize) = (56, 18);

const N_FOUNDATIONS: usize = 4;
const FOUNDATION_LEFT_TOP: (usize, usize) = (584, 51);
const FOUNDATION_SPACING: (usize, usize) = (0, 73);

const N_CELLS: usize = 8;
const CELLS_LEFT_TOP: (usize, usize) = (104, 361);
const CELL_SPACING: (usize, usize) = (56, 0);

const RANK_OFFSET: (usize, usize) = (3, 2);
const RANK_DIMENSIONS: (usize, usize) = (9, 12);

const NORMAL_SUIT_OFFSET: (usize, usize) = (14, 2);
const TEN_SUIT_OFFSET: (usize, usize) = (20, 2);
const SUIT_DIMENSIONS: (usize, usize) = (11, 12);

const WANTED: Rgba<u8> = Rgba::<u8> { data: [0, 255, 0, 255] };

fn main() {
    let img = image::open("/Users/ctm/eus/boards/green_dots.png").unwrap();

    for (x, y, pixel) in img.pixels() {
        if pixel == WANTED {
            println!("{}, {}", x, y);
        }
    }
}
