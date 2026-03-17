module tests.table_tester;

import std.stdio;
import std.conv : to;
import std.algorithm : canFind;
import table;
import pot;
import card;
import deck;
import players.player;
import evaluators.evaluator;
import variants.poker_variant;
import payouts.payout_structure;

// ─── Stubs ───────────────────────────────────────────────────────────────────

int t_passed = 0;
int t_failed = 0;

void t_check(string name, bool condition, string detail = "") {
    if (condition) {
        writefln("  PASS: %s", name);
        t_passed++;
    } else {
        if (detail.length > 0)
            writefln("  FAIL: %s  (%s)", name, detail);
        else
            writefln("  FAIL: %s", name);
        t_failed++;
    }
}

class StubEvaluator : Evaluator {
    int forced_score = 100;
    override int opCall(const Card[] board, const Card[] hole) {
        return forced_score;
    }
}

// evaluator that returns a unique score per player based on hole card rank
class RankedEvaluator : Evaluator {
    override int opCall(const Card[] board, const Card[] hole) {
        if (hole.length == 0) return 0;
        return hole[0].rank * 1000;
    }
}

class StubPlayer : Player {
    long forced_return;
    this(string n, long stack_, long ret = 0) {
        name = n; stack = stack_; forced_return = ret;
    }
    override long take_turn(Card[] board, long pot, long toCall,
                            size_t players_in, Evaluator eval) {
        return forced_return;
    }
}

class StubVariant : PokerVariant {
    int next_signal = Signal.CONTINUE;
    override int advance(Player[] players, Deck deck, ref Card[] board,
                         long pot, size_t current_round, ref size_t current_turn,
                         Evaluator eval) {
        return next_signal;
    }
}

class StubPayout : PayoutStructure {
    bool was_called = false;
    Pot[] received_pots;
    override void distribute(Pot[] pots) {
        was_called = true;
        received_pots = pots;
        foreach(pot; pots) {
            if(pot.winners.length == 0) continue;
            long share = pot.amount / pot.winners.length;
            long remainder = pot.amount % pot.winners.length;
            foreach(w; pot.winners) w.stack += share;
            if(remainder > 0) pot.winners[0].stack += remainder;
        }
    }
}

Player[] make_players(int count, long stack = 1000, long ret = 0) {
    Player[] players;
    foreach(i; 0..count)
        players ~= new StubPlayer("P" ~ to!string(i), stack, ret);
    return players;
}

Table make_table(PokerVariant variant = null, Evaluator eval = null,
                 StubPayout payout = null) {
    if (variant is null) variant = new StubVariant();
    if (eval    is null) eval    = new StubEvaluator();
    if (payout  is null) payout  = new StubPayout();
    Deck d = Deck.create_standard_52().shuffle_deck();
    return new Table(d, eval, variant, payout);
}

// ─── update / signal handling ────────────────────────────────────────────────

void test_update_returns_minus1_with_no_players() {
    auto t = make_table();
    t_check("update returns -1 with no players", t.update() == -1);
}

void test_update_returns_0_normally() {
    auto t = make_table();
    t.players = make_players(2);
    t_check("update returns 0 normally", t.update() == 0);
}

void test_continue_advances_turn() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.CONTINUE;
    auto t = make_table(variant);
    t.players = make_players(4);
    t.current_turn = 0;
    t.update();
    t_check("CONTINUE advances current_turn", t.current_turn != 0,
            "turn=" ~ t.current_turn.to!string);
}

void test_continue_advances_turn_multiple_times() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.CONTINUE;
    auto t = make_table(variant);
    t.players = make_players(4);
    t.current_turn = 0;
    t.update(); // -> 1
    t.update(); // -> 2
    t.update(); // -> 3
    t_check("CONTINUE advances turn through multiple calls",
            t.current_turn == 3, "turn=" ~ t.current_turn.to!string);
}

void test_continue_skips_folded_on_advance() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.CONTINUE;
    auto t = make_table(variant);
    t.players = make_players(4);
    t.players[1].folded = true;
    t.current_turn = 0;
    t.update();
    t_check("CONTINUE skips folded player when advancing",
            t.current_turn == 2, "turn=" ~ t.current_turn.to!string);
}

void test_continue_skips_null_on_advance() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.CONTINUE;
    auto t = make_table(variant);
    t.players = make_players(4);
    t.players[1] = null;
    t.current_turn = 0;
    t.update();
    t_check("CONTINUE skips null seat when advancing",
            t.current_turn == 2, "turn=" ~ t.current_turn.to!string);
}

