module evaluators.evaluator;

import card;
import deck;
import std.algorithm.comparison;

abstract class Evaluator{

    Deck deck;    

    int opCall(const Card[] board, const Card[] hole_cards);


    int evaluate_straight_flush(int hand_rank, int suit_count, int min_rank, int max_rank, uint rankBits, uint[] suitCounts, uint[] suitBits) const {
        foreach (s; 0 .. suit_count) {
            if (suitCounts[s] >= 5) {
                uint bits = suitBits[s];

                for (int high = max_rank; high >= min_rank+3; high--) {
                    uint mask = 0b11111u << (high - 4);
                    if ((bits & mask) == mask){
                        return (0x100000* hand_rank) + (high << 12);
                    }
                }
                uint bottomFourMask = 0b1111u << min_rank;
                uint aceBit = 1u << max_rank;

                if ((rankBits & aceBit) && (rankBits & bottomFourMask) == bottomFourMask){
                    int wheelHigh = min_rank + 3;
                    return (hand_rank << 20) + (wheelHigh << 12);
                }
            }
        }
        return 0;
    }


    
    int evaluate_flush(int hand_rank,int suit_count, int min_rank, int max_rank, uint[] suitCounts, uint[] suitBits)const{
        foreach (s; 0 .. suit_count) {
            if (suitCounts[s] >= 5) {
                int value = 0x100000 * hand_rank;
                int count = 0;

                for (int i = max_rank; i >= min_rank && count < 5; i--) {
                    if (suitBits[s] & (1 << i)) {
                        value |= i << (16 - count * 4);
                        count++;
                    }
                }
                return value;
            }
        }
        return 0;
    }

    void find_multiples(int lowest, int highest, const uint[] rankCounts, ref int quad, ref int trip1, ref int trip2, ref int pair1, ref int pair2)const{
        for (int i = highest; i >= lowest; i--) {
            const c = rankCounts[i];
            if (c == 4){
                quad = i;
            }
            else if (c == 3) {
                if (trip1 ==0){
                    trip1 = i;
                }
                else if(trip2==0) {
                    trip2 = i;
                }
            }
            else if (c == 2) {
                if (pair1 == 0){
                    pair1 = i;
                }
                else if(pair2 == 0) {
                    pair2 = i;
                }
            }
        }
    }

    int evaluate_quads(int hand_rank, int min_rank, int max_rank, int quad, uint[] rankCounts)const{
        if(quad){
            for(int i =max_rank; i>=min_rank; i--){
                if( i != quad && rankCounts[i] > 0){
                    return (0x100000*hand_rank) + (quad << 16) + (i << 12);
                }
            }
        }
        return 0;
    }


    int evaluate_full_house(int hand_rank, int trip1, int trip2, int pair1)const{
        if(trip1 && (trip2 || pair1)){
            int pairRank = max(trip2, pair1);
            return (0x100000 * hand_rank) + (trip1 << 16) + (pairRank << 12);
        }

        return 0;
    }

    int evaluate_straight(int hand_rank, int min_rank, int max_rank, uint rankBits)const{
        for (int high = max_rank; high >= min_rank + 4; high--) {
            uint mask = 0b11111u << (high - 4);
            
            if ((rankBits & mask) == mask) {
                return (hand_rank * 0x100000) + (high << 12);
            }
        }
        uint bottomFourMask = 0b1111u << min_rank;
        uint aceBit = 1u << max_rank;

        if ((rankBits & aceBit) && (rankBits & bottomFourMask) == bottomFourMask){
            int wheelHigh = min_rank + 3;
            return (hand_rank << 20) + (wheelHigh << 12);
        }
        return 0;
    }


    int evaluate_trips(int hand_rank, const int min_rank, const int max_rank, const int trip1, uint[] rankCounts)const{
        if (trip1) {
            int value = (0x100000*hand_rank) + (trip1 << 16);
            int count = 0;

            for (int i = max_rank; i >= min_rank && count < 2; i--) {
                if (i != trip1 && rankCounts[i] > 0) {
                    value |= i << (12 - count * 4);
                    count++;
                }
            }
            return value;
        }
        return 0;
    }


    int evaluate_two_pair(int hand_rank, int min_rank, int max_rank, int pair1, int pair2, uint[] rankCounts)const{
        if (pair1 && pair2) {
            int value = (0x100000 * hand_rank) + (pair1 << 16) + (pair2 << 12);
            for (int i = max_rank; i >= min_rank; i--) {
                if (i != pair1 && i != pair2 && rankCounts[i] > 0){
                    return value + (i << 8);
                }
            }
        }
        return 0;
    }

    int evaluate_pair(int hand_rank, int min_rank, int max_rank, int pair1, uint[] rankCounts)const{
        if (pair1) {
            int value = (0x100000*hand_rank) + (pair1 << 16);
            int count = 0;

            for (int i = max_rank; i >= min_rank && count < 3; i--) {
                if (i != pair1 && rankCounts[i] > 0) {
                    value |= i << (12 - count * 4);
                    count++;
                }
            }
            return value;
        }
        return 0;
    }

    int evaluate_high_card(int hand_rank, int min_rank, int max_rank, uint[] ronkCounts)const{
    
        int value = (0x100000 * hand_rank);
        int count = 0;
        for (int i = max_rank; i >= min_rank && count < 5; i--) {
            if (ronkCounts[i] > 0) {
                value |= i << (16 - count * 4);
                count++;
            }
        }
        return value;
    }
}




/*

    final int evaluate_straight(){return 0 ;}

    final int evaluate_straight_flush(){return 0 ;}

    final int evaluate_counts(){return 0 ;}
*/




