module players.player;

import deck;
import evaluators.evaluator;
import hand_util;
import card;



abstract class Player
{
    string name;
    long stack;
    Card[] hole;

    bool all_in;
    bool folded;
    bool matched;
    long round_bets;


    bool opEquals(Player lhs)const {
        if(this.name == lhs.name || this.stack == lhs.stack){
            return true;
        }
        return false;
    }


    abstract long take_turn(Card[] board, long pot, long toCall, size_t players_in, Evaluator eval);

    void round_clear(){
        matched = false;
        round_bets = 0;
    }

    void full_clear(){
        folded = false;
        all_in = false;
        round_clear();
        hole.length =0;
    }

}