void test_waiting_does_not_advance_turn() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.WAITING;
    auto t = make_table(variant);
    t.players = make_players(4);
    t.current_turn = 1;
    t.update();
    t_check("WAITING does not advance turn", t.current_turn == 1,
            "turn=" ~ t.current_turn.to!string);
}

void test_waiting_multiple_times_stays_on_same_player() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.WAITING;
    auto t = make_table(variant);
    t.players = make_players(4);
    t.current_turn = 2;
    t.update();
    t.update();
    t.update();
    t_check("WAITING stays on same player after multiple calls",
            t.current_turn == 2, "turn=" ~ t.current_turn.to!string);
}

void test_round_end_increments_round() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.ROUND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    t.update();
    t_check("ROUND_END increments current_round",
            t.current_round == 1, "round=" ~ t.current_round.to!string);
}

void test_round_end_increments_round_twice() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.ROUND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    t.update();
    t.update();
    t_check("ROUND_END increments round correctly on second call",
            t.current_round == 2, "round=" ~ t.current_round.to!string);
}

void test_round_end_resets_needs_setup() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.ROUND_END;
    variant.needs_setup = false;
    auto t = make_table(variant);
    t.players = make_players(3);
    t.update();
    t_check("ROUND_END resets variant.needs_setup", variant.needs_setup);
}

void test_round_end_resets_matched() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.ROUND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    foreach(p; t.players) p.matched = true;
    t.update();
    foreach(i, p; t.players)
        t_check("ROUND_END resets matched on P" ~ to!string(i), !p.matched);
}

void test_round_end_resets_round_bets() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.ROUND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    foreach(p; t.players) p.round_bets = 50;
    t.update();
    foreach(i, p; t.players)
        t_check("ROUND_END resets round_bets on P" ~ to!string(i),
                p.round_bets == 0, "round_bets=" ~ p.round_bets.to!string);
}

void test_round_end_does_not_clear_board() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.ROUND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    t.board_cards = [Card(0,14), Card(1,13), Card(2,12)];
    t.update();
    t_check("ROUND_END does NOT clear board cards",
            t.board_cards.length == 3,
            "length=" ~ t.board_cards.length.to!string);
}

void test_round_end_moves_turn_to_after_dealer() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.ROUND_END;
    auto t = make_table(variant);
    t.players = make_players(4);
    t.dealer_index = 0;
    t.current_turn = 3;
    t.update();
    t_check("ROUND_END sets turn to player after dealer",
            t.current_turn == 1, "turn=" ~ t.current_turn.to!string);
}

void test_round_end_creates_pots_from_bets() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.ROUND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    foreach(p; t.players) p.round_bets = 100;
    t.update();
    t_check("ROUND_END creates pots from round_bets",
            t.pots.length > 0, "pots=" ~ t.pots.length.to!string);
    t_check("ROUND_END pot amount is correct",
            t.pot_total() == 300, "total=" ~ t.pot_total().to!string);
}

void test_showdown_calls_payout() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.SHOWDOWN;
    auto payout = new StubPayout();
    auto t = make_table(variant, null, payout);
    t.players = make_players(3);
    t.update();
    t_check("SHOWDOWN calls payout.distribute", payout.was_called);
}

void test_showdown_does_not_clear_board() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.SHOWDOWN;
    auto t = make_table(variant);
    t.players = make_players(3);
    t.board_cards = [Card(0,14), Card(1,13), Card(2,12)];
    t.update();
    t_check("SHOWDOWN does not clear board",
            t.board_cards.length == 3);
}

void test_showdown_does_not_advance_turn() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.SHOWDOWN;
    auto t = make_table(variant);
    t.players = make_players(3);
    t.current_turn = 2;
    t.update();
    t_check("SHOWDOWN does not advance turn",
            t.current_turn == 2, "turn=" ~ t.current_turn.to!string);
}

