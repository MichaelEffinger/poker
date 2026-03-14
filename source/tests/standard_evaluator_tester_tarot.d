module tests.standard_evaluator_tester_tarot;

import std.stdio;
import card;
import evaluators.standard_evaluator;

// Tarot suits
enum SW = 0; // swords
enum CU = 1; // cups
enum PE = 2; // pentacles
enum WA = 3; // wands

// Tarot ranks: 2-10 = 2-10, Page=11, Knight=12, Queen=13, King=14, Ace=15
enum PAGE   = 11;
enum KNIGHT = 12;
enum QUEEN  = 13;
enum KING   = 14;
enum ACE    = 15;

Card c(int suit, int rank) { return Card(suit, rank); }

// Tarot evaluator: min_rank=2, max_rank=15, suit_count=4
StandardEvaluator eval;

int score(Card[] board, Card[] hole) {
    return eval(board, hole);
}

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

void standard_evaluator_test_tarot() {
    // min=2, max=15 (Ace), 4 suits
    eval = new StandardEvaluator(2, 15, 4);

    // -----------------------------------------------------------------------
    writeln("\n=== TAROT: HAND TYPE DETECTION ===");
    // -----------------------------------------------------------------------

    // straight flush using court cards
    test("Royal straight flush Ace-King-Queen-Knight-Page swords",
        [c(SW,ACE),c(SW,KING),c(SW,QUEEN),c(SW,KNIGHT),c(SW,PAGE)], [], 8);

    test("Straight flush Knight-high cups",
        [c(CU,KNIGHT),c(CU,PAGE),c(CU,10),c(CU,9),c(CU,8)], [], 8);

    test("Straight flush 6-high pentacles",
        [c(PE,6),c(PE,5),c(PE,4),c(PE,3),c(PE,2)], [], 8);

    test("Wheel straight flush A-2-3-4-5 wands",
        [c(WA,ACE),c(WA,2),c(WA,3),c(WA,4),c(WA,5)], [], 8);

    test("Straight flush Page-high swords (Page-10-9-8-7)",
        [c(SW,PAGE),c(SW,10),c(SW,9),c(SW,8),c(SW,7)], [], 8);

    // quads using court cards
    test("Four Pages",
        [c(SW,PAGE),c(CU,PAGE),c(PE,PAGE),c(WA,PAGE),c(SW,2)], [], 7);

    test("Four Knights",
        [c(SW,KNIGHT),c(CU,KNIGHT),c(PE,KNIGHT),c(WA,KNIGHT),c(SW,ACE)], [], 7);

    test("Four Queens",
        [c(SW,QUEEN),c(CU,QUEEN),c(PE,QUEEN),c(WA,QUEEN),c(SW,3)], [], 7);

    test("Four Kings",
        [c(SW,KING),c(CU,KING),c(PE,KING),c(WA,KING),c(SW,ACE)], [], 7);

    test("Four Aces",
        [c(SW,ACE),c(CU,ACE),c(PE,ACE),c(WA,ACE),c(SW,2)], [], 7);

    // full house with court cards
    test("Pages full of Knights",
        [c(SW,PAGE),c(CU,PAGE),c(PE,PAGE),c(SW,KNIGHT),c(CU,KNIGHT)], [], 6);

    test("Aces full of Kings",
        [c(SW,ACE),c(CU,ACE),c(PE,ACE),c(SW,KING),c(CU,KING)], [], 6);

    test("Queens full of Pages",
        [c(SW,QUEEN),c(CU,QUEEN),c(PE,QUEEN),c(SW,PAGE),c(CU,PAGE)], [], 6);

    // flush using new suits
    test("Ace-high flush swords",
        [c(SW,ACE),c(SW,10),c(SW,7),c(SW,4),c(SW,2)], [], 5);

    test("King-high flush cups",
        [c(CU,KING),c(CU,9),c(CU,6),c(CU,4),c(CU,2)], [], 5);

    test("Ace-high flush pentacles",
        [c(PE,ACE),c(PE,QUEEN),c(PE,9),c(PE,5),c(PE,3)], [], 5);

    test("Ace-high flush wands",
        [c(WA,ACE),c(WA,KNIGHT),c(WA,8),c(WA,5),c(WA,2)], [], 5);

    test("Flush not triggered with 4 suited (tarot)",
        [c(SW,ACE),c(SW,KING),c(SW,QUEEN),c(SW,PAGE),c(CU,2)], [], 0);

    // straights using court cards
    test("Ace-high straight A-K-Q-Kn-Pa mixed suits",
        [c(SW,ACE),c(CU,KING),c(PE,QUEEN),c(WA,KNIGHT),c(SW,PAGE)], [], 4);

    test("King-high straight K-Q-Kn-Pa-10",
        [c(SW,KING),c(CU,QUEEN),c(PE,KNIGHT),c(WA,PAGE),c(SW,10)], [], 4);

    test("Queen-high straight Q-Kn-Pa-10-9",
        [c(SW,QUEEN),c(CU,KNIGHT),c(PE,PAGE),c(WA,10),c(SW,9)], [], 4);

    test("Knight-high straight Kn-Pa-10-9-8",
        [c(SW,KNIGHT),c(CU,PAGE),c(PE,10),c(WA,9),c(SW,8)], [], 4);

    test("Page-high straight Pa-10-9-8-7",
        [c(SW,PAGE),c(CU,10),c(PE,9),c(WA,8),c(SW,7)], [], 4);

    test("Wheel straight A-2-3-4-5 mixed suits",
        [c(SW,ACE),c(CU,2),c(PE,3),c(WA,4),c(SW,5)], [], 4);

    test("Straight spanning low-to-court 7-8-9-10-Page",
        [c(SW,7),c(CU,8),c(PE,9),c(WA,10),c(SW,PAGE)], [], 4);

    // trips with court cards
    test("Three Pages",
        [c(SW,PAGE),c(CU,PAGE),c(PE,PAGE),c(SW,2),c(CU,3)], [], 3);

    test("Three Aces",
        [c(SW,ACE),c(CU,ACE),c(PE,ACE),c(SW,2),c(CU,3)], [], 3);

    test("Three Kings",
        [c(SW,KING),c(CU,KING),c(PE,KING),c(SW,ACE),c(CU,2)], [], 3);

    // two pair with court cards
    test("Aces and Kings",
        [c(SW,ACE),c(CU,ACE),c(SW,KING),c(CU,KING),c(SW,2)], [], 2);

    test("Pages and Knights",
        [c(SW,PAGE),c(CU,PAGE),c(SW,KNIGHT),c(CU,KNIGHT),c(SW,ACE)], [], 2);

    test("Queens and Pages",
        [c(SW,QUEEN),c(CU,QUEEN),c(SW,PAGE),c(CU,PAGE),c(SW,2)], [], 2);

    // pair with court cards
    test("Pair of Aces",
        [c(SW,ACE),c(CU,ACE),c(SW,2),c(CU,3),c(PE,4)], [], 1);

    test("Pair of Pages",
        [c(SW,PAGE),c(CU,PAGE),c(SW,ACE),c(CU,KING),c(PE,2)], [], 1);

    test("Pair of Knights",
        [c(SW,KNIGHT),c(CU,KNIGHT),c(SW,ACE),c(CU,2),c(PE,3)], [], 1);

    // high card with court cards
    test("Ace high (tarot)",
        [c(SW,ACE),c(CU,KING),c(PE,9),c(WA,5),c(SW,2)], [], 0);

    test("King high no pair",
        [c(SW,KING),c(CU,PAGE),c(PE,9),c(WA,6),c(SW,2)], [], 0);

    // -----------------------------------------------------------------------
    writeln("\n=== TAROT: HAND RANKING ORDER ===");
    // -----------------------------------------------------------------------

    Card[] sf   = [c(SW,ACE),c(SW,KING),c(SW,QUEEN),c(SW,KNIGHT),c(SW,PAGE)];
    Card[] quad = [c(SW,ACE),c(CU,ACE),c(PE,ACE),c(WA,ACE),c(SW,2)];
    Card[] fh   = [c(SW,ACE),c(CU,ACE),c(PE,ACE),c(SW,KING),c(CU,KING)];
    Card[] fl   = [c(SW,ACE),c(SW,KING),c(SW,9),c(SW,5),c(SW,2)];
    Card[] st   = [c(SW,ACE),c(CU,KING),c(PE,QUEEN),c(WA,KNIGHT),c(SW,PAGE)];
    Card[] tr   = [c(SW,ACE),c(CU,ACE),c(PE,ACE),c(SW,2),c(CU,3)];
    Card[] tp   = [c(SW,ACE),c(CU,ACE),c(SW,KING),c(CU,KING),c(SW,2)];
    Card[] pr   = [c(SW,ACE),c(CU,ACE),c(SW,2),c(CU,3),c(PE,4)];
    Card[] hc   = [c(SW,ACE),c(CU,KING),c(PE,9),c(WA,5),c(SW,2)];

    test_beats("SF beats quads (tarot)",      sf,   [], quad, []);
    test_beats("Quads beats full house (tarot)", quad, [], fh,   []);
    test_beats("Full house beats flush (tarot)", fh,   [], fl,   []);
    test_beats("Flush beats straight (tarot)",   fl,   [], st,   []);
    test_beats("Straight beats trips (tarot)",   st,   [], tr,   []);
    test_beats("Trips beats two pair (tarot)",   tr,   [], tp,   []);
    test_beats("Two pair beats pair (tarot)",    tp,   [], pr,   []);
    test_beats("Pair beats high card (tarot)",   pr,   [], hc,   []);

    // -----------------------------------------------------------------------
    writeln("\n=== TAROT: COURT CARD TIEBREAKERS ===");
    // -----------------------------------------------------------------------

    // straight flush tiebreaker through court cards
    test_beats("Ace-high SF beats King-high SF",
        [c(SW,ACE),c(SW,KING),c(SW,QUEEN),c(SW,KNIGHT),c(SW,PAGE)], [],
        [c(CU,KING),c(CU,QUEEN),c(CU,KNIGHT),c(CU,PAGE),c(CU,10)], []);

    test_beats("King-high SF beats Knight-high SF",
        [c(SW,KING),c(SW,QUEEN),c(SW,KNIGHT),c(SW,PAGE),c(SW,10)], [],
        [c(CU,KNIGHT),c(CU,PAGE),c(CU,10),c(CU,9),c(CU,8)], []);

    test_beats("Page-high SF beats 10-high SF",
        [c(SW,PAGE),c(SW,10),c(SW,9),c(SW,8),c(SW,7)], [],
        [c(CU,10),c(CU,9),c(CU,8),c(CU,7),c(CU,6)], []);

    // quads tiebreaker - court cards rank higher than numerals
    test_beats("Quad Aces beats quad Kings",
        [c(SW,ACE),c(CU,ACE),c(PE,ACE),c(WA,ACE),c(SW,2)], [],
        [c(SW,KING),c(CU,KING),c(PE,KING),c(WA,KING),c(SW,2)], []);

    test_beats("Quad Kings beats quad Queens",
        [c(SW,KING),c(CU,KING),c(PE,KING),c(WA,KING),c(SW,ACE)], [],
        [c(SW,QUEEN),c(CU,QUEEN),c(PE,QUEEN),c(WA,QUEEN),c(SW,ACE)], []);

    test_beats("Quad Queens beats quad Knights",
        [c(SW,QUEEN),c(CU,QUEEN),c(PE,QUEEN),c(WA,QUEEN),c(SW,ACE)], [],
        [c(SW,KNIGHT),c(CU,KNIGHT),c(PE,KNIGHT),c(WA,KNIGHT),c(SW,ACE)], []);

    test_beats("Quad Knights beats quad Pages",
        [c(SW,KNIGHT),c(CU,KNIGHT),c(PE,KNIGHT),c(WA,KNIGHT),c(SW,ACE)], [],
        [c(SW,PAGE),c(CU,PAGE),c(PE,PAGE),c(WA,PAGE),c(SW,ACE)], []);

    test_beats("Quad Pages beats quad 10s",
        [c(SW,PAGE),c(CU,PAGE),c(PE,PAGE),c(WA,PAGE),c(SW,ACE)], [],
        [c(SW,10),c(CU,10),c(PE,10),c(WA,10),c(SW,ACE)], []);

    // quad kicker using court cards
    test_beats("Quad 2s ace kicker beats quad 2s king kicker",
        [c(SW,2),c(CU,2),c(PE,2),c(WA,2),c(SW,ACE)], [],
        [c(SW,2),c(CU,2),c(PE,2),c(WA,2),c(SW,KING)], []);

    test_beats("Quad 2s king kicker beats quad 2s queen kicker",
        [c(SW,2),c(CU,2),c(PE,2),c(WA,2),c(SW,KING)], [],
        [c(SW,2),c(CU,2),c(PE,2),c(WA,2),c(SW,QUEEN)], []);

    // full house tiebreaker with court cards
    test_beats("Aces full of Kings beats Kings full of Aces",
        [c(SW,ACE),c(CU,ACE),c(PE,ACE),c(SW,KING),c(CU,KING)], [],
        [c(SW,KING),c(CU,KING),c(PE,KING),c(SW,ACE),c(CU,ACE)], []);

    test_beats("Queens full of Aces beats Pages full of Aces",
        [c(SW,QUEEN),c(CU,QUEEN),c(PE,QUEEN),c(SW,ACE),c(CU,ACE)], [],
        [c(SW,PAGE),c(CU,PAGE),c(PE,PAGE),c(SW,ACE),c(CU,ACE)], []);

    // flush tiebreaker - ace vs king high across suits
    test_beats("Ace-high flush swords beats King-high flush cups",
        [c(SW,ACE),c(SW,10),c(SW,7),c(SW,4),c(SW,2)], [],
        [c(CU,KING),c(CU,10),c(CU,7),c(CU,4),c(CU,2)], []);
        
    // straight tiebreaker - court card straights
    test_beats("Ace-high straight beats King-high straight",
        [c(SW,ACE),c(CU,KING),c(PE,QUEEN),c(WA,KNIGHT),c(SW,PAGE)], [],
        [c(SW,KING),c(CU,QUEEN),c(PE,KNIGHT),c(WA,PAGE),c(SW,10)], []);

    test_beats("King-high straight beats Queen-high straight",
        [c(SW,KING),c(CU,QUEEN),c(PE,KNIGHT),c(WA,PAGE),c(SW,10)], [],
        [c(SW,QUEEN),c(CU,KNIGHT),c(PE,PAGE),c(WA,10),c(SW,9)], []);

    test_beats("Queen-high straight beats Knight-high straight",
        [c(SW,QUEEN),c(CU,KNIGHT),c(PE,PAGE),c(WA,10),c(SW,9)], [],
        [c(SW,KNIGHT),c(CU,PAGE),c(PE,10),c(WA,9),c(SW,8)], []);

    test_beats("Knight-high straight beats Page-high straight",
        [c(SW,KNIGHT),c(CU,PAGE),c(PE,10),c(WA,9),c(SW,8)], [],
        [c(SW,PAGE),c(CU,10),c(PE,9),c(WA,8),c(SW,7)], []);

    test_beats("Page-high straight beats 10-high straight",
        [c(SW,PAGE),c(CU,10),c(PE,9),c(WA,8),c(SW,7)], [],
        [c(SW,10),c(CU,9),c(PE,8),c(WA,7),c(SW,6)], []);

    test_beats("9-high straight beats wheel (A-2-3-4-5)",
        [c(SW,9),c(CU,8),c(PE,7),c(WA,6),c(SW,5)], [],
        [c(SW,ACE),c(CU,2),c(PE,3),c(WA,4),c(SW,5)], []);

    // trips tiebreaker
    test_beats("Trip Aces beats trip Kings",
        [c(SW,ACE),c(CU,ACE),c(PE,ACE),c(SW,2),c(CU,3)], [],
        [c(SW,KING),c(CU,KING),c(PE,KING),c(SW,2),c(CU,3)], []);

    test_beats("Trip Kings beats trip Queens",
        [c(SW,KING),c(CU,KING),c(PE,KING),c(SW,ACE),c(CU,2)], [],
        [c(SW,QUEEN),c(CU,QUEEN),c(PE,QUEEN),c(SW,ACE),c(CU,2)], []);

    test_beats("Trip Pages beats trip 10s",
        [c(SW,PAGE),c(CU,PAGE),c(PE,PAGE),c(SW,ACE),c(CU,2)], [],
        [c(SW,10),c(CU,10),c(PE,10),c(SW,ACE),c(CU,2)], []);

    // two pair tiebreaker
    test_beats("Aces/Kings beats Queens/Knights",
        [c(SW,ACE),c(CU,ACE),c(SW,KING),c(CU,KING),c(SW,2)], [],
        [c(SW,QUEEN),c(CU,QUEEN),c(SW,KNIGHT),c(CU,KNIGHT),c(SW,2)], []);

    test_beats("Aces/Pages beats Kings/Queens",
        [c(SW,ACE),c(CU,ACE),c(SW,PAGE),c(CU,PAGE),c(SW,2)], [],
        [c(SW,KING),c(CU,KING),c(SW,QUEEN),c(CU,QUEEN),c(SW,2)], []);

    // pair tiebreaker
    test_beats("Pair of Aces beats pair of Kings",
        [c(SW,ACE),c(CU,ACE),c(SW,2),c(CU,3),c(PE,4)], [],
        [c(SW,KING),c(CU,KING),c(SW,2),c(CU,3),c(PE,4)], []);

    test_beats("Pair of Pages beats pair of 10s",
        [c(SW,PAGE),c(CU,PAGE),c(SW,ACE),c(CU,2),c(PE,3)], [],
        [c(SW,10),c(CU,10),c(SW,ACE),c(CU,2),c(PE,3)], []);

    // pair kicker tiebreaker - ace kicker vs king kicker
    test_beats("Pair of Pages ace kicker beats pair of Pages king kicker",
        [c(SW,PAGE),c(CU,PAGE),c(SW,ACE),c(CU,2),c(PE,3)], [],
        [c(SW,PAGE),c(CU,PAGE),c(SW,KING),c(CU,2),c(PE,3)], []);

    // high card tiebreaker
    test_beats("Ace high beats King high (tarot)",
        [c(SW,ACE),c(CU,KNIGHT),c(PE,8),c(WA,5),c(SW,2)], [],
        [c(SW,KING),c(CU,KNIGHT),c(PE,8),c(WA,5),c(SW,2)], []);

    test_beats("King high beats Queen high",
        [c(SW,KING),c(CU,PAGE),c(PE,8),c(WA,5),c(SW,2)], [],
        [c(SW,QUEEN),c(CU,PAGE),c(PE,8),c(WA,5),c(SW,2)], []);

    // -----------------------------------------------------------------------
    writeln("\n=== TAROT: TIES / EQUAL HANDS ===");
    // -----------------------------------------------------------------------

    test_equal("Same SF different suits (swords vs cups)",
        [c(SW,ACE),c(SW,KING),c(SW,QUEEN),c(SW,KNIGHT),c(SW,PAGE)], [],
        [c(CU,ACE),c(CU,KING),c(CU,QUEEN),c(CU,KNIGHT),c(CU,PAGE)], []);

    test_equal("Same SF different suits (pentacles vs wands)",
        [c(PE,KNIGHT),c(PE,PAGE),c(PE,10),c(PE,9),c(PE,8)], [],
        [c(WA,KNIGHT),c(WA,PAGE),c(WA,10),c(WA,9),c(WA,8)], []);

    test_equal("Same quads same kicker different suits",
        [c(SW,PAGE),c(CU,PAGE),c(PE,PAGE),c(WA,PAGE),c(SW,ACE)], [],
        [c(SW,PAGE),c(CU,PAGE),c(PE,PAGE),c(WA,PAGE),c(CU,ACE)], []);

    test_equal("Same straight different suits (court cards)",
        [c(SW,ACE),c(CU,KING),c(PE,QUEEN),c(WA,KNIGHT),c(SW,PAGE)], [],
        [c(CU,ACE),c(PE,KING),c(WA,QUEEN),c(SW,KNIGHT),c(CU,PAGE)], []);

    test_equal("Same flush rank different suits",
        [c(SW,ACE),c(SW,KING),c(SW,9),c(SW,5),c(SW,2)], [],
        [c(CU,ACE),c(CU,KING),c(CU,9),c(CU,5),c(CU,2)], []);

    test_equal("Same high card hand different suits",
        [c(SW,ACE),c(CU,KING),c(PE,9),c(WA,5),c(SW,2)], [],
        [c(CU,ACE),c(PE,KING),c(WA,9),c(SW,5),c(CU,2)], []);

    // -----------------------------------------------------------------------
    writeln("\n=== TAROT: EDGE CASES ===");
    // -----------------------------------------------------------------------

    // wheel straight flush with ace as low
    test("Wheel SF: A-2-3-4-5 wands",
        [c(WA,ACE),c(WA,2),c(WA,3),c(WA,4),c(WA,5)], [], 8);

    test("Wheel straight A-2-3-4-5 mixed suits is not SF",
        [c(SW,ACE),c(CU,2),c(PE,3),c(WA,4),c(SW,5)], [], 4);

    // 7-card hand with multiple court-card straights picks highest
    test_beats("7 cards picks Ace-high straight over King-high",
        [c(SW,ACE),c(CU,KING),c(PE,QUEEN),c(WA,KNIGHT),c(SW,PAGE),c(CU,10),c(PE,9)], [],
        [c(SW,KING),c(CU,QUEEN),c(PE,KNIGHT),c(WA,PAGE),c(SW,10)], []);

    // full house beats flush when both available
    test("Full house beats flush when both possible (tarot suits)",
        [c(SW,ACE),c(CU,ACE),c(PE,ACE),c(SW,KING),c(CU,KING),c(SW,PAGE),c(SW,9)], [], 6);

    // 6 suited cards picks best 5 - straight flush
    test("6 swords including royal SF picks best 5",
        [c(SW,ACE),c(SW,KING),c(SW,QUEEN),c(SW,KNIGHT),c(SW,PAGE),c(SW,2)], [], 8);

    // 4 suited is not a flush
    test("4 cups is not a flush (tarot)",
        [c(CU,ACE),c(CU,KING),c(CU,PAGE),c(CU,9),c(SW,2)], [], 0);

    // quads with full house cards still quads
    test("Quads + pair is still quads (tarot)",
        [c(SW,ACE),c(CU,ACE),c(PE,ACE),c(WA,ACE),c(SW,KING),c(CU,KING),c(PE,2)], [], 7);

    // two trips still becomes full house
    test("Two trips becomes full house (court cards)",
        [c(SW,ACE),c(CU,ACE),c(PE,ACE),c(SW,KING),c(CU,KING),c(PE,KING),c(SW,2)], [], 6);

    // straight not confused with almost-straight through court cards
    test("Almost straight through court gap is not straight (Q-Kn-Pa-10-8)",
        [c(SW,QUEEN),c(CU,KNIGHT),c(PE,PAGE),c(WA,10),c(SW,8)], [], 0);

    // -----------------------------------------------------------------------
    writeln("\n=== TAROT: CROSS-SUIT FUNCTIONALITY ===");
    // -----------------------------------------------------------------------

    // verify all 4 tarot suits can form flushes
    test("Swords flush",
        [c(SW,ACE),c(SW,KING),c(SW,9),c(SW,5),c(SW,2)], [], 5);

    test("Cups flush",
        [c(CU,ACE),c(CU,KING),c(CU,9),c(CU,5),c(CU,2)], [], 5);

    test("Pentacles flush",
        [c(PE,ACE),c(PE,KING),c(PE,9),c(PE,5),c(PE,2)], [], 5);

    test("Wands flush",
        [c(WA,ACE),c(WA,KING),c(WA,9),c(WA,5),c(WA,2)], [], 5);

    // verify all 4 suits can form straight flushes
    test("Swords straight flush",
        [c(SW,9),c(SW,8),c(SW,7),c(SW,6),c(SW,5)], [], 8);

    test("Cups straight flush",
        [c(CU,9),c(CU,8),c(CU,7),c(CU,6),c(CU,5)], [], 8);

    test("Pentacles straight flush",
        [c(PE,9),c(PE,8),c(PE,7),c(PE,6),c(PE,5)], [], 8);

    test("Wands straight flush",
        [c(WA,9),c(WA,8),c(WA,7),c(WA,6),c(WA,5)], [], 8);

    // mixed board/hole split with court cards
    test("Court cards split across board and hole",
        [c(SW,ACE),c(CU,ACE),c(PE,ACE)], [c(WA,ACE),c(SW,KING)], 7);

    test("Straight flush split across board and hole",
        [c(SW,ACE),c(SW,KING),c(SW,QUEEN)], [c(SW,KNIGHT),c(SW,PAGE)], 8);

    // -----------------------------------------------------------------------
    writeln("\n=== RESULTS ===");
    writefln("Passed: %d / %d", passed, passed + failed);
    if (failed > 0)
        writefln("Failed: %d", failed);
    else
        writeln("All tests passed!");
}