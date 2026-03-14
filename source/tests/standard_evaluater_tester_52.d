module tests.standard_evaluater_tester_52;
import std.stdio;
import card;
import evaluators.standard_evaluator;

// suits
enum S = 0; // spades
enum H = 1; // hearts
enum D = 2; // diamonds
enum C = 3; // clubs

Card c(int suit, int rank) { return Card(suit, rank); }

// FIX 1: declare eval at module scope so score() and main() can both access it
StandardEvaluator eval;

int score(Card[] board, Card[] hole) {
    return eval(board, hole);
}

// hand rank extracted from score
int hand_rank(int score) {
    if (score >= 0x800000) return 8; // straight flush
    if (score >= 0x700000) return 7; // quads
    if (score >= 0x600000) return 6; // full house
    if (score >= 0x500000) return 5; // flush
    if (score >= 0x400000) return 4; // straight
    if (score >= 0x300000) return 3; // trips
    if (score >= 0x200000) return 2; // two pair
    if (score >= 0x100000) return 1; // pair
    return 0;                         // high card
}

string[] rank_names = [
    "High Card", "Pair", "Two Pair", "Trips",
    "Straight", "Flush", "Full House", "Quads", "Straight Flush"
];

int passed = 0;
int failed = 0;

void test(string name, Card[] board, Card[] hole, int expected_rank) {
    int s = score(board, hole);
    int got = hand_rank(s);
    if (got == expected_rank) {
        writefln("  PASS: %s", name);
        passed++;
    } else {
        writefln("  FAIL: %s  expected=%s got=%s (score=0x%x)",
            name, rank_names[expected_rank], rank_names[got], s);
        failed++;
    }
}

// test that hand A scores higher than hand B
void test_beats(string name, Card[] board_a, Card[] hole_a, Card[] board_b, Card[] hole_b) {
    int sa = score(board_a, hole_a);
    int sb = score(board_b, hole_b);
    if (sa > sb) {
        writefln("  PASS: %s", name);
        passed++;
    } else {
        writefln("  FAIL: %s  scoreA=0x%x scoreB=0x%x (A should beat B)", name, sa, sb);
        failed++;
    }
}

void test_equal(string name, Card[] board_a, Card[] hole_a, Card[] board_b, Card[] hole_b) {
    int sa = score(board_a, hole_a);
    int sb = score(board_b, hole_b);
    if (sa == sb) {
        writefln("  PASS: %s", name);
        passed++;
    } else {
        writefln("  FAIL: %s  scoreA=0x%x scoreB=0x%x (should be equal)", name, sa, sb);
        failed++;
    }
}

