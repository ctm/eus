#![allow(dead_code)]

mod card;

mod board;
use board::Board;

mod solver;
use solver::Solver;

fn main() {
    let board = Board::parse();
    
    println!("Solving:\n{}", board);
    match Solver::new(&board).solution() {
        Some(solution) => println!("Solution = {:?}", solution),
        None => println!("No solution"),
    }
}