void test_showdown_distributes_to_winner() {
    auto variant  = new StubVariant();
    variant.next_signal = variant.Signal.SHOWDOWN;
    auto eval   = new RankedEvaluator();
    auto payout = new StubPayout();
    auto t = make_table(variant, eval, payout);
    t.players = make_players(3, 1000);

    // give each player a different hole card so evaluator can rank them
    t.players[0].hole = [Card(0, 14)]; // ace — wins
    t.players[1].hole = [Card(0, 10)];
    t.players[2].hole = [Card(0,  7)];

    Pot p;
    foreach(pl; t.players) p.eligible ~= pl;
    p.amount = 300;
    t.pots ~= p;

    t.update();
    t_check("SHOWDOWN distributes pot to highest ranked player",
            t.players[0].stack == 1300,
            "stack=" ~ t.players[0].stack.to!string);
}

void test_hand_end_clears_board() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.HAND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    t.board_cards = [Card(0,14), Card(1,13), Card(2,12)];
    t.update();
    t_check("HAND_END clears board_cards", t.board_cards.length == 0,
            "length=" ~ t.board_cards.length.to!string);
}

void test_hand_end_clears_pots() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.HAND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    Pot p; p.amount = 100;
    t.pots ~= p;
    t.update();
    t_check("HAND_END clears pots", t.pots.length == 0,
            "length=" ~ t.pots.length.to!string);
}

void test_hand_end_resets_current_round() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.HAND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    t.current_round = 3;
    t.update();
    t_check("HAND_END resets current_round to 0", t.current_round == 0,
            "current_round=" ~ t.current_round.to!string);
}

void test_hand_end_clears_hole_cards() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.HAND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    foreach(p; t.players) p.hole = [Card(0,14), Card(1,13)];
    t.update();
    foreach(i, p; t.players)
        t_check("HAND_END clears hole cards on P" ~ to!string(i),
                p.hole.length == 0);
}

void test_hand_end_resets_folded() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.HAND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    foreach(p; t.players) p.folded = true;
    t.update();
    foreach(i, p; t.players)
        t_check("HAND_END resets folded on P" ~ to!string(i), !p.folded);
}

void test_hand_end_resets_all_in() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.HAND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    foreach(p; t.players) p.all_in = true;
    t.update();
    foreach(i, p; t.players)
        t_check("HAND_END resets all_in on P" ~ to!string(i), !p.all_in);
}

void test_hand_end_resets_matched() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.HAND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    foreach(p; t.players) p.matched = true;
    t.update();
    foreach(i, p; t.players)
        t_check("HAND_END resets matched on P" ~ to!string(i), !p.matched);
}

void test_hand_end_resets_round_bets() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.HAND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    foreach(p; t.players) p.round_bets = 100;
    t.update();
    foreach(i, p; t.players)
        t_check("HAND_END resets round_bets on P" ~ to!string(i),
                p.round_bets == 0);
}

void test_hand_end_rotates_dealer() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.HAND_END;
    auto t = make_table(variant);
    t.players = make_players(4);
    t.dealer_index = 0;
    t.current_turn = 0;
    t.update();
    t_check("HAND_END rotates dealer_index", t.dealer_index != 0,
            "dealer=" ~ t.dealer_index.to!string);
}

void test_hand_end_skips_null_players() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.HAND_END;
    auto t = make_table(variant);
    t.players = make_players(3);
    t.players[1] = null;
    // should not crash
    t.update();
    t_check("HAND_END does not crash with null player slots", true);
}

void test_hand_end_resets_needs_setup() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.HAND_END;
    variant.needs_setup = false;
    auto t = make_table(variant);
    t.players = make_players(3);
    t.update();
    t_check("HAND_END resets variant.needs_setup", variant.needs_setup);
}

// ─── pot_total ────────────────────────────────────────────────────────────────

void test_pot_total_empty() {
    auto t = make_table();
    t_check("pot_total returns 0 with no pots", t.pot_total() == 0);
}

void test_pot_total_single_pot() {
    auto t = make_table();
    Pot p; p.amount = 150;
    t.pots ~= p;
    t_check("pot_total returns correct single pot amount",
            t.pot_total() == 150, "got=" ~ t.pot_total().to!string);
}

void test_pot_total_multiple_pots() {
    auto t = make_table();
    Pot p1; p1.amount = 100;
    Pot p2; p2.amount = 200;
    Pot p3; p3.amount = 50;
    t.pots ~= p1; t.pots ~= p2; t.pots ~= p3;
    t_check("pot_total sums multiple pots correctly",
            t.pot_total() == 350, "got=" ~ t.pot_total().to!string);
}

