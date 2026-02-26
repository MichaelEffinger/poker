module deck;

import std.random : Random, uniform, shuffle, unperdicableSeed;
import std.exception : enforce;
import std.stdio : writeln;
import card;

class Deck {

    Card[] data_;
    string[] suit_names;
    size_t index;
    auto rng = random(unpredictableSeed);

public:

    static Deck create_deck(string[] suits, int[] ranks){
        Deck deck;
        deck.suit_names_ = suits;

        foreach (s, suit; suits) {
            foreach( r; ranks) {
                deck.data_ ~= Card(s,r);
            }
        }
        return deck;
    }

    
    Card draw_card() {
        enforce(index < data_.length, "Deck Empty");
        return data_[index++];
    }

    void burn_card() {
        enforce(index < data_.length, "Deck Empty");
        index++;
    }

    ref Deck shuffle_deck() {
        shuffle(data_, rng);
        index = 0;
        return this;
    }

    ref string suit_name(int suit_id) const {
        return suit_names_[suit_id];
    }

    size_t size() const {
        return data_.size();
    }


    
  static Deck createStandard52() {
        string[] suits = ["Spades", "Diamonds", "Clubs", "Hearts"];
        Deck deck = new Deck;
        deck.suit_names_ = suits.dup;

        // Spades & Diamonds: Ace -> King
        foreach (s; 0 .. 2) {
            deck.data_ ~= Card(s, 14);
            foreach (r; 2 .. 14) {
                deck.data_ ~= Card(s, r);
            }
        }

        // Clubs & Hearts: King -> Ace
        foreach (s; 2 .. 4) {
            foreach_reverse(r; 2 .. 14) {
                deck.data_ ~= Card(s, r); 
            }
            deck.data_ ~= Card(s, 14); 
        }
        return deck;
    }


    extern(c++){
       int println(int myInt);
    }

};