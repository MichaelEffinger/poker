module evaluators.standard_evaluator;
import card;
import evaluators.evaluator;
import deck;

class StandardEvaluator : Evaluator{

    int highest_rank;
    int lowest_rank;
    int suit_amount;

    private uint[] rankCounts;
    private uint[] suitCounts;
    private uint[] suitBits;

    this(int min_card, int max_card, int suit_count){
        lowest_rank = min_card;
        highest_rank = max_card;
        suit_amount = suit_count;

        this.rankCounts = new uint[highest_rank + 1];
        this.suitCounts = new uint[suit_amount];
        this.suitBits = new uint[suit_amount];
    }


    this(int min_card, int max_card, int suit_count, Deck deck_){
        lowest_rank = min_card;
        highest_rank = max_card;
        suit_amount = suit_count;
        deck = deck_;

        this.rankCounts = new uint[highest_rank + 1];
        this.suitCounts = new uint[suit_amount];
        this.suitBits = new uint[suit_amount];
    }

    override int opCall(const Card[] board, const Card[] hole_cards){
        const(Card)[] full = board ~ hole_cards;
        rankCounts[] = 0;
        suitCounts[] = 0;
        uint rankBits = 0;
        suitBits[] = 0;

        foreach (card; full) {
            rankCounts[card.rank]++;
            suitCounts[card.suit]++;
            rankBits |= 1u << card.rank;
            suitBits[card.suit] |= 1u << card.rank;
        }


        int check_straight_flush = evaluate_straight_flush(8,suit_amount,lowest_rank,highest_rank,rankBits,suitCounts,suitBits);
        if(check_straight_flush){
            return check_straight_flush;
        }

        // evaluate types of pairs
        int quad = 0;
        int trip1 = 0;
        int trip2 = 0;
        int pair1 = 0;
        int pair2 = 0;
        find_multiples(lowest_rank,highest_rank, rankCounts, quad, trip1, trip2, pair1, pair2);

        int check_quads = evaluate_quads(7,lowest_rank,highest_rank,quad,rankCounts);
        if(check_quads){
            return check_quads;
        }

        int check_house = evaluate_full_house(6,trip1,trip2,pair1);
        if(check_house){
            return check_house;
        }

        int check_flush = evaluate_flush(5,4,lowest_rank, highest_rank, suitCounts, suitBits);
        if(check_flush){
            return check_flush;
        }

        int check_straight = evaluate_straight(4,lowest_rank,highest_rank,rankBits);
        if(check_straight){
            return check_straight;
        }

        int check_trips = evaluate_trips(3,lowest_rank,highest_rank,trip1, rankCounts);
        if(check_trips){
            return check_trips;
        }

        int check_two_pairs = evaluate_two_pair(2,lowest_rank,highest_rank,pair1,pair2, rankCounts);
        if(check_two_pairs){
            return check_two_pairs;
        }


        //pair

        int check_pair = evaluate_pair(1,lowest_rank,highest_rank, pair1, rankCounts);
        if(check_pair){
            return check_pair;
        }

        //bummer, you got nothin
        return evaluate_high_card(0,lowest_rank,highest_rank,rankCounts);

    }


    string[] handTypes = [
    "Straight Flush",
    "Quads",
    "Full House",
    "Flush",
    "Straight",
    "Trips",
    "Two Pair",
    "Pair",
    "High Card"
    ];




}

