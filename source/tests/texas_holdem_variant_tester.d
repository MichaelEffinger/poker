module tests.texas_holdem_variant_tester;

import std.stdio;
import std.conv : to;
import variants.texas_hold_em;
import variants.poker_variant;
import players.player;
import evaluators.evaluator;
import card;
import deck;

// ─── Stubs ───────────────────────────────────────────────────────────────────

class StubEvaluator : Evaluator {
    override int opCall(const Card[] board, const Card[] hole) {
        return 0;
    }
}

class StubPlayer : Player {
    long forced_return;
    this(string n, long stack_, long forced_return_ = 0) {
        name          = n;
        stack         = stack_;
        forced_return = forced_return_;
    }
    override long take_turn(Card[] board, long pot, long toCall,
                            size_t players_in, Evaluator eval) {
        return forced_return;
    }
}

Player[] make_players(int count, long stack = 1000) {
    Player[] players;
    foreach(i; 0..count)
        players ~= new StubPlayer("P" ~ to!string(i), stack);
    return players;
}

Deck make_deck() {
    Deck d = Deck.create_standard_52();
    d.shuffle_deck();
    return d;
}

// ─── post_blinds ─────────────────────────────────────────────────────────────

void test_post_blinds_deducts_correctly() {
    writeln("TEST: post_blinds deducts sb and bb correctly");
    auto variant = new TexasHoldEm();
    variant.current_blind = 10;
    Player[] players = make_players(4);
    size_t current_turn = 0;
    variant.post_blinds(players, current_turn);
    assert(players[1].round_bets == 10,  "SB round_bets should be 10");
    assert(players[1].stack     == 990,  "SB stack should be 990");
    assert(players[2].round_bets == 20,  "BB round_bets should be 20");
    assert(players[2].stack     == 980,  "BB stack should be 980");
    assert(current_turn == 3,            "current_turn should be UTG (seat 3)");
    writeln("  PASSED");
}

void test_post_blinds_skips_null_players() {
    writeln("TEST: post_blinds skips null seats");
    auto variant = new TexasHoldEm();
    variant.current_blind = 10;
    Player[] players = make_players(4);
    players[1] = null;
    size_t current_turn = 0;
    variant.post_blinds(players, current_turn);
    assert(players[2].round_bets == 10, "SB should be seat 2");
    assert(players[3].round_bets == 20, "BB should be seat 3");
    writeln("  PASSED");
}

void test_post_blinds_utg_correct_two_players() {
    writeln("TEST: post_blinds heads up - dealer is sb, other is bb, UTG wraps to dealer");
    auto variant = new TexasHoldEm();
    variant.current_blind = 10;
    Player[] players = make_players(2);
    size_t current_turn = 0; // dealer
    variant.post_blinds(players, current_turn);
    assert(players[0].round_bets == 10, "Dealer should be SB heads up");
    assert(players[1].round_bets == 20, "Other should be BB heads up");
    assert(current_turn == 0,           "UTG wraps back to dealer heads up");
    writeln("  PASSED");
}

void test_post_blinds_does_not_set_matched() {
    writeln("TEST: post_blinds does not set matched on bb so they get their option");
    auto variant = new TexasHoldEm();
    variant.current_blind = 10;
    Player[] players = make_players(4);
    size_t current_turn = 0;
    variant.post_blinds(players, current_turn);
    assert(!players[2].matched, "BB should not be matched yet, they get their option");
    writeln("  PASSED");
}

void test_post_blinds_large_blind() {
    writeln("TEST: post_blinds works with large blind values");
    auto variant = new TexasHoldEm();
    variant.current_blind = 500;
    Player[] players = make_players(3, 10000);
    size_t current_turn = 0;
    variant.post_blinds(players, current_turn);
    assert(players[1].stack == 9500,  "SB stack after 500 blind");
    assert(players[2].stack == 9000,  "BB stack after 1000 blind");
    writeln("  PASSED");
}