void test_pot_total_zero_amount_pot() {
    auto t = make_table();
    Pot p; p.amount = 0;
    t.pots ~= p;
    t_check("pot_total handles zero amount pot", t.pot_total() == 0);
}

void test_pot_total_large_values() {
    auto t = make_table();
    Pot p1; p1.amount = 100_000;
    Pot p2; p2.amount = 250_000;
    t.pots ~= p1; t.pots ~= p2;
    t_check("pot_total handles large chip values",
            t.pot_total() == 350_000, "got=" ~ t.pot_total().to!string);
}

// ─── create_pots ─────────────────────────────────────────────────────────────

void test_create_pots_simple() {
    auto t = make_table();
    t.players = make_players(3);
    foreach(p; t.players) p.round_bets = 100;
    t.create_pots();
    t_check("create_pots creates one pot when all bets equal",
            t.pots.length == 1, "pots=" ~ t.pots.length.to!string);
    t_check("create_pots pot amount is correct",
            t.pots[0].amount == 300, "amount=" ~ t.pots[0].amount.to!string);
}

void test_create_pots_clears_round_bets() {
    auto t = make_table();
    t.players = make_players(3);
    foreach(p; t.players) p.round_bets = 100;
    t.create_pots();
    foreach(i, p; t.players)
        t_check("create_pots zeroes round_bets on P" ~ to!string(i),
                p.round_bets == 0);
}

void test_create_pots_no_bets_creates_no_pots() {
    auto t = make_table();
    t.players = make_players(3);
    t.create_pots();
    t_check("create_pots creates no pots when no bets",
            t.pots.length == 0, "pots=" ~ t.pots.length.to!string);
}

void test_create_pots_side_pot() {
    auto t = make_table();
    t.players = make_players(3);
    t.players[0].round_bets = 50;
    t.players[0].all_in     = true;
    t.players[1].round_bets = 100;
    t.players[2].round_bets = 100;
    t.create_pots();
    t_check("create_pots creates two pots for all-in scenario",
            t.pots.length == 2, "pots=" ~ t.pots.length.to!string);
    t_check("create_pots main pot amount correct",
            t.pots[0].amount == 150, "main=" ~ t.pots[0].amount.to!string);
    t_check("create_pots side pot amount correct",
            t.pots[1].amount == 100, "side=" ~ t.pots[1].amount.to!string);
}

void test_create_pots_side_pot_eligible() {
    auto t = make_table();
    t.players = make_players(3);
    t.players[0].round_bets = 50;
    t.players[0].all_in     = true;
    t.players[1].round_bets = 100;
    t.players[2].round_bets = 100;
    t.create_pots();
    // all three eligible for main pot, only p1 and p2 for side pot
    t_check("create_pots main pot has 3 eligible players",
            t.pots[0].eligible.length == 3,
            "eligible=" ~ t.pots[0].eligible.length.to!string);
    t_check("create_pots side pot has 2 eligible players",
            t.pots[1].eligible.length == 2,
            "eligible=" ~ t.pots[1].eligible.length.to!string);
}

void test_create_pots_folded_not_eligible() {
    auto t = make_table();
    t.players = make_players(3);
    t.players[0].round_bets = 100;
    t.players[0].folded     = true;
    t.players[1].round_bets = 100;
    t.players[2].round_bets = 100;
    t.create_pots();
    t_check("folded player not in pot eligible list",
            !t.pots[0].eligible.canFind(t.players[0]));
}

void test_create_pots_two_players_one_folds() {
    auto t = make_table();
    t.players = make_players(2);
    t.players[0].round_bets = 100;
    t.players[0].folded = true;
    t.players[1].round_bets = 100;
    t.create_pots();
    t_check("create_pots correct with one folded player",
            t.pots.length == 1);
    t_check("folded player not eligible in two player fold scenario",
            !t.pots[0].eligible.canFind(t.players[0]));
}

void test_create_pots_preserves_conservation() {
    // total chips before == total chips in pots
    auto t = make_table();
    t.players = make_players(4);
    t.players[0].round_bets = 50;
    t.players[1].round_bets = 100;
    t.players[2].round_bets = 100;
    t.players[3].round_bets = 75;
    t.create_pots();
    long total = 0;
    foreach(pot; t.pots) total += pot.amount;
    t_check("create_pots conserves total chips",
            total == 325, "total=" ~ total.to!string);
}

// ─── find_and_set_winners ─────────────────────────────────────────────────────

