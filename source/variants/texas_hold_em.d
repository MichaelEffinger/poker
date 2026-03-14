module variants.texas_hold_em;

import variants.poker_variant;
import table;
import card;
import deck;
import players.player;
import evaluators.evaluator;



class TexasHoldEm : PokerVariant{


    int max_hsize_tand_until_blind_up;
    int hands_until_blind_up;
    long current_blind;


    void deal_cards(Player[] players, Deck deck){
        deck.burn_card();
        for(int i = 0; i < 2; i++){
            for(size_t j = 0; j < players.length; j++){
                if(players[j] !is null){
                    players[j].hole ~= deck.draw_card();
                }
            }
        }
    }

    void deal_flop(ref Card[] board, Deck deck){
        deck.burn_card();
        board ~= deck.draw_card();
        board ~= deck.draw_card();
        board ~= deck.draw_card();
    }

    void deal_turn(ref Card[] board, Deck deck){
        deck.burn_card();
        board ~= deck.draw_card();
    }

    void deal_river(ref Card[] board, Deck deck){
        deck.burn_card();
        board ~= deck.draw_card();
    }

    void post_blinds(Player[] players, ref size_t current_turn) {
        size_t sb, bb;
        size_t active = active_count(players);

        if(active == 2) {
            sb = current_turn;
            bb = next_turn_for_blinds(players, current_turn, current_turn);
        } 
        else {
            sb = next_turn_for_blinds(players, current_turn, current_turn);
            bb = next_turn_for_blinds(players, sb, current_turn);
        }

        players[sb].stack -= current_blind;
        players[sb].round_bets += current_blind;

        players[bb].stack -= current_blind * 2;
        players[bb].round_bets += current_blind * 2;

        current_turn = next_turn_for_blinds(players, bb, current_turn);
    }

    bool betting_complete(Player[] players) {
        foreach(p; players) {
            if(p is null || p.folded || p.all_in) {
                continue;
            }
            if(!p.matched){ 
                return false;
            }
        }
        return true;
    }

    override int advance(Player[] players, Deck deck, ref Card[] board, long pot, size_t current_round, ref size_t current_turn, Evaluator eval){

        switch(current_round){
            case 0:
                if(needs_setup){
                    post_blinds(players, current_turn);
                    deal_cards(players,deck);
                    needs_setup = false;
                }
                if(betting_complete(players)) {
                    needs_setup = true;
                    return Signal.ROUND_END;
                }
                long result_signal = betting(players, board, pot, current_turn, eval);
                if(result_signal == Signal.WAITING) return Signal.WAITING;
                return Signal.CONTINUE;

            break;
            case 1:
                if(needs_setup){
                    deal_flop(board, deck);
                    needs_setup = false;
                }
                if(betting_complete(players)) {
                    needs_setup = true;
                    return Signal.ROUND_END;
                }
                long result_signal = betting(players, board, pot, current_turn, eval);
                if(result_signal == Signal.WAITING) return Signal.WAITING;
                return Signal.CONTINUE;

            break;
            case 2:
                if(needs_setup){
                    deal_turn(board, deck);
                    needs_setup = false;
                }
                if(betting_complete(players)) {
                    needs_setup = true;
                    return Signal.ROUND_END;
                }
                long result_signal = betting(players, board, pot, current_turn, eval);
                if(result_signal == Signal.WAITING) return Signal.WAITING;
                return Signal.CONTINUE;
            break;
            case 3:
                if(needs_setup){
                    deal_river(board, deck);
                    needs_setup = false;
                }
                if(betting_complete(players)) {
                    needs_setup = true;
                    return Signal.SHOWDOWN;
                }
                long result_signal = betting(players, board, pot, current_turn, eval);
                if(result_signal == Signal.WAITING) return Signal.WAITING;
                return Signal.CONTINUE;
            break;
            default:
                return Signal.HAND_END;
            break;
        }

    }


    size_t next_turn_for_blinds(Player[] players, size_t current_turn, size_t start){
        if (players.length == 0){
            return 0;
        }
        while (true){
            current_turn = (current_turn + 1) % players.length;
            if (current_turn == start){
                break;
            }
            if (players[current_turn] !is null){
                return current_turn;
            }
        }
      return start;
    }

}