// ─── betting_complete ─────────────────────────────────────────────────────────

void test_betting_complete_all_matched() {
    writeln("TEST: betting_complete returns true when all active players matched");
    auto variant = new TexasHoldEm();
    Player[] players = make_players(3);
    foreach(p; players) p.matched = true;
    assert(variant.betting_complete(players));
    writeln("  PASSED");
}

void test_betting_complete_someone_unmatched() {
    writeln("TEST: betting_complete returns false when someone hasnt matched");
    auto variant = new TexasHoldEm();
    Player[] players = make_players(3);
    players[0].matched = true;
    players[1].matched = true;
    players[2].matched = false;
    assert(!variant.betting_complete(players));
    writeln("  PASSED");
}

void test_betting_complete_skips_folded() {
    writeln("TEST: betting_complete skips folded players");
    auto variant = new TexasHoldEm();
    Player[] players = make_players(3);
    players[0].matched = true;
    players[1].matched = true;
    players[2].matched = false;
    players[2].folded  = true;
    assert(variant.betting_complete(players));
    writeln("  PASSED");
}

void test_betting_complete_skips_all_in() {
    writeln("TEST: betting_complete skips all_in players");
    auto variant = new TexasHoldEm();
    Player[] players = make_players(3);
    players[0].matched = true;
    players[1].matched = true;
    players[2].matched = false;
    players[2].all_in  = true;
    assert(variant.betting_complete(players));
    writeln("  PASSED");
}

void test_betting_complete_empty_table() {
    writeln("TEST: betting_complete returns true with no active players");
    auto variant = new TexasHoldEm();
    Player[] players = make_players(3);
    foreach(p; players) p.folded = true;
    assert(variant.betting_complete(players));
    writeln("  PASSED");
}

void test_betting_complete_all_null() {
    writeln("TEST: betting_complete returns true when all seats are null");
    auto variant = new TexasHoldEm();
    Player[] players = [null, null, null];
    assert(variant.betting_complete(players));
    writeln("  PASSED");
}

void test_betting_complete_only_one_active() {
    writeln("TEST: betting_complete with only one active player");
    auto variant = new TexasHoldEm();
    Player[] players = make_players(3);
    players[0].matched = true;
    players[1].folded  = true;
    players[2].folded  = true;
    assert(variant.betting_complete(players));
    writeln("  PASSED");
}

void test_betting_complete_mixed_null_and_folded() {
    writeln("TEST: betting_complete skips mix of null and folded");
    auto variant = new TexasHoldEm();
    Player[] players = make_players(4);
    players[0] = null;
    players[1].folded  = true;
    players[2].matched = true;
    players[3].all_in  = true;
    assert(variant.betting_complete(players));
    writeln("  PASSED");
}

// ─── betting ──────────────────────────────────────────────────────────────────

void test_betting_fold() {
    writeln("TEST: betting sets folded = true on -1 return");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Player[] players = make_players(3, 1000);
    (cast(StubPlayer)players[0]).forced_return = -1;
    Card[] board;
    variant.betting(players, board, 100, 0, eval);
    assert(players[0].folded,        "Player should be folded");
    assert(players[0].stack == 1000, "Stack should be unchanged on fold");
    writeln("  PASSED");
}

void test_betting_call() {
    writeln("TEST: betting deducts call amount correctly");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Player[] players = make_players(3, 1000);
    players[1].round_bets = 20;
    (cast(StubPlayer)players[0]).forced_return = 20;
    Card[] board;
    variant.betting(players, board, 100, 0, eval);
    assert(players[0].stack      == 980, "Stack should be 980 after call");
    assert(players[0].round_bets == 20,  "round_bets should be 20");
    assert(players[0].matched,           "matched should be true after call");
    writeln("  PASSED");
}