void test_find_winners_tie() {
    auto eval = new StubEvaluator();
    auto t = make_table(null, eval);
    t.players = make_players(3);
    Pot p;
    foreach(pl; t.players) p.eligible ~= pl;
    p.amount = 300;
    t.pots ~= p;
    t.find_and_set_winners();
    t_check("find_and_set_winners all players tie",
            t.pots[0].winners.length == 3,
            "winners=" ~ t.pots[0].winners.length.to!string);
}

void test_find_winners_clear_previous_winners() {
    auto eval = new StubEvaluator();
    auto t = make_table(null, eval);
    t.players = make_players(2);
    Pot p;
    foreach(pl; t.players) p.eligible ~= pl;
    p.winners ~= t.players[0]; // pre-existing winner
    p.amount = 200;
    t.pots ~= p;
    t.find_and_set_winners();
    // stub returns same score for all so should be 2 winners not 1
    t_check("find_and_set_winners clears previous winners before recalculating",
            t.pots[0].winners.length == 2,
            "winners=" ~ t.pots[0].winners.length.to!string);
}

void test_find_winners_single_winner_by_rank() {
    auto eval = new RankedEvaluator();
    auto t = make_table(null, eval);
    t.players = make_players(3, 1000);
    t.players[0].hole = [Card(0, 14)]; // ace - wins
    t.players[1].hole = [Card(0, 10)];
    t.players[2].hole = [Card(0,  7)];
    Pot p;
    foreach(pl; t.players) p.eligible ~= pl;
    p.amount = 300;
    t.pots ~= p;
    t.find_and_set_winners();
    t_check("find_and_set_winners picks highest ranked player",
            t.pots[0].winners.length == 1 &&
            t.pots[0].winners[0] == t.players[0],
            "winners=" ~ t.pots[0].winners.length.to!string);
}

void test_find_winners_multiple_pots() {
    auto eval = new RankedEvaluator();
    auto t = make_table(null, eval);
    t.players = make_players(3, 1000);
    t.players[0].hole = [Card(0, 14)];
    t.players[1].hole = [Card(0, 10)];
    t.players[2].hole = [Card(0,  7)];

    Pot main_pot;
    foreach(pl; t.players) main_pot.eligible ~= pl;
    main_pot.amount = 150;

    Pot side_pot;
    side_pot.eligible ~= t.players[0];
    side_pot.eligible ~= t.players[1];
    side_pot.amount = 100;

    t.pots ~= main_pot;
    t.pots ~= side_pot;

    t.find_and_set_winners();
    t_check("find_and_set_winners handles multiple pots",
            t.pots[0].winners.length == 1 && t.pots[1].winners.length == 1);
}

// ─── next_turn ────────────────────────────────────────────────────────────────

void test_next_turn_basic() {
    auto t = make_table();
    t.players = make_players(4);
    t.current_turn = 0;
    size_t next = t.next_turn(0);
    t_check("next_turn advances to next seat", next == 1,
            "got=" ~ next.to!string);
}

void test_next_turn_skips_null() {
    auto t = make_table();
    t.players = make_players(4);
    t.players[1] = null;
    t.current_turn = 0;
    size_t next = t.next_turn(0);
    t_check("next_turn skips null seats", next == 2,
            "got=" ~ next.to!string);
}

void test_next_turn_skips_folded() {
    auto t = make_table();
    t.players = make_players(4);
    t.players[1].folded = true;
    t.current_turn = 0;
    size_t next = t.next_turn(0);
    t_check("next_turn skips folded players", next == 2,
            "got=" ~ next.to!string);
}

void test_next_turn_skips_all_in() {
    auto t = make_table();
    t.players = make_players(4);
    t.players[1].all_in = true;
    t.current_turn = 0;
    size_t next = t.next_turn(0);
    t_check("next_turn skips all_in players", next == 2,
            "got=" ~ next.to!string);
}

void test_next_turn_wraps_around() {
    auto t = make_table();
    t.players = make_players(4);
    t.current_turn = 3;
    size_t next = t.next_turn(3);
    t_check("next_turn wraps around from last seat",
            next == 0, "got=" ~ next.to!string);
}

void test_next_turn_skips_multiple_in_a_row() {
    auto t = make_table();
    t.players = make_players(5);
    t.players[1].folded = true;
    t.players[2].folded = true;
    t.players[3] = null;
    t.current_turn = 0;
    size_t next = t.next_turn(0);
    t_check("next_turn skips multiple consecutive inactive seats",
            next == 4, "got=" ~ next.to!string);
}

