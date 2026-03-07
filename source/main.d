module main;

import std.stdio;
import std.algorithm;
import std.array;
import deck;
import card;
import raylib;
import player;

alias Types = Player.Types;

void DrawTextureCentered(Texture2D tex,float x,float y,float scale,float rotation, Color thecolor){
    Rectangle dest = Rectangle(x, y,tex.width * scale,tex.height * scale);

    Vector2 origin = Vector2(tex.width * scale / 2,tex.height * scale / 2);

    DrawTexturePro(tex,Rectangle(0, 0, tex.width, tex.height),dest,origin,rotation,thecolor);
}

int main() {

    Player[] players = [
        new Player("Riley", Types.MANIAC, 0.3),
        new Player("Ryan", Types.HOTHEAD, 0.6),
        new Player("Liv", Types.NITPICKER, 0.6),
        new Player("Hunter", Types.STANDARD, 0.5),
        new Player("Cole", Types.BULLY, 0.7),
        new Player("Chris", Types.TILTER, 0.3),
        new Player("Blake", Types.SHOWBOAT, 0.4),
        new Player("Johnny", Types.MANIPULATOR, 0.6),
        new Player("John", Types.CALLER, 0.5),
        new Player("Elijah", Types.GAMBLER, 0.5),
        new Player("Parker", Types.RANDOMIZER, 0.3),
        new Player("Poker God", Types.ABC, 0.9)
    ];


    InitWindow(1280,800,"main");

    Texture2D uncut_card_sheet = LoadTexture("./cardSprites.png");

    Texture2D herroGovna = LoadTexture("./govna.jpg");
    SetWindowOpacity(1);

    Texture2D chair = LoadTexture("./chair.png");

    Texture2D table = LoadTexture("./table.png");

    int spriteLength = 167;
    int spriteHeight = 220;

    const int screenWidth = 1280;
    const int screenHeight = 800;

    int cx = screenWidth/2;
    int cy = screenHeight/2;


    Vector2 ballPosition = {cx - 125, cast(int)( cy - 360 + (chair.height * 0.080))};

    SetTargetFPS(60);

    while(!WindowShouldClose()){


        if (IsKeyDown(KeyboardKey.KEY_RIGHT)) ballPosition.x += 2.0f;
        if (IsKeyDown(KeyboardKey.KEY_LEFT)) ballPosition.x -= 2.0f;
        if (IsKeyDown(KeyboardKey.KEY_UP)) ballPosition.y -= 2.0f;
        if (IsKeyDown(KeyboardKey.KEY_DOWN)) ballPosition.y += 2.0f;

        
        BeginDrawing();
        int suit = 0;
        int rank = 1;
        DrawTextureRec(uncut_card_sheet,Rectangle(spriteLength*(rank-1),spriteHeight*(suit-1),spriteLength,spriteHeight),Vector2(0,0), Colors.WHITE);

        ClearBackground(Color(120,120,120));

        DrawTextureCentered(table,cx,cy,1.25,180,Colors.WHITE);
        // Dealer (bottom center)
        DrawTextureCentered(chair, cx, cy + 200 + (chair.height*.080), .2, 180, Colors.WHITE);
        DrawTextureCentered(chair, cx-125, cy - 360 + (chair.height*.080), .2, 0, Colors.WHITE);
        DrawTextureCentered(chair, cx+125, cy - 360 + (chair.height*.080), .2, 0, Colors.WHITE);
        // Right side (3)
        DrawTextureCentered(chair, cx + 375, cy - 205, .2, 45, Colors.WHITE);
        DrawTextureCentered(chair, cx + 450, cy, .2, 90, Colors.WHITE);
        DrawTextureCentered(chair, cx + 375, cy + 205, .2, 135, Colors.WHITE);

        // Left side (3)
        DrawTextureCentered(chair, cx - 375, cy - 205, .2, 315, Colors.WHITE);
        DrawTextureCentered(chair, cx - 450, cy, .2, 270, Colors.WHITE);
        DrawTextureCentered(chair, cx - 375, cy + 205, .2, 225, Colors.WHITE);


        // Player stick heads (circles) at each chair
        DrawCircle(cx, cast(int)(cy + 200 + (chair.height * 0.080)), 40, Colors.BLACK);        // Dealer
        DrawCircle(cast(int)(ballPosition.x), cast(int)(ballPosition.y), 40, Colors.BLUE); // Left top
        DrawCircle(cx + 125, cast(int)(cy - 360 + (chair.height * 0.080)), 60, Colors.GREEN);// Right top

        // Right side
        DrawCircle(cx + 375, cy - 205, 40, Colors.ORANGE);
        DrawCircle(cx + 450, cy, 40, Colors.PURPLE);
        DrawCircle(cx + 375, cy + 205, 40, Colors.YELLOW);

        // Left side
        DrawCircle(cx - 375, cy - 205, 40, Colors.RED);
        DrawCircle(cx - 450, cy, 40, Colors.PINK);
        DrawCircle(cx - 375, cy + 205, 40, Colors.BROWN);



        EndDrawing();
    }

    Deck myDeck = Deck.create_standard_52();

    Deck* newdeck = new Deck;

    foreach(d; myDeck.deck){
        writeln(d.rank, " of ", myDeck.suit_names[d.suit]);
    }
     myDeck.shuffle_deck();
    foreach(d; myDeck.deck){
        writeln(d.rank, " of ", myDeck.suit_names[d.suit]);
    }
    return 0;
}




