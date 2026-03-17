module main;

import std.stdio;
import std.algorithm;
import std.array;
import std.conv;
import std.random;
import std.string;
import raylib;

import card;
import deck;
import table;
import pot;
import players.player;
import players.computer_player;
import players.human_player;
import evaluators.standard_evaluator;
import variants.texas_hold_em;
import payouts.standard_payout;

import tests.standard_evaluater_tester_52;
import tests.standard_evaluator_tester_tarot;
import tests.texas_holdem_variant_tester;

alias Types = ComputerPlayer.Types;

struct PlayerTemplate {
    string name;
    Types  type;
    float  skill;
}

// ─── Card rendering ───────────────────────────────────────────────────────────

Texture2D uncut_card_sheet;
const int   spriteLength = 167;
const int   spriteHeight = 220;
const float renderScale  = 0.4f;

void DrawCardUI(int x, int y, Card c, bool hidden, bool grayed = false) {
    float drawW = spriteLength * renderScale;
    float drawH = spriteHeight * renderScale;
    Color tint  = grayed ? Color(100, 100, 100, 255) : Colors.WHITE;
    if (hidden) {
        DrawRectangle(x, y, cast(int)drawW, cast(int)drawH,
                      grayed ? Colors.DARKGRAY : Colors.DARKBLUE);
        DrawRectangleLines(x, y, cast(int)drawW, cast(int)drawH, Colors.RAYWHITE);
        return;
    }
    int rankCol = (c.rank == 14) ? 0 : c.rank - 1;
    int suitRow  = c.suit;
    Rectangle sourceRec = Rectangle(cast(float)(rankCol * spriteLength),
                                    cast(float)(suitRow  * spriteHeight),
                                    cast(float)spriteLength,
                                    cast(float)spriteHeight);
    Rectangle destRec   = Rectangle(cast(float)x, cast(float)y, drawW, drawH);
    DrawTexturePro(uncut_card_sheet, sourceRec, destRec, Vector2(0, 0), 0.0f, tint);
}

// ─── Layout ───────────────────────────────────────────────────────────────────

const int cx = 1280 / 2;
const int cy = 800  / 2;

Vector2[] chairPos = [
    Vector2(cx,       cy + 280),
    Vector2(cx - 350, cy + 220),
    Vector2(cx - 500, cy),
    Vector2(cx - 350, cy - 220),
    Vector2(cx,       cy - 280),
    Vector2(cx + 350, cy - 220),
    Vector2(cx + 500, cy),
    Vector2(cx + 350, cy + 220),
    Vector2(cx + 150, cy + 280),
];

// ─── Draw ─────────────────────────────────────────────────────────────────────

void draw(Table t, float sliderVal, long raiseAmount, string winnerText, bool showdown) {
    BeginDrawing();
    ClearBackground(Color(25, 35, 25, 255));
    DrawEllipse(cx, cy, 550, 300, Color(30, 80, 30, 255));

    if (showdown) {
        DrawText(toStringz(winnerText),
                 cx - (MeasureText(toStringz(winnerText), 32) / 2),
                 cy - 150, 32, Colors.GOLD);
    } else {
        string pTxt = "POT: $" ~ t.pot_total().to!string;
        DrawText(toStringz(pTxt),
                 cx - (MeasureText(toStringz(pTxt), 24) / 2),
                 cy - 110, 24, Colors.GOLD);
    }

    foreach (i, p; t.players) {
        if (p is null) continue;
        if (i >= chairPos.length) continue;

        int px = cast(int)chairPos[i].x;
        int py = cast(int)chairPos[i].y;

        bool folded = p.folded;

        if (t.current_turn == i && !showdown)
            DrawCircle(px, py, 45, Color(255, 255, 0, 100));

        // dealer button
        if (t.dealer_index == i)
            DrawCircle(px + 35, py - 35, 10, Colors.WHITE);

        DrawCircle(px, py, 30, folded ? Colors.DARKGRAY : Colors.MAROON);
        DrawText(toStringz(p.name),
                 px - (MeasureText(toStringz(p.name), 18) / 2),
                 py + 35, 18, folded ? Colors.GRAY : Colors.WHITE);
        DrawText(toStringz("$" ~ p.stack.to!string), px - 25, py + 55, 16, Colors.LIME);

        if (p.hole.length >= 2) {
            bool hideAI = (i != 0 && !showdown);
            DrawCardUI(px - 40, py - 100, p.hole[0], hideAI, folded);
            DrawCardUI(px + 5,  py - 100, p.hole[1], hideAI, folded);
        }
    }

    // board cards
    foreach (i, c; t.board_cards)
        DrawCardUI(cast(int)(cx - 180 + (i * 75)), cy - 44, c, false);

    // human controls
    Player cur = t.players[t.current_turn];
    if (!showdown && cur !is null && cast(HumanPlayer)cur !is null) {
        DrawRectangle(400, 710, 400, 10, Colors.GRAY);
        DrawCircle(400 + cast(int)(sliderVal * 400), 715, 12, Colors.GOLD);
        DrawText(toStringz("Raise: $" ~ raiseAmount.to!string), 550, 680, 20, Colors.WHITE);
        DrawText("[C] CALL/CHECK  [F] FOLD  [R] RAISE", cx - 180, 740, 20, Colors.YELLOW);
    } else if (showdown) {
        DrawText("PRESS [SPACE] FOR NEXT HAND", cx - 150, 740, 22, Colors.LIME);
    }

    EndDrawing();
}

