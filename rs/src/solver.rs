use std::collections::HashSet;

use crate::board::Board;

// Don't need either of these, but at least Hash isn't in there.
#[derive(Debug)]
pub struct Solver {
    board: Board,
}

impl Solver {
    pub fn new(board: &Board) -> Self {
        let mut new_board = *board;
        new_board.make_automatic_moves();
        Self { board: new_board }
    }

    pub fn solution(&self) -> Option<Vec<(&'static str, u8, u8)>> {
        let mut reversed_solution = vec![];
        if !self.solve(&mut HashSet::new(), &mut reversed_solution) {
            None
        } else {
            reversed_solution.reverse();
            Some(reversed_solution)
        }
    }

    // Using an &str for the first of the tuples is gross, but I'm
    // too lazy to make an Enum yet
    pub fn solve(
        &self,
        seen: &mut HashSet<Board>,
        solution: &mut Vec<(&'static str, u8, u8)>,
    ) -> bool {
        if self.board.is_solved() {
            true
        } else {
            seen.insert(self.board);

            self.column_to_card_column(seen, solution)
                || self.column_to_empty_column(seen, solution)
                || self.column_to_cell(seen, solution)
                || self.cell_to_card_column(seen, solution)
                || self.cell_to_empty_column(seen, solution)
        }
    }

    fn column_to_card_column(
        &self,
        seen: &mut HashSet<Board>,
        solution: &mut Vec<(&'static str, u8, u8)>,
    ) -> bool {
        for from in Board::column_index_iterator() {
            for to in Board::column_index_iterator() {
                if from != to {
                    // This is a premature optimization.  FIXME: benchmark without
                    if Self::helper(
                        self.board.column_to_card_column(from, to),
                        "move_column_to_card_column",
                        from,
                        to,
                        seen,
                        solution,
                    ) {
                        return true;
                    }
                }
            }
        }
        false
    }

    fn column_to_empty_column(
        &self,
        seen: &mut HashSet<Board>,
        solution: &mut Vec<(&'static str, u8, u8)>,
    ) -> bool {
        if let Some(to) = self.board.empty_column() {
            for from in Board::column_index_iterator() {
                if Self::helper(
                    self.board.column_to_empty_column(from, to),
                    "move_column_to_empty_column",
                    from,
                    to,
                    seen,
                    solution,
                ) {
                    return true;
                }
            }
        }
        false
    }

    fn column_to_cell(
        &self,
        seen: &mut HashSet<Board>,
        solution: &mut Vec<(&'static str, u8, u8)>,
    ) -> bool {
        if let Some(to) = self.board.cells.empty_cell_index() {
            for from in Board::column_index_iterator() {
                if Self::helper(
                    self.board.column_to_cell(from, to),
                    "move_column_to_cell",
                    from,
                    to,
                    seen,
                    solution,
                ) {
                    return true;
                }
            }
        }
        false
    }

    fn cell_to_card_column(
        &self,
        seen: &mut HashSet<Board>,
        solution: &mut Vec<(&'static str, u8, u8)>,
    ) -> bool {
        for from in Board::cell_index_iterator() {
            for to in Board::column_index_iterator() {
                if Self::helper(
                    self.board.cell_to_card_column(from, to),
                    "move_cell_to_card_column",
                    from,
                    to,
                    seen,
                    solution,
                ) {
                    return true;
                }
            }
        }
        false
    }

    fn cell_to_empty_column(
        &self,
        seen: &mut HashSet<Board>,
        solution: &mut Vec<(&'static str, u8, u8)>,
    ) -> bool {
        if let Some(to) = self.board.empty_column() {
            for from in Board::cell_index_iterator() {
                if Self::helper(
                    self.board.cell_to_empty_column(from, to),
                    "move_cell_to_empty_column",
                    from,
                    to,
                    seen,
                    solution,
                ) {
                    return true;
                }
            }
        }
        false
    }

    fn helper(
        maybe_board: Option<Board>,
        step_name: &'static str,
        from: usize,
        to: usize,
        seen: &mut HashSet<Board>,
        solution: &mut Vec<(&'static str, u8, u8)>,
    ) -> bool {
        if let Some(board) = maybe_board {
            if seen.contains(&board) {
                return false;
            }
            if Self::new(&board).solve(seen, solution) {
                solution.push((step_name, from as u8, to as u8));
                return true;
            }
        }
        false
    }
}
