module players.human_player;

import players.player;
import deck;
import evaluators.evaluator;
import card;
import std.stdio;


class HumanPlayer : Player{





    this(string player_name, long chip_count){
        stack = chip_count;
        name = player_name;
    }
    enum WAITING_FOR_INPUT = -69;
    private bool decision_ready = false;

    private long decision_value = 0;

    private bool turn_active = false;

    override long take_turn(Card[] board, long pot, long toCall,size_t players_in, Evaluator eval){
        writeln("take_turn called, turn_active: ", turn_active, " decision_ready: ", decision_ready);
        if (!turn_active){
            turn_active = true;
            decision_ready = false;
        }

        if (!decision_ready){
            return WAITING_FOR_INPUT;
        }
        turn_active = false;
        decision_ready = false;

        return decision_value;
    }

    void submit_decision(long value){
         writeln("submit_decision called with: ", value);
        decision_value = value;
        decision_ready = true;
    }

    bool is_waiting(){
        return !decision_ready;
    }



}