void test_next_turn_returns_start_when_all_inactive() {
    auto t = make_table();
    t.players = make_players(3);
    t.players[1].folded = true;
    t.players[2].folded = true;
    t.current_turn = 0;
    size_t next = t.next_turn(0);
    t_check("next_turn returns start when no other active players",
            next == 0, "got=" ~ next.to!string);
}

void test_next_turn_empty_table() {
    auto t = make_table();
    t.players = [];
    size_t next = t.next_turn(0);
    t_check("next_turn returns 0 with empty table", next == 0);
}

// ─── clean_bankrupt ───────────────────────────────────────────────────────────

void test_clean_bankrupt_removes_busted_player() {
    auto t = make_table();
    t.players = make_players(3);
    t.players[1].stack = 0;
    t.clean_bankrupt();
    t_check("clean_bankrupt nulls out busted player",
            t.players[1] is null);
}

void test_clean_bankrupt_keeps_solvent_players() {
    auto t = make_table();
    t.players = make_players(3);
    t.players[1].stack = 0;
    t.clean_bankrupt();
    t_check("clean_bankrupt keeps P0 with stack", t.players[0] !is null);
    t_check("clean_bankrupt keeps P2 with stack", t.players[2] !is null);
}

void test_clean_bankrupt_skips_null_seats() {
    auto t = make_table();
    t.players = make_players(3);
    t.players[1] = null;
    t.clean_bankrupt();
    t_check("clean_bankrupt does not crash on null seats", true);
}

void test_clean_bankrupt_removes_multiple_busted() {
    auto t = make_table();
    t.players = make_players(4);
    t.players[0].stack = 0;
    t.players[2].stack = 0;
    t.clean_bankrupt();
    t_check("clean_bankrupt removes P0", t.players[0] is null);
    t_check("clean_bankrupt removes P2", t.players[2] is null);
    t_check("clean_bankrupt keeps P1",   t.players[1] !is null);
    t_check("clean_bankrupt keeps P3",   t.players[3] !is null);
}

void test_clean_bankrupt_negative_stack() {
    auto t = make_table();
    t.players = make_players(3);
    t.players[1].stack = -50; // went negative somehow
    t.clean_bankrupt();
    t_check("clean_bankrupt removes player with negative stack",
            t.players[1] is null);
}

void test_clean_bankrupt_keeps_one_chip() {
    auto t = make_table();
    t.players = make_players(3);
    t.players[1].stack = 1;
    t.clean_bankrupt();
    t_check("clean_bankrupt keeps player with 1 chip",
            t.players[1] !is null);
}

// ─── showdown flow ───────────────────────────────────────────────────────────

// A variant that sequences through signals like a real hand:
// CONTINUE x N, then SHOWDOWN, then HAND_END
class SequenceVariant : PokerVariant {
    int[] sequence;
    size_t index = 0;
    override int advance(Player[] players, Deck deck, ref Card[] board,
                         long pot, size_t current_round, ref size_t current_turn,
                         Evaluator eval) {
        if (index >= sequence.length) return Signal.HAND_END;
        return sequence[index++];
    }
}

void test_showdown_fires_after_sequence() {
    auto variant = new SequenceVariant();
    variant.sequence = [
        variant.Signal.CONTINUE,
        variant.Signal.CONTINUE,
        variant.Signal.SHOWDOWN
    ];
    auto payout = new StubPayout();
    auto t = make_table(variant, null, payout);
    t.players = make_players(3, 1000);

    t.update(); // CONTINUE
    t_check("showdown not fired yet after CONTINUE", !payout.was_called);
    t.update(); // CONTINUE
    t_check("showdown not fired yet after second CONTINUE", !payout.was_called);
    t.update(); // SHOWDOWN
    t_check("showdown fires after SHOWDOWN signal", payout.was_called);
}

void test_hand_end_fires_after_showdown() {
    auto variant = new SequenceVariant();
    variant.sequence = [
        variant.Signal.SHOWDOWN,
        variant.Signal.HAND_END
    ];
    auto t = make_table(variant);
    t.players = make_players(3, 1000);
    t.current_round = 3;
    t.board_cards = [Card(0,14), Card(1,13), Card(2,12)];

    t.update(); // SHOWDOWN
    t_check("board still present after SHOWDOWN",
            t.board_cards.length == 3);
    t_check("round not reset after SHOWDOWN",
            t.current_round == 3, "round=" ~ t.current_round.to!string);

    t.update(); // HAND_END
    t_check("board cleared after HAND_END",
            t.board_cards.length == 0);
    t_check("round reset after HAND_END",
            t.current_round == 0);
}

