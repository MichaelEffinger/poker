module tests.computer_player_tester;

import std.stdio;
import std.math : abs;
import std.algorithm.comparison : clamp;
import card;
import players.computer_player;

// suits
enum S = 0;
enum H = 1;
enum D = 2;
enum C = 3;

Card c(int suit, int rank) { return Card(suit, rank); }

int passed = 0;
int failed = 0;

// exact value test
void test_exact(T)(string name, T got, T expected) {
    if (got == expected) {
        writefln("  PASS: %s  (got %s)", name, got);
        passed++;
    } else {
        writefln("  FAIL: %s  expected=%s got=%s", name, expected, got);
        failed++;
    }
}

// value must be within [lo, hi]
void test_range(T)(string name, T got, T lo, T hi) {
    if (got >= lo && got <= hi) {
        writefln("  PASS: %s  (got %s, range [%s, %s])", name, got, lo, hi);
        passed++;
    } else {
        writefln("  FAIL: %s  expected in [%s, %s], got %s", name, lo, hi, got);
        failed++;
    }
}

// just display a value with no pass/fail — for non-deterministic results
void test_display(T)(string name, T got) {
    writefln("  INFO: %s  = %s", name, got);
}

// boolean test
void test_bool(string name, bool got, bool expected) {
    if (got == expected) {
        writefln("  PASS: %s  (got %s)", name, got);
        passed++;
    } else {
        writefln("  FAIL: %s  expected=%s got=%s", name, expected, got);
        failed++;
    }
}

// test that A > B
void test_greater(T)(string name, T a, T b) {
    if (a > b) {
        writefln("  PASS: %s  (%s > %s)", name, a, b);
        passed++;
    } else {
        writefln("  FAIL: %s  expected %s > %s", name, a, b);
        failed++;
    }
}


