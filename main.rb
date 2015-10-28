#!/usr/bin/env ruby

require 'set'
require 'forwardable'
require 'minitest'

# Position on board
class Pos
  attr_reader :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end

  def eql?(other)
    x == other.x and y == other.y
  end

  def hash
    [x, y].hash
  end

  def can_attack?(other)
    return false if self.eql?(other)
    on_row_with?(other) or on_col_with?(other) or diagonal_to?(other)
  end

  private

  def on_row_with?(other)
    other.y == y
  end

  def on_col_with?(other)
    other.x == x
  end

  def diagonal_to?(other)
    (other.x - x).abs == (other.y - y).abs
  end
end

class Board
  extend Forwardable

  attr_reader :size

  def initialize(size)
    @size = size
    @moves = Set.new
  end

  def_delegator :@moves, :include?, :include?

  def add(pos)
    return false if moves.include?(pos)
    @moves << pos
  end

  # Is the configuration of pieces correct according to the rules
  def correct?
    jeporadized_pieces.empty?
  end

  def n_moves
    moves.length
  end

  def n_jeporadized
    jeporadized_pieces.length
  end

  def move_piece(piece, dest)
    return false if moves.include?(dest)
    moves.delete(piece)
    moves.add(dest)
  end

  def clone
    Board.new(size).tap do |new_board|
      new_board.instance_variable_set(:@moves, moves.clone)
    end
  end

  # @note Only really works on board.size < 10
  def to_s
    str = '  ' + size.downto(1).map(&:to_s).join + "\n"
    1.upto(size).reduce(str) do |str, y|
      str + "#{y} " +
        size.downto(1).reduce('') do |row_str, x|
          row_str + (moves.include?(Pos.new(x, y)) ? 'Q' : '+')
        end +
        "\n"
    end
  end

  def jeporadized_pieces
    moves.select do |move|
      moves.any? { |other| other.can_attack?(move) }
    end
  end

  private

  attr_reader :moves
end

class Solver
  attr_reader :board, :iter

  def initialize(size)
    @board = Board.new(size)
    @iter = 1
    populate
  end

  def solve
    until board.correct?
      return false if temp == 0
      new_board = altered_board
      @board = new_board if accept_board?(new_board)
      @iter += 1
    end
  end

  private

  # A new board with a random move applied
  def altered_board
    board.clone.tap do |new_board|
      piece = board.jeporadized_pieces.first
      new_move = move_dest(piece)
      new_board.move_piece(piece, new_move)
    end
  end

  # A random destination in the same col as the piece
  def move_dest(piece)
    pos = piece
    pos = Pos.new(piece.x, rand(board.size)) until pos != piece

    pos
  end

  def random_pos
    Pos.new(*2.times.map { rand(board.size) + 1 })
  end

  def temp
    (10**board.size) / iter
  end

  def accept_board?(new_board)
    energy_delta = new_board.n_jeporadized - board.n_jeporadized

    return true if energy_delta < 0

    prob = Math.exp(-energy_delta / temp)

    if rand < prob
      return true
    else
      return false
    end
  end

  def score
    board.n_jeporadized
  end

  def populate
    1.upto(board.size).each do |x|
      board.add(Pos.new(x, rand(board.size)))
    end
  end
end

class TestPos < Minitest::Test
  def test_can_attack?
    # Diags
    assert Pos.new(1, 1).can_attack?(Pos.new(2, 2))
    assert Pos.new(1, 2).can_attack?(Pos.new(2, 3))
    assert Pos.new(5, 5).can_attack?(Pos.new(4, 4))
    assert Pos.new(3, 2).can_attack?(Pos.new(2, 1))
    assert Pos.new(101, 102).can_attack?(Pos.new(102, 103))

    # Verts
    assert Pos.new(1, 1).can_attack?(Pos.new(5, 1))

    # Horiz
    assert Pos.new(1, 1).can_attack?(Pos.new(1, 5))
  end
end

class TestBoard < Minitest::Test
  attr_reader :board

  def setup
    @board = Board.new(10)
  end

  def test_add_piece
    move = Pos.new(1, 1)
    board.add(move)
    assert board.include?(move)
  end

  def test_correct
    refute board_with_moves([1, 1], [2, 2]).correct?
    refute board_with_moves([4, 1], [4, 2], [6, 8]).correct?
    assert board_with_moves([4, 1], [6, 2]).correct?
  end

  def test_n_jeporadized
    assert_equal 3,
                 board_with_moves([1, 1], [2, 1], [3, 1]).n_jeporadized
  end

  def test_clone
    a = board_with_moves([1, 1])
    b = a.clone.tap { |b| b.add(Pos.new(1, 2)) }

    assert a.correct?
    refute b.correct?
  end

  private

  def board_with_moves(*moves, size: 10)
    Board.new(size).tap do |board|
      moves.each { |m| board.add(Pos.new(m[0], m[1])) }
    end
  end
end

class TestSolver < Minitest::Test
  def test_populate
    solver = Solver.new(10)
    assert_equal 10, solver.board.n_moves
  end

  def test_solve
    solver = Solver.new(5).tap(&:solve)
    assert solver.board.correct?
  end
end

if $PROGRAM_NAME == __FILE__
  if !ARGV.first.nil?
    board = Solver.new(ARGV.first.to_i).tap(&:solve).board
    exit board.correct? ? 0 : 1
  else
    require 'minitest/autorun'
  end
end
