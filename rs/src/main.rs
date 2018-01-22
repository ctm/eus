#![allow(dead_code)]

mod card;

mod board;
use board::Board;

mod solver;
use solver::Solver;

mod card_examiner;
use card_examiner::CardExaminer;

fn main() {
    let board = Board::parse();

    CardExaminer::new(&board).examine();
    
    println!("Solving:\n{}", board);
//    match Solver::new(&board).solution() {
//        Some(solution) => println!("Solution = {:?}", solution),
//        None => println!("No solution"),
//    }
}