void computer_player_test() {

    // -----------------------------------------------------------------------
    writeln("\n=== PERSONALITY TRAITS: NIT ===");
    // -----------------------------------------------------------------------
    auto nit = new ComputerPlayer("Nit", ComputerPlayer.Types.NIT, 0.5f, 1000);
    test_range("NIT tightness",       nit.tightness,       0.85f, 1.0f);
    test_range("NIT aggression",      nit.aggression,      0.0f,  0.35f);
    test_range("NIT bluff_frequency", nit.bluff_frequency, 0.0f,  0.1f);
    test_range("NIT patience",        nit.patience,        0.85f, 1.0f);

    // -----------------------------------------------------------------------
    writeln("\n=== PERSONALITY TRAITS: MANIAC ===");
    // -----------------------------------------------------------------------
    auto maniac = new ComputerPlayer("Maniac", ComputerPlayer.Types.MANIAC, 0.5f, 1000);
    test_range("MANIAC aggression",      maniac.aggression,      0.9f,  1.0f);
    test_range("MANIAC tightness",       maniac.tightness,       0.0f,  0.15f);
    test_range("MANIAC bluff_frequency", maniac.bluff_frequency, 0.55f, 1.0f);
    test_range("MANIAC patience",        maniac.patience,        0.0f,  0.15f);

    // -----------------------------------------------------------------------
    writeln("\n=== PERSONALITY TRAITS: ROCK ===");
    // -----------------------------------------------------------------------
    auto rock = new ComputerPlayer("Rock", ComputerPlayer.Types.ROCK, 0.5f, 1000);
    test_exact("ROCK bluff_frequency", rock.bluff_frequency, 0.0f);
    test_exact("ROCK patience",        rock.patience,        1.0f);
    test_range("ROCK tightness",       rock.tightness,       0.9f, 1.0f);

    // -----------------------------------------------------------------------
    writeln("\n=== PERSONALITY TRAITS: STOIC ===");
    // -----------------------------------------------------------------------
    auto stoic = new ComputerPlayer("Stoic", ComputerPlayer.Types.STOIC, 0.5f, 1000);
    test_exact("STOIC tilt_resistance", stoic.tilt_resistance, 1.0f);

    // -----------------------------------------------------------------------
    writeln("\n=== PERSONALITY TRAITS: HOTHEAD ===");
    // -----------------------------------------------------------------------
    auto hothead = new ComputerPlayer("Hothead", ComputerPlayer.Types.HOTHEAD, 0.5f, 1000);
    test_range("HOTHEAD tilt_resistance", hothead.tilt_resistance, 0.0f, 0.15f);

    // -----------------------------------------------------------------------
    writeln("\n=== PERSONALITY TRAITS: TRAPPER ===");
    // -----------------------------------------------------------------------
    auto trapper = new ComputerPlayer("Trapper", ComputerPlayer.Types.TRAPPER, 0.5f, 1000);
    test_exact("TRAPPER trappiness", trapper.trappiness, 1.0f);

    // -----------------------------------------------------------------------
    writeln("\n=== PERSONALITY TRAITS: BULLY ===");
    // -----------------------------------------------------------------------
    auto bully = new ComputerPlayer("Bully", ComputerPlayer.Types.BULLY, 0.5f, 1000);
    test_exact("BULLY aggression", bully.aggression, 1.0f);

    // -----------------------------------------------------------------------
    writeln("\n=== PERSONALITY TRAITS: COWARD ===");
    // -----------------------------------------------------------------------
    auto coward = new ComputerPlayer("Coward", ComputerPlayer.Types.COWARD, 0.5f, 1000);
    test_exact("COWARD risk_tolerance", coward.risk_tolerance, 0.0f);

    // -----------------------------------------------------------------------
    writeln("\n=== PERSONALITY TRAITS: TILTER ===");
    // -----------------------------------------------------------------------
    auto tilter = new ComputerPlayer("Tilter", ComputerPlayer.Types.TILTER, 0.5f, 1000);
    test_range("TILTER starts with tilt", tilter.tilt, 0.55f, 1.0f);

    // -----------------------------------------------------------------------
    writeln("\n=== SIM COUNT SCALES WITH SKILL ===");
    // -----------------------------------------------------------------------
    auto low_skill  = new ComputerPlayer("Bad",  ComputerPlayer.Types.STANDARD, 0.0f, 1000);
    auto mid_skill  = new ComputerPlayer("Mid",  ComputerPlayer.Types.STANDARD, 0.5f, 1000);
    auto high_skill = new ComputerPlayer("Good", ComputerPlayer.Types.STANDARD, 1.0f, 1000);

    test_exact("skill=0 sim_count is minimum (10)", low_skill.sim_count,  cast(size_t)10);
    test_exact("skill=1 sim_count is maximum (5000)", high_skill.sim_count, cast(size_t)5000);
    test_greater("high skill has more sims than low skill", high_skill.sim_count, low_skill.sim_count);
    test_greater("mid skill has more sims than low skill",  mid_skill.sim_count,  low_skill.sim_count);
    test_display("mid skill sim_count", mid_skill.sim_count);

    // -----------------------------------------------------------------------
    writeln("\n=== CALCULATE POT ODDS ===");
    // -----------------------------------------------------------------------
    auto p = new ComputerPlayer("Test", ComputerPlayer.Types.STANDARD, 0.5f, 1000);

    // toCall=0 should always return 0 (free to play)
    test_exact("pot odds: free call is 0.0",
        p.calculate_pot_odds(100, 0), 0.0);

    // toCall / (pot + toCall)
    // 50 / (100 + 50) = 0.333...
    test_range("pot odds: 50 into 100 pot",
        p.calculate_pot_odds(100, 50), 0.32, 0.35);

    // 100 / (100 + 100) = 0.5
    test_range("pot odds: pot-sized bet",
        p.calculate_pot_odds(100, 100), 0.49, 0.51);

    // 200 / (100 + 200) = 0.666...
    test_range("pot odds: 2x overbet",
        p.calculate_pot_odds(100, 200), 0.65, 0.68);

    // huge overbet approaches 1.0
    test_range("pot odds: massive overbet approaches 1.0",
        p.calculate_pot_odds(10, 10000), 0.99, 1.0);

    // -----------------------------------------------------------------------
    writeln("\n=== EVALUATE STARTING HAND ===");
    // -----------------------------------------------------------------------

    // pocket pairs: score = 45 + rank*3
    auto skilled = new ComputerPlayer("Skilled", ComputerPlayer.Types.STANDARD, 1.0f, 1000);
    Card[] aces   = [c(S,14), c(H,14)];
    Card[] kings  = [c(S,13), c(H,13)];
    Card[] twos   = [c(S,2),  c(H,2)];

    int score_AA = skilled.evaluate_starting_hand(aces);
    int score_KK = skilled.evaluate_starting_hand(kings);
    int score_22 = skilled.evaluate_starting_hand(twos);

    test_exact("AA score formula: 45 + 14*3 = 87", score_AA, 87);
    test_exact("KK score formula: 45 + 13*3 = 84", score_KK, 84);
    test_exact("22 score formula: 45 + 2*3  = 51", score_22, 51);
    test_greater("AA scores higher than KK", score_AA, score_KK);
    test_greater("KK scores higher than 22", score_KK, score_22);

    // suited connectors get bonus
    Card[] suited_connectors   = [c(S,10), c(S,9)];
    Card[] offsuit_connectors  = [c(S,10), c(H,9)];
    int score_suited   = skilled.evaluate_starting_hand(suited_connectors);
    int score_offsuit  = skilled.evaluate_starting_hand(offsuit_connectors);
    test_greater("Suited connectors score higher than offsuit (skill=1)", score_suited, score_offsuit);

    // connectedness bonus: closer ranks score higher
    Card[] connected  = [c(S,10), c(H,9)];   // distance 1
    Card[] gapped     = [c(S,10), c(H,6)];   // distance 4, no bonus
    int score_conn = skilled.evaluate_starting_hand(connected);
    int score_gap  = skilled.evaluate_starting_hand(gapped);
    test_greater("Connected hand scores higher than gapped", score_conn, score_gap);

    // -----------------------------------------------------------------------
    writeln("\n=== SHOULD PLAY PREFLOP ===");
    // -----------------------------------------------------------------------

    // NIT should fold weak hands
    auto nit2 = new ComputerPlayer("Nit2", ComputerPlayer.Types.NIT, 0.5f, 1000);
    Card[] trash = [c(S,7), c(H,2)]; // offsuit 7-2, worst hand
    int trash_score = nit2.evaluate_starting_hand(trash);
    test_bool("NIT folds 7-2 offsuit preflop (no bet)",
        nit2.should_play_preflop(trash_score, 0, 0), false);

    // NIT should play AA
    int aa_score = nit2.evaluate_starting_hand(aces);
    test_bool("NIT plays AA preflop",
        nit2.should_play_preflop(aa_score, 0, 100), true);

    // MANIAC plays trash
    auto maniac2 = new ComputerPlayer("Maniac2", ComputerPlayer.Types.MANIAC, 0.5f, 1000);
    test_bool("MANIAC plays 7-2 offsuit (free to call)",
        maniac2.should_play_preflop(trash_score, 0, 100), true);

    // free to see flop should lower threshold
    auto std_player = new ComputerPlayer("Std", ComputerPlayer.Types.STANDARD, 0.5f, 1000);
    bool free_play = std_player.should_play_preflop(40, 0, 100);
    bool costly_play = std_player.should_play_preflop(40, 200, 10);
    test_display("Standard plays marginal hand free (score=40)", free_play);
    test_display("Standard plays marginal hand with large bet (score=40)", costly_play);

    // -----------------------------------------------------------------------
    writeln("\n=== TILT MECHANICS ===");
    // -----------------------------------------------------------------------

    auto hothead2 = new ComputerPlayer("HH2", ComputerPlayer.Types.HOTHEAD, 0.5f, 1000);
    auto stoic2   = new ComputerPlayer("St2", ComputerPlayer.Types.STOIC,   0.5f, 1000);

    float hh_tilt_before = hothead2.tilt;
    float st_tilt_before = stoic2.tilt;

    hothead2.on_bad_beat();
    stoic2.on_bad_beat();

    float hh_tilt_after = hothead2.tilt;
    float st_tilt_after = stoic2.tilt;

    test_greater("HOTHEAD tilt increases on bad beat", hh_tilt_after, hh_tilt_before);
    test_greater("STOIC tilt increases less than HOTHEAD on bad beat",
        hh_tilt_after - hh_tilt_before,
        st_tilt_after - st_tilt_before);

    // confidence drops on bad beat
    float hh_conf_before = 0.5f; // starting confidence
    hothead2.confidence = 0.5f;
    hothead2.on_bad_beat();
    test_range("Confidence drops after bad beat",
        hothead2.confidence, 0.0f, 0.49f);

    // win hand reduces tilt
    hothead2.tilt = 0.8f;
    hothead2.on_win_hand();
    test_range("Tilt reduced after winning hand",
        hothead2.tilt, 0.0f, 0.79f);

    // win bluff boosts confidence more than win hand
    auto p2 = new ComputerPlayer("P2", ComputerPlayer.Types.STANDARD, 0.5f, 1000);
    auto p3 = new ComputerPlayer("P3", ComputerPlayer.Types.STANDARD, 0.5f, 1000);
    p2.confidence = 0.5f;
    p3.confidence = 0.5f;
    p2.on_win_bluff();
    p3.on_win_hand();
    test_greater("Win bluff boosts confidence more than win hand",
        p2.confidence, p3.confidence);

    // tilt stays clamped at 1.0
    auto tilter2 = new ComputerPlayer("Tilter2", ComputerPlayer.Types.TILTER, 0.0f, 1000);
    tilter2.tilt = 1.0f;
    tilter2.on_bad_beat();
    test_range("Tilt never exceeds 1.0 after multiple bad beats",
        tilter2.tilt, 0.0f, 1.0f);

    // -----------------------------------------------------------------------
    writeln("\n=== SHOULD RAISE ===");
    // -----------------------------------------------------------------------
    auto aggressive = new ComputerPlayer("Aggro", ComputerPlayer.Types.BULLY, 0.5f, 1000);
    auto passive    = new ComputerPlayer("Pass",  ComputerPlayer.Types.CALLER, 0.5f, 1000);

    // big equity edge should trigger raise
    test_bool("Aggressive player raises with big equity edge (0.8 equity, 0.2 pot odds)",
        aggressive.should_raise(0.8, 0.2), true);

    // small edge may not raise for passive player
    test_display("Passive player raises with small edge (0.4 equity, 0.35 pot odds)",
        passive.should_raise(0.4, 0.35));

    // no edge = don't raise
    test_bool("Nobody raises with negative edge",
        aggressive.should_raise(0.2, 0.8), false);

    // -----------------------------------------------------------------------
    writeln("\n=== CALCULATE RAISE SIZE ===");
    // -----------------------------------------------------------------------
    auto raiser = new ComputerPlayer("Raiser", ComputerPlayer.Types.TAG, 0.5f, 500);

    // negative edge = 0 raise
    long zero_raise = raiser.calculate_raise_size(100, 10, 0.2, 0.8);
    test_exact("Negative edge produces 0 raise", zero_raise, 0L);

    // raise is at least 2x the call
    long min_raise = raiser.calculate_raise_size(100, 20, 0.9, 0.1);
    test_range("Raise is at least 2x toCall (min raise = 40)", min_raise, 40L, 500L);

    // raise never exceeds stack
    long capped_raise = raiser.calculate_raise_size(10000, 100, 0.99, 0.01);
    test_range("Raise never exceeds stack (500)", capped_raise, 0L, 500L);

    // bigger equity edge = bigger raise
    long small_edge_raise = raiser.calculate_raise_size(200, 10, 0.55, 0.3);
    long large_edge_raise = raiser.calculate_raise_size(200, 10, 0.9,  0.1);
    test_greater("Larger equity edge produces larger raise",
        large_edge_raise, small_edge_raise);

    // -----------------------------------------------------------------------
    writeln("\n=== BOREDOM PRESSURE ===");
    // -----------------------------------------------------------------------

    // patient player accumulates boredom slowly
    auto patient   = new ComputerPlayer("Patient",   ComputerPlayer.Types.GRINDER, 0.5f, 1000);
    auto impatient = new ComputerPlayer("Impatient", ComputerPlayer.Types.GAMBLER, 0.5f, 1000);

    float pat_boredom = 0.0f;
    float imp_boredom = 0.0f;
    for (int i = 0; i < 10; i++) {
        patient.boredom_pressure();
        impatient.boredom_pressure();
    }

    test_greater("Impatient player accumulates boredom faster than patient",
        impatient.boredom, patient.boredom);

    test_display("GRINDER boredom after 10 folds",  patient.boredom);
    test_display("GAMBLER boredom after 10 folds",  impatient.boredom);

    // -----------------------------------------------------------------------
    writeln("\n=== DETECT OVERPLAY / SUSPICION ===");
    // -----------------------------------------------------------------------
    auto watcher = new ComputerPlayer("Watcher", ComputerPlayer.Types.ABC, 0.5f, 1000);

    float suspicion_before = watcher.suspicion;
    watcher.detect_overplay(500, 50, false); // 10x pot overbet
    test_greater("Suspicion rises after massive overbet",
        watcher.suspicion, suspicion_before);

    watcher.detect_overplay(0, 50, true); // all-in
    test_greater("Suspicion rises on all-in",
        watcher.suspicion, suspicion_before);

    // suspicion decays over time
    watcher.suspicion = 0.5f;
    float before_decay = watcher.suspicion;
    watcher.update_reputation();
    test_range("Suspicion decays after update_reputation",
        watcher.suspicion, 0.0f, before_decay);

    // suspicion never goes negative
    watcher.suspicion = 0.0f;
    watcher.update_reputation();
    test_range("Suspicion never goes negative", watcher.suspicion, 0.0f, 1.0f);

    // suspicion capped at 1.0
    watcher.suspicion = 0.95f;
    watcher.detect_overplay(99999, 10, true);
    test_range("Suspicion capped at 1.0", watcher.suspicion, 0.0f, 1.0f);

    // -----------------------------------------------------------------------
    writeln("\n=== CONFIDENT ENOUGH ===");
    // -----------------------------------------------------------------------
    auto conf_player = new ComputerPlayer("Conf", ComputerPlayer.Types.STANDARD, 0.5f, 1000);

    // free call is always confident enough
    test_bool("Always confident enough for free call (toCall=0)",
        conf_player.confident_enough(0.1, 100, 0), true);

    // very strong equity vs small bet = confident
    test_bool("Confident with 90% equity vs small bet",
        conf_player.confident_enough(0.9, 100, 5), true);

    // very weak equity vs large bet = not confident
    test_bool("Not confident with 10% equity vs pot-sized bet",
        conf_player.confident_enough(0.1, 100, 100), false);

    // tilt lowers threshold (tilted player calls more)
    auto tilt_player = new ComputerPlayer("TiltConf", ComputerPlayer.Types.STANDARD, 0.5f, 1000);
    tilt_player.tilt = 1.0f;
    tilt_player.tilt_resistance = 0.0f;
    bool tilted_call   = tilt_player.confident_enough(0.35, 100, 100);
    bool normal_call   = conf_player.confident_enough(0.35, 100, 100);
    test_display("Tilted player confident enough at 35% equity pot-sized bet", tilted_call);
    test_display("Normal player confident enough at 35% equity pot-sized bet", normal_call);

    // sunk cost: bad player with money in pot is more likely to call
    auto fish = new ComputerPlayer("Fish", ComputerPlayer.Types.STANDARD, 0.0f, 1000);
    fish.sunk_cost = 500;
    fish.risk_tolerance = 1.0f;
    bool sunk_cost_call = fish.confident_enough(0.3, 100, 100);
    test_display("Fish with 500 sunk cost confident at 30% equity", sunk_cost_call);

    // -----------------------------------------------------------------------
    writeln("\n=== EFFECTIVE TIGHTNESS ===");
    // -----------------------------------------------------------------------
    auto tight_bored = new ComputerPlayer("TightBored", ComputerPlayer.Types.NIT, 0.5f, 1000);
    float tight_fresh = tight_bored.effective_tightness();

    tight_bored.boredom = 0.5f;
    float tight_bored_val = tight_bored.effective_tightness();

    test_greater("Boredom reduces effective tightness", tight_fresh, tight_bored_val);
    test_range("Effective tightness always in [0,1]", tight_bored_val, 0.0f, 1.0f);

    // boredom can't make effective tightness negative
    tight_bored.boredom = 1.0f;
    test_range("Effective tightness floored at 0 with max boredom",
        tight_bored.effective_tightness(), 0.0f, 1.0f);

    // -----------------------------------------------------------------------
    writeln("\n=== RESULTS ===");
    writefln("Passed: %d / %d", passed, passed + failed);
    if (failed > 0)
        writefln("Failed: %d", failed);
    else
        writeln("All tests passed!");
}