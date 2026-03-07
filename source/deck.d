module deck;

import std.random;
import std.exception : enforce;
import std.algorithm.mutation;
import card;


struct Deck {

    Card[] deck;
    string[] suit_names;
    size_t top;
    int rank_count;
    Random rng;

    this(string[] suits) {
        suit_names = suits;
        rng = Random(unpredictableSeed);
    }

    static Deck create_deck(string[] suits, int[] ranks){
        Deck temp_deck = Deck();
        temp_deck.suit_names = suits.dup;
        temp_deck.rank_count = cast(int) ranks.length;

        foreach (suitIndex, suit; suits) {
            foreach(r; ranks) {
                temp_deck.deck ~= Card(cast(int)suitIndex, r);
            }
        }

        return temp_deck;
    }

    Card draw_card() {
        enforce(top < deck.length, "Deck Empty");
        return deck[top++];
    }

    void burn_card() {
        enforce(top < deck.length, "Deck Empty");
        top++;
    }

    void remove(Card card){
        for(size_t i = top; i < deck.length; i++){
            if(card.rank == deck[i].rank && card.suit == deck[i].suit){
                swap(deck[top], deck[i]);
                top++;
            }
        }
    }

    void remove_cards(Card[] cards){
        foreach (c; cards){
            remove(c);
        }
    }

    ref Deck shuffle_deck() {
       randomShuffle(deck,rng);
        top = 0;  
        return this;
    }

    size_t size() const {
        return deck.length;
    }

    static Deck create_standard_52() {
        string[] suits = ["Spades", "Diamonds", "Clubs", "Hearts"];
        Deck temp_deck = Deck(suits);
        temp_deck.suit_names = suits;

        // Spades & Diamonds: Ace -> King
        foreach (s; 0 .. 2) {
            temp_deck.deck ~= Card(s, 14);
            foreach (r; 2 .. 14) {
                temp_deck.deck ~= Card(s, r);
            }
        }

        // Clubs & Hearts: King -> Ace
        foreach (s; 2 .. 4) {
            foreach_reverse(r; 2 .. 14) {
                temp_deck.deck ~= Card(s, r); 
            }
            temp_deck.deck ~= Card(s, 14); 
        }
        return temp_deck;
    }



}