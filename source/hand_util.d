module hand_util;

import std.algorithm;
import std.array : array;
import card;

size_t[] determine_winners(const long[] values, const bool[] active){
    assert(values.length == active.length, "values and active must be same length");

    size_t[] winners;
    long bestValue;

    bool first = true;

    foreach (i, v; values){
        if (!active[i]){
            continue;
        }
        if (first){
            bestValue = v;
            winners = [i];
            first = false;
        }
        else if (v > bestValue){
            bestValue = v;
            winners.length = 0;
            winners ~= i;
        }
        else if (v == bestValue){
            winners ~= i;
        }
    }
    return winners;
}

size_t[] determine_winners(const long[] values){
    size_t[] winners;
    long bestValue;

    bool first = true;

    foreach (i, v; values){
        if (first){
            bestValue = v;
            winners = [i];
            first = false;
        }
        else if (v > bestValue){
            bestValue = v;
            winners.length = 0;
            winners ~= i;
        }
        else if (v == bestValue){
            winners ~= i;
        }
    }
    return winners;
}


bool has_flush_draw(Card[] hole, Card[] board) {
    Card[] allCards = hole ~ board;
    if (allCards.length < 4) return false;

    int[4] suitCounts;
    foreach (card; allCards) {
        suitCounts[card.suit]++;
    }

    foreach (count; suitCounts) {
        if (count == 4) return true; 
    }
    return false;
}

bool has_straight_draw(Card[] hole, Card[] board) {
    Card[] allCards = hole ~ board;
    if (allCards.length < 4) return false;

    int[] ranks;
    foreach (c; allCards) ranks ~= cast(int)c.rank;
    
    if (canFind(ranks, 14)) ranks ~= 1; 
    
    auto uniqueRanks = ranks.sort().uniq().array();
    if (uniqueRanks.length < 4) return false;

    for (size_t i = 0; i <= uniqueRanks.length - 4; i++) {
        int span = uniqueRanks[i + 3] - uniqueRanks[i];
        
        if (span == 3) return true;
        
        if (span == 4) return true;
    }

    return false;
}