# frozen_string_literal: true

module Eus
  # Methods that aren't specific to any other source file.
  module Util
    # NOTE: this is not at all Eus specific.  It implements zip
    # for an arbitrary number of arrays, but always returns arrays whose
    # length is the length of the largest of the arrays passed in.
    #
    # For example,
    #
    #   a = [1, 2]
    #   b = [3, 4, 5]
    #   c = [7]
    #   a.zip(b, c)
    #   => [[1, 3, 7], [2, 4, nil]]
    #   max_zip(a, b, c)
    #   => [[1, 3, 7], [2, 4, nil], [nil, 5, nil]]
    def self.max_len_zip(*arrays)
      max_array = arrays.inject([]) { |max, a| a.size > max.size ? a : max }
      max_array.zip(*arrays).tap { |a| a.each(&:shift) }
    end
  end
end
