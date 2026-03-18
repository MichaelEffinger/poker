module variants.poker_variant;

import table;
import players.player;
import deck;
import card;
import evaluators.evaluator;

import std.stdio;

abstract class PokerVariant{

    enum Signal {
    CONTINUE=0,
    ROUND_END=1,
    SHOWDOWN=2,
    HAND_END=3, 
    FOLD_WIN=4,
    WAITING = -69
    }
    
    bool needs_setup = true;
    int advance(Player[] players, ref Deck deck, ref Card[] board, long pot, size_t current_round, ref size_t current_turn, Evaluator eval);

    long current_highest_bet(Player[] players) {
        long highest = 0;
        foreach(p; players)
            if(p !is null && p.round_bets > highest)
                highest = p.round_bets;
        return highest;
    }

    size_t active_count(Player[] players) {
        size_t count = 0;
        foreach(p; players)
            if(p !is null && !p.folded && !p.all_in)
                count++;
        return count;
    }


    long betting(Player[] players, Card[] board,long pot, size_t current_turn, Evaluator eval){
        Player in_action = players[current_turn];

        if(in_action is null || in_action.folded || in_action.all_in){
            return 0;
        }
        long highest = current_highest_bet(players);
        long toCall = highest- in_action.round_bets;   
        size_t active = active_count(players);

        long result = in_action.take_turn(board,pot,toCall,active,eval);

        if(result == -69){
            return result;
        }

        if(result == -1){
            in_action.folded = true;
        }
        else if(result > highest){
            foreach(i,other;players){
                if(other !is null && other !is in_action && !other.folded){
                    other.matched = false;
                }
            }
            in_action.stack -= result;
            in_action.round_bets += result;
            in_action.matched = true;
            if(in_action.stack <= 0) in_action.all_in = true;
        }
        else{
            in_action.stack -= result;
            in_action.round_bets += result;
            in_action.matched = true;
        }

        return 0;
    }



}