void standard_evaluator_test_52() {
    // FIX 2: removed redundant static this() block; eval is initialized once here
    eval = new StandardEvaluator(2, 14, 4);

    // -----------------------------------------------------------------------
    writeln("\n=== HAND TYPE DETECTION ===");
    // -----------------------------------------------------------------------

    // straight flush
    test("Royal flush (A-K-Q-J-T spades)",
        [c(S,14),c(S,13),c(S,12),c(S,11),c(S,10)], [], 8);

    test("Straight flush 9-high",
        [c(H,9),c(H,8),c(H,7),c(H,6),c(H,5)], [], 8);

    test("Wheel straight flush A-2-3-4-5",
        [c(D,14),c(D,2),c(D,3),c(D,4),c(D,5)], [], 8);

    test("Straight flush with extra cards",
        [c(S,9),c(S,8),c(S,7),c(S,6),c(S,5),c(H,2),c(D,3)], [], 8);

    // quads
    test("Four aces",
        [c(S,14),c(H,14),c(D,14),c(C,14),c(S,2)], [], 7);

    test("Four 2s",
        [c(S,2),c(H,2),c(D,2),c(C,2),c(S,14)], [], 7);

    test("Four kings with extra cards",
        [c(S,13),c(H,13),c(D,13),c(C,13),c(S,2),c(H,3),c(D,4)], [], 7);

    // full house
    test("Aces full of kings",
        [c(S,14),c(H,14),c(D,14),c(C,13),c(S,13)], [], 6);

    test("Twos full of threes",
        [c(S,2),c(H,2),c(D,2),c(C,3),c(S,3)], [], 6);

    test("Full house with 7 cards",
        [c(S,10),c(H,10),c(D,10),c(C,9),c(S,9),c(H,2),c(D,3)], [], 6);

    // two trips = full house (best trip + best pair)
    test("Two trips becomes full house",
        [c(S,10),c(H,10),c(D,10),c(C,9),c(S,9),c(H,9),c(D,2)], [], 6);

    // flush
    test("Ace-high flush spades",
        [c(S,14),c(S,10),c(S,7),c(S,4),c(S,2)], [], 5);

    test("Flush with 6 suited cards picks best 5",
        [c(H,14),c(H,12),c(H,10),c(H,8),c(H,6),c(H,4),c(D,2)], [], 5);

    test("Flush not triggered with 4 suited",
        [c(S,14),c(S,10),c(S,7),c(S,4),c(H,2)], [], 0); // high card

    // straight
    test("Broadway straight A-K-Q-J-T",
        [c(S,14),c(H,13),c(D,12),c(C,11),c(S,10)], [], 4);

    test("Wheel straight A-2-3-4-5",
        [c(S,14),c(H,2),c(D,3),c(C,4),c(S,5)], [], 4);

    test("Mid straight 8-high",
        [c(S,8),c(H,7),c(D,6),c(C,5),c(S,4)], [], 4);

    test("Straight with extra cards",
        [c(S,9),c(H,8),c(D,7),c(C,6),c(S,5),c(H,2),c(D,14)], [], 4);

    test("Almost straight (one gap) is not straight",
        [c(S,9),c(H,8),c(D,6),c(C,5),c(S,4)], [], 0);

    // trips
    test("Three aces",
        [c(S,14),c(H,14),c(D,14),c(C,2),c(S,3)], [], 3);

    test("Three 2s",
        [c(S,2),c(H,2),c(D,2),c(C,14),c(S,13)], [], 3);

    // two pair
    test("Aces and kings",
        [c(S,14),c(H,14),c(D,13),c(C,13),c(S,2)], [], 2);

    test("Twos and threes",
        [c(S,2),c(H,2),c(D,3),c(C,3),c(S,14)], [], 2);

    test("Two pair with 7 cards picks best two pair",
        [c(S,14),c(H,14),c(D,13),c(C,13),c(S,12),c(H,12),c(D,2)], [], 2);

    // pair
    test("Pair of aces",
        [c(S,14),c(H,14),c(D,2),c(C,3),c(S,4)], [], 1);

    test("Pair of 2s",
        [c(S,2),c(H,2),c(D,14),c(C,13),c(S,12)], [], 1);

    // high card
    test("Ace high",
        [c(S,14),c(H,10),c(D,7),c(C,4),c(S,2)], [], 0);

    test("King high",
        [c(S,13),c(H,10),c(D,7),c(C,4),c(S,2)], [], 0);

    test("Hole cards only (no board)",
        [], [c(S,14),c(H,14),c(D,14),c(C,14),c(S,2)], 7);

    test("Board only (no hole cards)",
        [c(S,14),c(H,14),c(D,14),c(C,14),c(S,2)], [], 7);

    test("Split across board and hole",
        [c(S,14),c(H,14),c(D,14)], [c(C,14),c(S,2)], 7);

    // -----------------------------------------------------------------------
    writeln("\n=== HAND RANKING ORDER (higher rank beats lower) ===");
    // -----------------------------------------------------------------------

    Card[] straight_flush  = [c(S,9),c(S,8),c(S,7),c(S,6),c(S,5)];
    Card[] quads           = [c(S,14),c(H,14),c(D,14),c(C,14),c(S,2)];
    Card[] full_house      = [c(S,14),c(H,14),c(D,14),c(C,13),c(S,13)];
    Card[] flush_hand      = [c(S,14),c(S,10),c(S,7),c(S,4),c(S,2)];
    Card[] straight_hand   = [c(S,14),c(H,13),c(D,12),c(C,11),c(S,10)];
    Card[] trips_hand      = [c(S,14),c(H,14),c(D,14),c(C,2),c(S,3)];
    Card[] two_pair_hand   = [c(S,14),c(H,14),c(D,13),c(C,13),c(S,2)];
    Card[] pair_hand       = [c(S,14),c(H,14),c(D,2),c(C,3),c(S,4)];
    Card[] high_card_hand  = [c(S,14),c(H,10),c(D,7),c(C,4),c(S,2)];

    test_beats("Straight flush beats quads",      straight_flush, [], quads, []);
    test_beats("Quads beats full house",           quads, [], full_house, []);
    test_beats("Full house beats flush",           full_house, [], flush_hand, []);
    test_beats("Flush beats straight",             flush_hand, [], straight_hand, []);
    test_beats("Straight beats trips",             straight_hand, [], trips_hand, []);
    test_beats("Trips beats two pair",             trips_hand, [], two_pair_hand, []);
    test_beats("Two pair beats pair",              two_pair_hand, [], pair_hand, []);
    test_beats("Pair beats high card",             pair_hand, [], high_card_hand, []);

    // -----------------------------------------------------------------------
    writeln("\n=== TIEBREAKERS WITHIN SAME HAND TYPE ===");
    // -----------------------------------------------------------------------

    // straight flush tiebreaker
    test_beats("K-high SF beats 9-high SF",
        [c(S,13),c(S,12),c(S,11),c(S,10),c(S,9)], [],
        [c(H,9),c(H,8),c(H,7),c(H,6),c(H,5)], []);

    // quads tiebreaker
    test_beats("Quad aces beats quad kings",
        [c(S,14),c(H,14),c(D,14),c(C,14),c(S,2)], [],
        [c(S,13),c(H,13),c(D,13),c(C,13),c(S,2)], []);

    // quad kicker tiebreaker
    test_beats("Quad 2s king kicker beats quad 2s queen kicker",
        [c(S,2),c(H,2),c(D,2),c(C,2),c(S,13)], [],
        [c(S,2),c(H,2),c(D,2),c(C,2),c(S,12)], []);

    // full house tiebreaker
    test_beats("Aces full of 2s beats kings full of aces",
        [c(S,14),c(H,14),c(D,14),c(C,2),c(S,2)], [],
        [c(S,13),c(H,13),c(D,13),c(C,14),c(S,14)], []);

    // flush tiebreaker
    test_beats("A-high flush beats K-high flush",
        [c(S,14),c(S,10),c(S,7),c(S,4),c(S,2)], [],
        [c(H,13),c(H,10),c(H,7),c(H,4),c(H,2)], []);

    test_beats("Same top 4, higher 5th card wins flush",
        [c(S,14),c(S,13),c(S,12),c(S,11),c(S,4)], [],
        [c(H,14),c(H,13),c(H,12),c(H,11),c(H,2)], []);

    // straight tiebreaker
    test_beats("Broadway beats 9-high straight",
        [c(S,14),c(H,13),c(D,12),c(C,11),c(S,10)], [],
        [c(S,9),c(H,8),c(D,7),c(C,6),c(S,5)], []);

    test_beats("9-high straight beats wheel",
        [c(S,9),c(H,8),c(D,7),c(C,6),c(S,5)], [],
        [c(S,14),c(H,2),c(D,3),c(C,4),c(S,5)], []);

    // trips tiebreaker
    test_beats("Trip aces beats trip kings",
        [c(S,14),c(H,14),c(D,14),c(C,2),c(S,3)], [],
        [c(S,13),c(H,13),c(D,13),c(C,2),c(S,3)], []);

    // two pair tiebreaker - top pair
    test_beats("AA/22 beats KK/QQ",
        [c(S,14),c(H,14),c(D,2),c(C,2),c(S,3)], [],
        [c(S,13),c(H,13),c(D,12),c(C,12),c(S,3)], []);

    // two pair tiebreaker - second pair
    test_beats("AA/KK beats AA/QQ",
        [c(S,14),c(H,14),c(D,13),c(C,13),c(S,2)], [],
        [c(S,14),c(H,14),c(D,12),c(C,12),c(S,2)], []);

    // two pair tiebreaker - kicker
    test_beats("AA/KK/Q kicker beats AA/KK/J kicker",
        [c(S,14),c(H,14),c(D,13),c(C,13),c(S,12)], [],
        [c(S,14),c(H,14),c(D,13),c(C,13),c(S,11)], []);

    // pair tiebreaker
    test_beats("Pair of aces beats pair of kings",
        [c(S,14),c(H,14),c(D,2),c(C,3),c(S,4)], [],
        [c(S,13),c(H,13),c(D,2),c(C,3),c(S,4)], []);

    // pair kicker
    test_beats("Pair AA/K kicker beats pair AA/Q kicker",
        [c(S,14),c(H,14),c(D,13),c(C,2),c(S,3)], [],
        [c(S,14),c(H,14),c(D,12),c(C,2),c(S,3)], []);

    // high card tiebreaker
    test_beats("A-high beats K-high",
        [c(S,14),c(H,10),c(D,7),c(C,4),c(S,2)], [],
        [c(S,13),c(H,10),c(D,7),c(C,4),c(S,2)], []);

    // -----------------------------------------------------------------------
    writeln("\n=== TIES / EQUAL HANDS ===");
    // -----------------------------------------------------------------------

    test_equal("Same straight flush different suits",
        [c(S,9),c(S,8),c(S,7),c(S,6),c(S,5)], [],
        [c(H,9),c(H,8),c(H,7),c(H,6),c(H,5)], []);

    test_equal("Same quads same kicker",
        [c(S,7),c(H,7),c(D,7),c(C,7),c(S,14)], [],
        [c(S,7),c(H,7),c(D,7),c(C,7),c(H,14)], []);

    test_equal("Identical high card hands",
        [c(S,14),c(H,10),c(D,7),c(C,4),c(S,2)], [],
        [c(H,14),c(D,10),c(C,7),c(S,4),c(H,2)], []);

    test_equal("Same straight different suits",
        [c(S,9),c(H,8),c(D,7),c(C,6),c(S,5)], [],
        [c(H,9),c(D,8),c(C,7),c(S,6),c(H,5)], []);

    // -----------------------------------------------------------------------
    writeln("\n=== EDGE CASES ===");
    // -----------------------------------------------------------------------

    // flush vs straight - flush wins
    test_beats("Flush beats same-rank straight",
        [c(S,9),c(S,8),c(S,6),c(S,4),c(S,2)], [],   // 9-high flush (not a straight)
        [c(S,9),c(H,8),c(D,7),c(C,6),c(S,5)], []);  // 9-high straight

    // FIX 3: corrected test name - this is a straight flush, not just a flush
    test("6 cards same suit picks best 5 (royal straight flush)",
        [c(S,14),c(S,13),c(S,12),c(S,11),c(S,10),c(S,2)], [], 8);

    // dont mistake 4-flush for flush
    test("4 suited cards is not a flush",
        [c(S,14),c(S,13),c(S,12),c(S,11),c(H,2)], [], 0);

    // full house preferred over flush when both present
    test("Full house beats flush when both possible",
        [c(S,14),c(H,14),c(D,14),c(C,13),c(S,13),c(S,10),c(S,7)], [], 6);

    // straight flush not confused with separate straight+flush
    test("Straight and flush in different suits is just a flush",
        [c(S,9),c(S,7),c(S,5),c(S,3),c(S,2),c(H,8),c(D,6)], [], 5);

    // wheel straight flush
    test("Wheel straight flush A-2-3-4-5 same suit",
        [c(C,14),c(C,5),c(C,4),c(C,3),c(C,2)], [], 8);

    // 7 card hand with multiple straights picks highest
    test_beats("7 cards - picks highest straight",
        [c(S,14),c(H,13),c(D,12),c(C,11),c(S,10),c(H,9),c(D,8)], [],
        [c(S,9),c(H,8),c(D,7),c(C,6),c(S,5)], []);

    // quads + pair (7 cards) still quads
    test("Quads with full house cards is still quads",
        [c(S,14),c(H,14),c(D,14),c(C,14),c(S,13),c(H,13),c(D,2)], [], 7);

    // -----------------------------------------------------------------------
    writeln("\n=== RESULTS ===");
    writefln("Passed: %d / %d", passed, passed + failed);
    if (failed > 0)
        writefln("Failed: %d", failed);
    else
        writeln("All tests passed!");
}