void test_betting_raise_resets_others_matched() {
    writeln("TEST: raise resets other players matched flag");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Player[] players = make_players(3, 1000);
    players[1].matched = true;
    players[2].matched = true;
    (cast(StubPlayer)players[0]).forced_return = 100;
    Card[] board;
    variant.betting(players, board, 50, 0, eval);
    assert(!players[1].matched, "P1 matched should be reset after raise");
    assert(!players[2].matched, "P2 matched should be reset after raise");
    assert(players[0].matched,  "Raiser should be matched");
    writeln("  PASSED");
}

void test_betting_raise_does_not_reset_folded() {
    writeln("TEST: raise does not touch folded players matched flag");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Player[] players = make_players(3, 1000);
    players[1].matched = true;
    players[2].folded  = true;
    players[2].matched = false;
    (cast(StubPlayer)players[0]).forced_return = 100;
    Card[] board;
    variant.betting(players, board, 50, 0, eval);
    assert(players[2].folded, "Folded player should still be folded");
    writeln("  PASSED");
}

void test_betting_waiting_for_input() {
    writeln("TEST: betting does nothing on WAITING_FOR_INPUT (-69)");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Player[] players = make_players(3, 1000);
    (cast(StubPlayer)players[0]).forced_return = -69;
    long stack_before = players[0].stack;
    Card[] board;
    variant.betting(players, board, 100, 0, eval);
    assert(players[0].stack == stack_before, "Stack should be unchanged while waiting");
    assert(!players[0].folded,               "Should not be folded while waiting");
    assert(!players[0].matched,              "Should not be matched while waiting");
    writeln("  PASSED");
}

void test_betting_skips_null_player() {
    writeln("TEST: betting does nothing if player at current_turn is null");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Player[] players = make_players(3, 1000);
    players[0] = null;
    Card[] board;
    // should not crash
    variant.betting(players, board, 100, 0, eval);
    writeln("  PASSED");
}

void test_betting_skips_already_folded() {
    writeln("TEST: betting does nothing if current player is already folded");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Player[] players = make_players(3, 1000);
    players[0].folded = true;
    (cast(StubPlayer)players[0]).forced_return = 100;
    long stack_before = players[0].stack;
    Card[] board;
    variant.betting(players, board, 100, 0, eval);
    assert(players[0].stack == stack_before, "Folded player stack should be untouched");
    writeln("  PASSED");
}

void test_betting_skips_all_in_player() {
    writeln("TEST: betting does nothing if current player is all_in");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Player[] players = make_players(3, 1000);
    players[0].all_in = true;
    (cast(StubPlayer)players[0]).forced_return = 100;
    long stack_before = players[0].stack;
    Card[] board;
    variant.betting(players, board, 100, 0, eval);
    assert(players[0].stack == stack_before, "All-in player stack should be untouched");
    writeln("  PASSED");
}

void test_betting_check_zero_to_call() {
    writeln("TEST: betting check when toCall is 0 sets matched");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Player[] players = make_players(3, 1000);
    (cast(StubPlayer)players[0]).forced_return = 0; // check
    Card[] board;
    variant.betting(players, board, 0, 0, eval);
    assert(players[0].matched,          "Player should be matched after check");
    assert(players[0].stack == 1000,    "Stack should be unchanged after check");
    writeln("  PASSED");
}

void test_betting_raise_deducts_stack() {
    writeln("TEST: raise deducts correct amount from stack");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Player[] players = make_players(3, 1000);
    (cast(StubPlayer)players[0]).forced_return = 200;
    Card[] board;
    variant.betting(players, board, 100, 0, eval);
    assert(players[0].stack      == 800, "Stack should be 800 after 200 raise");
    assert(players[0].round_bets == 200, "round_bets should be 200");
    writeln("  PASSED");
}

// ─── advance signals ──────────────────────────────────────────────────────────

void test_advance_round0_returns_round_end_when_betting_complete() {
    writeln("TEST: round 0 returns ROUND_END when betting complete");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    variant.current_blind = 10;
    Deck d = make_deck();
    Player[] players = make_players(4, 1000);
    foreach(p; players) p.matched = true;
    Card[] board;
    size_t current_turn = 0;
    int signal = variant.advance(players, d, board, 0, 0, current_turn, eval);
    assert(signal == variant.Signal.ROUND_END, "Should return ROUND_END");
    writeln("  PASSED");
}

