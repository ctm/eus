# frozen_string_literal: true

require 'set'
require 'board'

module Eus
  class Solver # rubocop:disable Documentation
    # TODO: remove depth once we're comfortable everything works right
    def initialize(source, seen = Set.new, depth = 0)
      @board = (source.is_a?(Board) ? source : Board.parse(source)).deep_freeze
      @seen = seen
      @depth = depth
    end

    def solve
      return [] if board.solved?

      seen << board
      column_to_card_column || column_to_empty_column || column_to_cell ||
        cell_to_column
    end

    private

    attr_reader :board, :seen, :depth

    def column_to_card_column
      Board::CARD_COLUMN_INDEXES.any? do |from|
        Board::CARD_COLUMN_INDEXES.any? do |to|
          next if from == to

          helper(:move_column_to_card_column, from, to)
        end
      end
    end

    def column_to_empty_column
      return nil unless (to = empty_column_index)

      Board::CARD_COLUMN_INDEXES.any? do |from|
        helper(:move_column_to_empty_column, from, to)
      end
    end

    def column_to_cell
      return nil unless (to = empty_cell_index)

      Board::CARD_COLUMN_INDEXES.any? do |from|
        helper(:move_column_to_cell, from, to)
      end
    end

    def cell_to_column
      Board::CELL_INDEXES.any? do |from|
        Board::CARD_COLUMN_INDEXES.any? do |to|
          helper(:move_cell_to_column, from, to)
        end
      end
    end

    def helper(method, from, to)
      return nil unless (new_board = board.send(method, from, to))
      return nil if seen.include?(new_board)

      STDERR.puts "#{depth}: #{method}(#{from}, #{to})"

      solution = Solver.new(new_board, seen, depth + 1).solve
      [method, from, to] + solution if solution
    end

    def empty_column_index
      @empty_column_index ||= Board::CARD_COLUMN_INDEXES.detect do |index|
        board.columns[index].empty?
      end
    end

    def empty_cell_index
      @empty_cell_index ||= Board::CELL_INDEXES.detect do |index|
        board.cells[index].nil?
      end
    end
  end
end
