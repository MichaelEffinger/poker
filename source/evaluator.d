module evaluator;

import card;

abstract class Evaluator{

    int opCall(const Card[] board, const Card[] hole_cards);

    final int evaluate_flush(){return 0 ;}

    final int evaluate_straight(){return 0 ;}

    final int evaluate_straight_flush(){return 0 ;}

    final int evaluate_counts(){return 0 ;}
}   