void test_advance_round1_returns_round_end_when_betting_complete() {
    writeln("TEST: round 1 returns ROUND_END when betting complete");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    variant.needs_setup = false; // skip setup
    Deck d = make_deck();
    Player[] players = make_players(4, 1000);
    foreach(p; players) p.matched = true;
    Card[] board;
    size_t current_turn = 0;
    int signal = variant.advance(players, d, board, 0, 1, current_turn, eval);
    assert(signal == variant.Signal.ROUND_END, "Round 1 should return ROUND_END");
    writeln("  PASSED");
}

void test_advance_round2_returns_round_end_when_betting_complete() {
    writeln("TEST: round 2 returns ROUND_END when betting complete");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    variant.needs_setup = false;
    Deck d = make_deck();
    Player[] players = make_players(4, 1000);
    foreach(p; players) p.matched = true;
    Card[] board;
    size_t current_turn = 0;
    int signal = variant.advance(players, d, board, 0, 2, current_turn, eval);
    assert(signal == variant.Signal.ROUND_END, "Round 2 should return ROUND_END");
    writeln("  PASSED");
}

void test_advance_round3_returns_round_end_when_betting_complete() {
    writeln("TEST: round 3 returns ROUND_END when betting complete");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    variant.needs_setup = false;
    Deck d = make_deck();
    Player[] players = make_players(4, 1000);
    foreach(p; players) p.matched = true;
    Card[] board;
    size_t current_turn = 0;
    int signal = variant.advance(players, d, board, 0, 3, current_turn, eval);
    assert(signal == variant.Signal.SHOWDOWN, "Round 3 should return SHOWDOWN");
    writeln("  PASSED");
}

void test_advance_default_returns_hand_end() {
    writeln("TEST: advance returns HAND_END on unknown round");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Deck d = make_deck();
    Player[] players = make_players(2, 1000);
    Card[] board;
    size_t current_turn = 0;
    int signal = variant.advance(players, d, board, 0, 99, current_turn, eval);
    assert(signal == variant.Signal.HAND_END, "Should return HAND_END for unknown round");
    writeln("  PASSED");
}

void test_advance_returns_continue_when_betting_incomplete() {
    writeln("TEST: advance returns CONTINUE when betting not complete");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    variant.current_blind = 10;
    variant.needs_setup = false;
    Deck d = make_deck();
    Player[] players = make_players(4, 1000);
    // nobody matched, player 0 just checks (returns 0)
    foreach(p; players) p.matched = false;
    (cast(StubPlayer)players[0]).forced_return = 0;
    Card[] board;
    size_t current_turn = 0;
    int signal = variant.advance(players, d, board, 0, 1, current_turn, eval);
    assert(signal == variant.Signal.CONTINUE, "Should return CONTINUE when betting incomplete");
    writeln("  PASSED");
}

// ─── advance setup ────────────────────────────────────────────────────────────

void test_advance_round1_deals_flop() {
    writeln("TEST: round 1 setup deals 3 cards to board");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Deck d = make_deck();
    Player[] players = make_players(4, 1000);
    foreach(p; players) p.matched = false;
    (cast(StubPlayer)players[0]).forced_return = 0;
    Card[] board;
    size_t current_turn = 0;
    variant.advance(players, d, board, 0, 1, current_turn, eval);
    assert(board.length == 3, "Flop should deal 3 cards");
    writeln("  PASSED");
}

void test_advance_round2_deals_one_card() {
    writeln("TEST: round 2 setup deals 1 card to board");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Deck d = make_deck();
    Player[] players = make_players(4, 1000);
    foreach(p; players) p.matched = false;
    (cast(StubPlayer)players[0]).forced_return = 0;
    Card[] board;
    size_t current_turn = 0;
    variant.advance(players, d, board, 0, 2, current_turn, eval);
    assert(board.length == 1, "Turn should deal 1 card");
    writeln("  PASSED");
}

