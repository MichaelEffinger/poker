module table;
import card;
import deck;
import pot;
import evaluators.evaluator;
import players.player;
import variants.poker_variant;
import payouts.payout_structure;

class Table{
    Player[] players; 
    Card[] board_cards;
    Pot[] pots;
    size_t dealer_index;
    size_t current_turn;
    size_t current_round;

    //interchangable game modules;
    Deck deck;
    Evaluator evaluator;
    PokerVariant variant;
    PayoutStructure payouts;


    long pot_total(){
        long accumulator = 0;
        foreach(pot; pots){
            accumulator += pot.amount;
        }
        // also count bets not yet swept into a pot
        foreach(p; players){
            if(p !is null){
                accumulator += p.round_bets;
            }
        }
        return accumulator;
    }

    //Alimony, Nit   // change payout
    //lowball // changes evaluator
    //tarot card // changes deck
    //omaha, irish // 5 card draw, continue


    this(Deck game_deck, Evaluator game_evaluator, PokerVariant game_variant, PayoutStructure game_payout){
        deck = game_deck;
        evaluator = game_evaluator;
        variant = game_variant;
        payouts = game_payout;

    }

    void find_and_set_winners(){
        for(size_t i = 0; i < pots.length; i++){
            long top_score = 0;
            pots[i].winners.length = 0;

            for(size_t j = 0; j < pots[i].eligible.length; j++){
                long new_score = evaluator(board_cards, pots[i].eligible[j].hole);

                if(new_score > top_score){
                    pots[i].winners.length = 0;
                    pots[i].winners ~= pots[i].eligible[j];
                    top_score = new_score;
                }
                else if(new_score == top_score){
                    pots[i].winners ~= pots[i].eligible[j];
                }
            }
        }
    }

    size_t next_turn(size_t start){
        if (players.length == 0){
            return 0;
        }
        while (true){
            current_turn = (current_turn + 1) % players.length;
            if (current_turn == start){
                break;
            }
            if (players[current_turn] !is null && !players[current_turn].folded && !players[current_turn].all_in){
                return current_turn;
            }
        }
      return start;
    }

    int update(){
        if(players.length <=0){
            return -1; 
        }

        int signal = variant.advance(players, deck, board_cards, pot_total(), current_round,current_turn, evaluator);

        switch(signal){
            case variant.Signal.WAITING:
                break;
            case variant.Signal.CONTINUE:
                current_turn = next_turn(current_turn);
                break;
            case variant.Signal.ROUND_END:
                current_round++;
                create_pots();
                round_clear();
                current_turn = next_turn(dealer_index);
                break;
            case variant.Signal.SHOWDOWN:
                create_pots();
                find_and_set_winners();
                payouts.distribute(pots);
                current_round++;
                break;
            case variant.Signal.HAND_END:
                hand_end();
                clean_bankrupt();
                current_round=0;
                break;
            case variant.Signal.FOLD_WIN:
                create_pots();
                find_fold_winner();
                payouts.distribute(pots);
                hand_end();
                clean_bankrupt();
                break;
            default:
                break;
        }

        return 0;

    }


    void create_pots(){
        bool[] contributers;
        int contributer_count = 0;

        for(size_t i = 0; i < players.length; i++){
            if(players[i] !is null && players[i].round_bets > 0){
                contributers ~= true;
                contributer_count++; 
            }
            else{
                contributers ~= false;
            }
        }

        while(contributer_count > 0){
            Pot newPot;
            long lowest = find_current_lowest_bet(contributers);

            if(lowest == long.max){
                break;
            }

            foreach(i, cont; contributers){
                if(cont && players[i] !is null && !players[i].folded){ 
                    newPot.eligible ~= players[i];
                }
            }

            newPot.amount = 0;

            for(size_t i = 0; i < players.length; i++){
                if(players[i] is null || players[i].round_bets == 0) continue;

                if(players[i].round_bets <= lowest){
                    newPot.amount += players[i].round_bets;
                    players[i].round_bets = 0;
                    contributer_count--;
                    contributers[i] = false;
                }
                else{
                    newPot.amount += lowest;
                    players[i].round_bets -= lowest; 
                }
            }
            this.pots ~= newPot; 
        }
    }

    long find_current_lowest_bet(bool[] contributers){
        long current_lowest = long.max;

        foreach(i; 0 .. players.length){
            if (!contributers[i] || players[i].round_bets == 0) {
                continue;
            }

            if (players[i].round_bets < current_lowest ){
                current_lowest = players[i].round_bets;
            }
        }

        return current_lowest;
    }


    void hand_end() {
        board_cards.length = 0;
        pots.length = 0;
        current_round = 0;
        deck.shuffle_deck();
        foreach(player; players){
            if(player !is null){
                player.full_clear();
            }
        }
    }

    void round_clear() {
        foreach(player; players){
            if(player !is null){
                player.round_clear();
            }
        }
        variant.needs_setup = true;
    }

    void clean_bankrupt(){
        for(size_t i = 0; i < players.length; i++){
            if(players[i] is null){
                continue;
            }
            if(players[i].stack <= 0){
                players[i] = null;
            }
        }
    }

    void find_fold_winner() {
        Player winner;
        foreach(p; players) {
            if(p !is null && !p.folded) {
                winner = p;
                break;
            }
        }
        foreach(ref pot; pots) {
            pot.winners.length = 0;
            pot.winners ~= winner;
        }
    }


}