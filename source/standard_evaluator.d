module standard_evaluator;

class StandardEvaluator : Evaluator{



    int opCall(const Card[] board, const Card[] hole_cards){

        Card[] full_hand = board ~ hole_cards;

        //containers of suit counts;
        int[4] suits;
        //container of rank counts;
        int[13] ranks;
        int max_count;
        int second_max_count;
        int straighter;
        bool can_flush = 0;
        int value = 0x000000;


        //build list of values;
        foreach(card; full_hand){
            straighter |= 1 << c.rank;
            suits[card.suit]++;
            ranks[card.rank]++;
        }    

        //check straight flush
        foreach (s; 0 .. 4) {
            if (suits[s] < 5) {
                continue;
            }
            can_flush = 1;
            uint bits = suitBits[s];

            for (int high = 14; high >= 5; high--) {
                uint mask = 0b11111 << (high - 4);
                if ((bits & mask) == mask){
                    return (0x700000 + highCard * 0x1000);
                }
            }

            // wheel
            if ((bits & (1 << 14)) && (bits & 0b111100) == 0b111100){
                return (0x700000 + 5* 0x1000);
            }
        }


        //check for 4 of a kind
        for(int i =14; i >= 2; i--){
            if(ranks[i] == 4){
                value = 0x600000 + i * 0x10000;
                int quad_rank = i;
                for (int j = 14; j >= 2; j--) {
                    if (j != quad_rank && ranks[j] > 0) {
                        return value + j*0x1000;
                        break;
                    }
                }
            }
            else if(ranks[i]>max_count){
                max_count = ranks[i];
                max_count_value =1;
            }
            else if(ranks[i]>second_max_count){
                second_max_count = ranks[i];
                second_max_count_value = 1;
            }
        }

        //check for full house
        if(max_count >= 3 && second_max_count >=2){
            return 0x600000 + 0x010000*max_count_value + 0x001000*second_max_count_value;
        }


        //check for flush

        if(can_flush){
            value += 0x500000;
            int count = 0;
            for (int i = 14; i >= 2 && count < 5; i--) {
                if (ranks[i] > 0 && suitHasFlush[i]) {
                    value += i * pow16(4 - count); 
                    count++;
                }
            }
        }


        //check for straight
        for (int high = 14; high >= 5; high--) {
            uint mask = 0b11111 << (high - 4);
            if ((bits & mask) == mask){
                return (0x400000 + highCard * 0x1000);
            }
        }

        // wheel
        if ((bits & (1 << 14)) && (bits & 0b111100) == 0b111100){
            return (0x400000 + 5* 0x1000);
        }

    
        //check for three of kind
        if(max_count >=3){
            value += (0x300000 + max_count_value* 0x10000);
            for (int i = 14; i >= 2 && count < 5; i--) {
                if (ranks[i] != 3 && ranks[i]!= 0) {
                    value += i * pow16(2 - count); 
                    count++;
                }
            }

        }
        
        //check for 2 pair
        if(max_count >=2 && second_max_count >=2){
            value +=(0x200000 + max_count_value * 0x10000 + second_max_count_value * 0x1000);
            for(int i =14; i>=2; i--){
                if(i != max_count_value && i != second_max_count_value){
                    return value += i *0x100;
                }
            }

        }
        

        // check for pair

        //return high card;




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



