module standard_evaluator;
import card;
import evaluator;

class StandardEvaluator : Evaluator{

  override int opCall(const Card[] board, const Card[] hole_cards) {

    const(Card)[] full = board ~ hole_cards;
    int[15] rankCounts;
    int[4] suitCounts;
    uint rankBits = 0;
    uint[4] suitBits;

    foreach (card; full) {
        rankCounts[card.rank]++;
        suitCounts[card.suit]++;
        rankBits |= 1u << card.rank;
        suitBits[card.suit] |= 1u << card.rank;
    }

    // Straight flush
    foreach (s; 0 .. 4) {
        if (suitCounts[s] >= 5) {
            uint bits = suitBits[s];

            for (int high = 14; high >= 5; high--) {
                uint mask = 0b11111u << (high - 4);
                if ((bits & mask) == mask)
                    return 0x800000 + (high << 12);
            }

            // wheel
            if ((bits & (1 << 14)) &&(bits & 0b11110) == 0b11110){
                return 0x800000 + (5 << 12);
            }
        }
    }

    // evaluate types of pairs
    int quad = 0;
    int trip1 = 0;
    int trip2 = 0;
    int pair1 = 0;
    int pair2 = 0;

    for (int i = 14; i >= 2; i--) {
        const c = rankCounts[i];
        if (c == 4) quad = i;
        else if (c == 3) {
            if (!trip1) trip1 = i;
            else trip2 = i;
        }
        else if (c == 2) {
            if (!pair1) pair1 = i;
            else pair2 = i;
        }
    }

    // quads
    if (quad) {
        for (int i = 14; i >= 2; i--)
            if (i != quad && rankCounts[i] > 0)
                return 0x700000 + (quad << 16) + (i << 12);
    }

    // full houe!! my favorite hand
    if (trip1 && (trip2 || pair1)) {
        int pairRank = trip2 ? trip2 : pair1;
        return 0x600000 + (trip1 << 16) + (pairRank << 12);
    }

    // flush
    foreach (s; 0 .. 4) {
        if (suitCounts[s] >= 5) {
            int value = 0x500000;
            int count = 0;

            for (int i = 14; i >= 2 && count < 5; i--) {
                if (suitBits[s] & (1 << i)) {
                    value |= i << (12 - count * 4);
                    count++;
                }
            }
            return value;
        }
    }

    //straight
    for (int high = 14; high >= 5; high--) {
        uint mask = 0b11111u << (high - 4);
        if ((rankBits & mask) == mask)
            return 0x400000 + (high << 12);
    }

    // wheel
    if ((rankBits & (1 << 14)) && (rankBits & 0b11110) == 0b11110){
        return 0x400000 + (5 << 12);
    }


    // sets and trips
    if (trip1) {
        int value = 0x300000 + (trip1 << 16);
        int count = 0;

        for (int i = 14; i >= 2 && count < 2; i--) {
            if (i != trip1 && rankCounts[i] > 0) {
                value |= i << (12 - count * 4);
                count++;
            }
        }
        return value;
    }

    //two pair
    if (pair1 && pair2) {
        int value = 0x200000 + (pair1 << 16) + (pair2 << 12);
        for (int i = 14; i >= 2; i--) {
            if (i != pair1 && i != pair2 && rankCounts[i] > 0){
                return value + (i << 8);
            }
        }
    }

    //pair
    if (pair1) {
        int value = 0x100000 + (pair1 << 16);
        int count = 0;

        for (int i = 14; i >= 2 && count < 3; i--) {
            if (i != pair1 && rankCounts[i] > 0) {
                value |= i << (12 - count * 4);
                count++;
            }
        }
        return value;
    }

    //bummer, you got nothin
    int value = 0;
    int count = 0;

    for (int i = 14; i >= 2 && count < 5; i--) {
        if (rankCounts[i] > 0) {
            value |= i << (16 - count * 4);
            count++;
        }
    }

    return value;
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

