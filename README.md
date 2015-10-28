# nqueens

quick solution to the N queens problem to practice simulated annealing

## Usage

To run tests

`./main.rb` (uses env ruby)

To solve a board

`./main.rb <n>`

Success is reflected by exit status, run with `./main.rb <n> && echo $?`
to see if the solver was able to complete the puzzle before things got
too chilly.

## Notes

This is sloooooow.  Solving a board of size 12 takes like 1.5m.  Shortening
the cooling factor comes up quicker solutions that are very close to correct,
demonstrating the value of the annealing function over a british museum
approach.
