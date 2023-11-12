# RSPx

# Mixed Strategy Nash Equilibrium

The Nash Equilibrium in game theory is a pair of strategies in which each player's strategy is a best response to the other player's strategy. In the game of Rock, Paper, Scissors, Spock, and Lizard (let us call it RPSx), the Nash Equilibrium can be found using mixed strategies. A Mixed Strategy Nash Equilibrium allows each player in a game to have a probability of choosing any of their available strategies. Each player's expected payoff from their strategies should be the same at the equilibrium. In contrast, in a pure strategy Nash equilibrium, each player has a fixed strategy, while in a mixed strategy Nash equilibrium, each player has a probability distribution over their strategies. 

In the case of RPSx, there are five possible moves, and the Nash Equilibrium is achieved when each player has an equal probability of choosing any of the five options. This means that the probability of choosing any of the five weapons (or moves) is 1/5 or 0.2 for each player. 

We will define the expected value for each player. Let p be the probability that player 1 picks one of the five weapons, that is, rock, paper, scissors, spock, or lizard, and, on the other hand, let q be the probability that player 2 picks one of the five weapons. The expected value for player 2 is:

Eu(q(rock)) =  0*p(rock) + (-1)*p(paper) + 1*p(scissors) + (-1)*p(spock) + 1*p(lizard)
Eu(q(paper)) =  1*p(rock) + 0*p(paper) + (-1)*p(scissors) + 1*p(spock) + (-1)*p(lizard)
Eu(q(scissors)) = (- 1)*p(rock) + 1*p(paper) + 0*p(scissors) + (-1)*p(spock) + 1*p(lizard)
Eu(q(spock)) = 1*p(rock) + (-1)*p(paper) + 1*p(scissors) + 0*p(spock) + (-1)*p(lizard)
Eu(q(lizard)) = (- 1)*p(rock) + 1*p(paper) + (-1)*p(scissors) + 1*p(spock) + 0*p(lizard)

Solving the system of equations, we eventually reach that the Nash Equilibrium for the game is:

For player 1, p(rock) = p(paper) = p(scissors) = p(Spock) = p(Lizard) = 1/5 
For player 2, q(rock) = q(paper) = q(scissors) = q(Spock) = q(Lizard) = 1/5

It's important to note that the Nash Equilibrium is not necessarily the best strategy in every situation. For example, in a single round of RPSx, it might be better to choose the most likely choice of the other player, rather than choosing randomly. However, in a series of games, the Nash Equilibrium of choosing randomly is often the best strategy.

