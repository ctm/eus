# frozen_string_literal: true

require 'set'

require 'board'

module Eus
  class Solver # rubocop:disable Documentation
    # depth is just for debugging
    def initialize(source, seen = Set.new, depth = 0)
      @board = source.is_a?(Board) ? source : Board.parse(source).deep_freeze
      @seen = seen
      @depth = depth
    end

    def solve # rubocop:disable MethodLength, AbcSize
      return [] if board.solved?

      new_seen = (seen + [board]).freeze
      SOURCE_INDEXES.each do |from|
        SOURCE_INDEXES.each do |to|
          next unless (new_board = board.move(from, to))
          next if seen.include?(new_board)

          STDERR.puts "#{depth}: from: #{from}, to: #{to}"

          solution = Solver.new(new_board, new_seen, depth + 1).solve
          return [from, to] + solution if solution
        end
      end

      nil
    end

    private

    attr_reader :board, :seen, :depth

    # TODO: probably want something other than a hardcoded constant
    SOURCE_INDEXES = (0...16).freeze
  end
end
