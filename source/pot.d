module pot;
import players.player;

struct Pot{
    long amount;
    Player[] eligible;
    Player[] winners;
}