// ─── Main ─────────────────────────────────────────────────────────────────────

int main() {
    // run tests first
    standard_evaluator_test_52();
    standard_evaluator_test_tarot();
    texas_holdem_tester();

    InitWindow(1280, 800, "D-Poker");
    SetTargetFPS(60);
    uncut_card_sheet = LoadTexture("./resources/cardSprites.png");

    // build modules
    Deck d = Deck.create_standard_52().shuffle_deck();
    auto eval    = new StandardEvaluator(2, 14, 4);
    auto variant = new TexasHoldEm();
    auto payouts = new StandardPayout();

    variant.current_blind = 10;

    auto t = new Table(d, eval, variant, payouts);

    // human player
    auto human  = new HumanPlayer("YOU", 1000);
    t.players  ~= human;

    // full roster, shuffle and pick 7
    PlayerTemplate[] roster = [
        PlayerTemplate("Riley",     Types.MANIAC,      0.9f),
        PlayerTemplate("Ryan",      Types.HOTHEAD,     0.8f),
        PlayerTemplate("Liv",       Types.NIT,         0.2f),
        PlayerTemplate("Hunter",    Types.STANDARD,    0.5f),
        PlayerTemplate("Cole",      Types.BULLY,       0.8f),
        PlayerTemplate("Chris",     Types.TILTER,      0.7f),
        PlayerTemplate("Blake",     Types.SHOWBOAT,    0.6f),
        PlayerTemplate("Johnny",    Types.MANIPULATOR, 0.5f),
        PlayerTemplate("John",      Types.CALLER,      0.3f),
        PlayerTemplate("Elijah",    Types.GAMBLER,     0.9f),
        PlayerTemplate("Parker",    Types.RANDOMIZER,  0.5f),
        PlayerTemplate("Poker God", Types.ABC,         1.0f),
    ];

    auto rng = Random(unpredictableSeed);
    randomShuffle(roster, rng);

    foreach (r; roster[0 .. 7]) {
        auto ai  = new ComputerPlayer(r.name, r.type, r.skill, 1000);
        t.players ~= ai;
    }

    t.dealer_index = 0;
    t.current_turn = 0;

    // UI state
    float  sliderVal   = 0.0f;
    long   raiseAmount = 0;
    float  aiTimer     = 0.0f;
    bool   showdown    = false;
    string winnerText  = "";

    while (!WindowShouldClose()) {

        // showdown screen — wait for space to start next hand
        if (showdown) {
            if (IsKeyPressed(KeyboardKey.KEY_SPACE)) {
                showdown   = false;
                winnerText = "";
                sliderVal  = 0.0f;
                aiTimer    = 0.0f;
            }
            draw(t, sliderVal, raiseAmount, winnerText, showdown);
            continue;
        }

        Player cur = t.players[t.current_turn];
        bool is_human = cur !is null && cast(HumanPlayer)cur !is null;

        // human input
        if (is_human) {
            // find current highest bet to calculate toCall
            long highest = 0;
            foreach (p; t.players)
                if (p !is null && p.round_bets > highest)
                    highest = p.round_bets;
            long already_bet = cur.round_bets;
            long to_call     = highest - already_bet;
            long min_raise   = highest * 2;
            if (min_raise == 0) min_raise = variant.current_blind * 2;

            // slider
            if (IsMouseButtonDown(MouseButton.MOUSE_BUTTON_LEFT)) {
                Vector2 m = GetMousePosition();
                if (m.y > 700 && m.y < 730 && m.x > 400 && m.x < 800)
                    sliderVal = (m.x - 400) / 400.0f;
            }
            raiseAmount = min_raise + cast(long)(sliderVal * (cur.stack - min_raise));
            if (raiseAmount > cur.stack) raiseAmount = cur.stack;
            if (raiseAmount < min_raise) raiseAmount = min_raise;

            auto hp = cast(HumanPlayer)cur;
            if (IsKeyPressed(KeyboardKey.KEY_C)) hp.submit_decision(to_call);
            if (IsKeyPressed(KeyboardKey.KEY_F)) hp.submit_decision(-1);
            if (IsKeyPressed(KeyboardKey.KEY_R)) hp.submit_decision(raiseAmount);
        }

        // AI delay
        aiTimer += GetFrameTime();
        bool ai_ready = !is_human && aiTimer > 0.8f;

        if (is_human || ai_ready) {
            int signal = t.update();
            if (ai_ready) aiTimer = 0.0f;

            if (signal == variant.Signal.SHOWDOWN || t.current_round > 3) {
                winnerText = "";
                foreach (pot; t.pots) {
                    foreach (w; pot.winners) {
                        if (winnerText.length > 0) winnerText ~= ", ";
                        winnerText ~= w.name ~ " WINS $" ~ pot.amount.to!string;
                    }
                }
                if (winnerText == "") winnerText = "No winners found";
                showdown = true;
            }
        }
        draw(t, sliderVal, raiseAmount, winnerText, showdown);
    }

    UnloadTexture(uncut_card_sheet);
    CloseWindow();
    return 0;
}