void test_advance_round3_deals_one_card() {
    writeln("TEST: round 3 setup deals 1 card to board");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Deck d = make_deck();
    Player[] players = make_players(4, 1000);
    foreach(p; players) p.matched = false;
    (cast(StubPlayer)players[0]).forced_return = 0;
    Card[] board;
    size_t current_turn = 0;
    variant.advance(players, d, board, 0, 3, current_turn, eval);
    assert(board.length == 1, "River should deal 1 card");
    writeln("  PASSED");
}

void test_advance_round0_deals_hole_cards() {
    writeln("TEST: round 0 setup deals 2 hole cards to each player");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    variant.current_blind = 10;
    Deck d = make_deck();
    Player[] players = make_players(4, 1000);
    foreach(p; players) p.matched = false;
    (cast(StubPlayer)players[0]).forced_return = 0;
    Card[] board;
    size_t current_turn = 0;
    variant.advance(players, d, board, 0, 0, current_turn, eval);
    foreach(p; players)
        assert(p.hole.length == 2, "Each player should have 2 hole cards");
    writeln("  PASSED");
}

void test_advance_setup_only_runs_once_per_round() {
    writeln("TEST: setup only runs once, board doesnt grow on second call");
    auto variant = new TexasHoldEm();
    auto eval    = new StubEvaluator();
    Deck d = make_deck();
    Player[] players = make_players(4, 1000);
    foreach(p; players) p.matched = false;
    (cast(StubPlayer)players[0]).forced_return = 0;
    Card[] board;
    size_t current_turn = 0;
    variant.advance(players, d, board, 0, 1, current_turn, eval); // flop, deals 3
    size_t board_size_after_first = board.length;
    variant.advance(players, d, board, 0, 1, current_turn, eval); // second call, no redeal
    assert(board.length == board_size_after_first, "Board should not grow on second advance");
    writeln("  PASSED");
}

// ─── Runner ──────────────────────────────────────────────────────────────────

void texas_holdem_tester() {
    writeln("=== TexasHoldEm Tests ===\n");

    writeln("-- post_blinds --");
    test_post_blinds_deducts_correctly();
    test_post_blinds_skips_null_players();
    test_post_blinds_utg_correct_two_players();
    test_post_blinds_does_not_set_matched();
    test_post_blinds_large_blind();

    writeln("-- betting_complete --");
    test_betting_complete_all_matched();
    test_betting_complete_someone_unmatched();
    test_betting_complete_skips_folded();
    test_betting_complete_skips_all_in();
    test_betting_complete_empty_table();
    test_betting_complete_all_null();
    test_betting_complete_only_one_active();
    test_betting_complete_mixed_null_and_folded();

    writeln("-- betting --");
    test_betting_fold();
    test_betting_call();
    test_betting_raise_resets_others_matched();
    test_betting_raise_does_not_reset_folded();
    test_betting_waiting_for_input();
    test_betting_skips_null_player();
    test_betting_skips_already_folded();
    test_betting_skips_all_in_player();
    test_betting_check_zero_to_call();
    test_betting_raise_deducts_stack();

    writeln("-- advance signals --");
    test_advance_round0_returns_round_end_when_betting_complete();
    test_advance_round1_returns_round_end_when_betting_complete();
    test_advance_round2_returns_round_end_when_betting_complete();
    test_advance_round3_returns_round_end_when_betting_complete();
    test_advance_default_returns_hand_end();
    test_advance_returns_continue_when_betting_incomplete();

    writeln("-- advance setup --");
    test_advance_round0_deals_hole_cards();
    test_advance_round1_deals_flop();
    test_advance_round2_deals_one_card();
    test_advance_round3_deals_one_card();
    test_advance_setup_only_runs_once_per_round();

    writeln("\n=== All tests passed ===");
}