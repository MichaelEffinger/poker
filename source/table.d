module table;
import deck;
import player;
import card;

class Table{
    Player[] players;
    int max_players;
    int dealer_index;
    int current_turn;

    Deck deck;
    Deck equity_deck;
    Card[] board_cards;


    int pot;
    int minimum_bet;
    int small_blind;
    int big_blind;
    int[Player] round_bets;

   // Evaluator tableEvaluator;


    enum Round{PreFlop, Flop, Turn, River, Showdown}
    Round currentRound;



    int get_winner(){
        return 0;
    }

}