void test_full_hand_sequence_state() {
    // simulate a full hand: 4 ROUND_ENDs then SHOWDOWN then HAND_END
    auto variant = new SequenceVariant();
    variant.sequence = [
        variant.Signal.ROUND_END, // preflop end
        variant.Signal.ROUND_END, // flop end
        variant.Signal.ROUND_END, // turn end
        variant.Signal.ROUND_END, // river end
        variant.Signal.SHOWDOWN,
        variant.Signal.HAND_END
    ];
    auto payout = new StubPayout();
    auto t = make_table(variant, null, payout);
    t.players = make_players(3, 1000);

    foreach(_; 0..4) t.update(); // four round ends
    t_check("round is 4 after four ROUND_ENDs",
            t.current_round == 4, "round=" ~ t.current_round.to!string);

    t.update(); // SHOWDOWN
    t_check("payout called at SHOWDOWN", payout.was_called);
    t_check("round still 4 at SHOWDOWN",
            t.current_round == 4);

    t.update(); // HAND_END
    t_check("round reset to 0 after HAND_END",
            t.current_round == 0);
    t_check("board cleared after full hand",
            t.board_cards.length == 0);
}

void test_showdown_winner_gets_chips() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.SHOWDOWN;
    auto eval   = new RankedEvaluator();
    auto payout = new StubPayout();
    auto t = make_table(variant, eval, payout);
    t.players = make_players(3, 1000);

    t.players[0].hole = [Card(0, 14)]; // ace wins
    t.players[1].hole = [Card(0,  9)];
    t.players[2].hole = [Card(0,  5)];

    Pot p;
    foreach(pl; t.players) p.eligible ~= pl;
    p.amount = 300;
    t.pots ~= p;

    long before = t.players[0].stack;
    t.update();
    t_check("winner stack increased after showdown",
            t.players[0].stack > before,
            "before=" ~ before.to!string ~ " after=" ~ t.players[0].stack.to!string);
    t_check("winner received correct amount",
            t.players[0].stack == 1300,
            "stack=" ~ t.players[0].stack.to!string);
}

void test_showdown_losers_dont_get_chips() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.SHOWDOWN;
    auto eval   = new RankedEvaluator();
    auto payout = new StubPayout();
    auto t = make_table(variant, eval, payout);
    t.players = make_players(3, 1000);

    t.players[0].hole = [Card(0, 14)];
    t.players[1].hole = [Card(0,  9)];
    t.players[2].hole = [Card(0,  5)];

    Pot p;
    foreach(pl; t.players) p.eligible ~= pl;
    p.amount = 300;
    t.pots ~= p;

    t.update();
    t_check("loser P1 stack unchanged",
            t.players[1].stack == 1000,
            "stack=" ~ t.players[1].stack.to!string);
    t_check("loser P2 stack unchanged",
            t.players[2].stack == 1000,
            "stack=" ~ t.players[2].stack.to!string);
}

void test_showdown_tie_splits_pot() {
    auto variant = new StubVariant();
    variant.next_signal = variant.Signal.SHOWDOWN;
    auto eval   = new StubEvaluator(); // all same score
    auto payout = new StubPayout();
    auto t = make_table(variant, eval, payout);
    t.players = make_players(2, 1000);

    Pot p;
    foreach(pl; t.players) p.eligible ~= pl;
    p.amount = 200;
    t.pots ~= p;

    t.update();
    t_check("tied player P0 gets half pot",
            t.players[0].stack == 1100,
            "stack=" ~ t.players[0].stack.to!string);
    t_check("tied player P1 gets half pot",
            t.players[1].stack == 1100,
            "stack=" ~ t.players[1].stack.to!string);
}

