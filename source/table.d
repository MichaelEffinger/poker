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
    Card[5] board_cards;


    int pot;
    int minimum_bet;
    int small_blind;
    int big_blind;
    int[Player] round_bets;

    Evaluator tableEvaluator;


    enum Round{PreFlop, Flop, Turn, River, Showdown}
    Round currentRound;

    int evaluate_hand(Card[2] h, Card[5]* board){

		int[] rank_count;
		rank_count.length = deck.rank_count;
		int[] suit_count;
        suit_count.length = deck.suit_names.length;

        return 0;
	}



    int get_winner(){
        return 0;
    }

}


