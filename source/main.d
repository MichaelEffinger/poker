module main;

import std.stdio;
import std.algorithm;
import std.array;
import deck;
import card;
import raylib;

int main() {

    InitWindow(1280,800,"main");

    Texture2D uncut_card_sheet = LoadTexture("./cardSprites.png");

    Texture2D herroGovna = LoadTexture("./govna.jpg");
    SetWindowOpacity(1);

    Texture2D chair = LoadTexture("./chair.png");

    int spriteLength = 167;
    int spriteHeight = 220;

    const int screenWidth = 800;
    const int screenHeight = 450;

    Vector2 ballPosition = { screenWidth/2, screenHeight/2 };   
    Vector2 rileyPosition = {screenWidth/2 +5, screenHeight/2 + 20};



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
        DrawText("move the ball with arrow keys", 10,10,20, Colors.DARKGRAY);
        DrawCircleV(rileyPosition,300,Colors.ORANGE);
        DrawCircleV(ballPosition, 50, Colors.BLUE);

        if(CheckCollisionCircles(ballPosition,50,rileyPosition, 300)){
            DrawText("Im Fat, Let Me eat you", screenWidth/2,screenWidth/2,20, Colors.DARKGRAY);
        }

        // DrawTextureEx(herroGovna,Vector2(0,0),0,1.6,Colors.WHITE);




        
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