void test_showdown_then_hand_end_cleans_up() {
    auto variant = new SequenceVariant();
    variant.sequence = [variant.Signal.SHOWDOWN, variant.Signal.HAND_END];
    auto eval   = new StubEvaluator();
    auto payout = new StubPayout();
    auto t = make_table(variant, eval, payout);
    t.players = make_players(3, 1000);
    foreach(p; t.players) p.hole = [Card(0,14), Card(1,13)];
    t.board_cards = [Card(2,10), Card(3,9), Card(0,8)];

    Pot p;
    foreach(pl; t.players) p.eligible ~= pl;
    p.amount = 300;
    t.pots ~= p;

    t.update(); // SHOWDOWN
    t.update(); // HAND_END
    t_check("hole cards cleared after full showdown+hand_end",
            t.players[0].hole.length == 0);
    t_check("board cleared after full showdown+hand_end",
            t.board_cards.length == 0);
    t_check("pots cleared after full showdown+hand_end",
            t.pots.length == 0);
    t_check("round reset after full showdown+hand_end",
            t.current_round == 0);
}

// ─── Runner ──────────────────────────────────────────────────────────────────

void table_tester() {
    writeln("\n=== Table Tests ===\n");

    writeln("-- update / signal handling --");
    test_update_returns_minus1_with_no_players();
    test_update_returns_0_normally();
    test_continue_advances_turn();
    test_continue_advances_turn_multiple_times();
    test_continue_skips_folded_on_advance();
    test_continue_skips_null_on_advance();
    test_waiting_does_not_advance_turn();
    test_waiting_multiple_times_stays_on_same_player();
    test_round_end_increments_round();
    test_round_end_increments_round_twice();
    test_round_end_resets_needs_setup();
    test_round_end_resets_matched();
    test_round_end_resets_round_bets();
    test_round_end_does_not_clear_board();
    test_round_end_moves_turn_to_after_dealer();
    test_round_end_creates_pots_from_bets();
    test_showdown_calls_payout();
    test_showdown_does_not_clear_board();
    test_showdown_does_not_advance_turn();
    test_showdown_distributes_to_winner();
    test_hand_end_clears_board();
    test_hand_end_clears_pots();
    test_hand_end_resets_current_round();
    test_hand_end_clears_hole_cards();
    test_hand_end_resets_folded();
    test_hand_end_resets_all_in();
    test_hand_end_resets_matched();
    test_hand_end_resets_round_bets();
    test_hand_end_rotates_dealer();
    test_hand_end_skips_null_players();
    test_hand_end_resets_needs_setup();

    writeln("-- showdown flow --");
    test_showdown_fires_after_sequence();
    test_hand_end_fires_after_showdown();
    test_full_hand_sequence_state();
    test_showdown_winner_gets_chips();
    test_showdown_losers_dont_get_chips();
    test_showdown_tie_splits_pot();
    test_showdown_then_hand_end_cleans_up();

    writeln("-- pot_total --");
    test_pot_total_empty();
    test_pot_total_single_pot();
    test_pot_total_multiple_pots();
    test_pot_total_zero_amount_pot();
    test_pot_total_large_values();

    writeln("-- create_pots --");
    test_create_pots_simple();
    test_create_pots_clears_round_bets();
    test_create_pots_no_bets_creates_no_pots();
    test_create_pots_side_pot();
    test_create_pots_side_pot_eligible();
    test_create_pots_folded_not_eligible();
    test_create_pots_two_players_one_folds();
    test_create_pots_preserves_conservation();

    writeln("-- find_and_set_winners --");
    test_find_winners_tie();
    test_find_winners_clear_previous_winners();
    test_find_winners_single_winner_by_rank();
    test_find_winners_multiple_pots();

    writeln("-- next_turn --");
    test_next_turn_basic();
    test_next_turn_skips_null();
    test_next_turn_skips_folded();
    test_next_turn_skips_all_in();
    test_next_turn_wraps_around();
    test_next_turn_skips_multiple_in_a_row();
    test_next_turn_returns_start_when_all_inactive();
    test_next_turn_empty_table();

    writeln("-- clean_bankrupt --");
    test_clean_bankrupt_removes_busted_player();
    test_clean_bankrupt_keeps_solvent_players();
    test_clean_bankrupt_skips_null_seats();
    test_clean_bankrupt_removes_multiple_busted();
    test_clean_bankrupt_negative_stack();
    test_clean_bankrupt_keeps_one_chip();

    writeln("\n=== RESULTS ===");
    writefln("Passed: %d / %d", t_passed, t_passed + t_failed);
    if (t_failed > 0)
        writefln("Failed: %d", t_failed);
    else
        writeln("All tests passed!");
}