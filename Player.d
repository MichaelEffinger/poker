module Player;

import card;
import std.math : abs;


class Player
{

	enum Types
	{
		NIT, // Extremely tight, rarely plays hands
		MANIAC, // Very loose and aggressive, bets wildly
		STANDARD, // Balanced, average play style
		TAG, // Tight-Aggressive, solid starting hands, aggressive when in
		LAG, // Loose-Aggressive, plays many hands aggressively
		CALLER, // Passive, calls a lot, rarely raises
		ROCK, // Very tight, almost never bluffs
		SHARK, // Skilled, adaptive, reads opponents well
		FISH, // Weak, makes poor decisions, easy to exploit
		ABC, // Follows standard textbook strategy without deviations
		MANIPULATOR, // Trappy, tries to lure players into bad situations
		RANDOMIZER, // Plays unpredictably, hard to read
	};

	// Personality factors 
	float aggression;
	float tightness;
	float bluff_frequency;
	float risk_tolerance;
	float adaptability;
	float tiltability;
	float patience;
	float trappiness;

	//Difficulty factors
	float skill;
	float positional_awareness;
	float board_awareness;
	float tiltResistance;


	long stack;
	int position;
	Card[2] hole;
	Cards[5]* board;

	static int evaluate_hand(Cards[] cards){
		int same_suit = 0;
		int distance_value = 0;
		int sum_value = 0;
		int is_pair = 0;
		switch (cards.length)
		{
		case 2:
			int hi = max(cards[0].rank, cards[1].rank);
			int lo = min(cards[0].rank, cards[1].rank);
			
			if (hi == lo) {
				return 45 + hi * 3;
			}
			
			sum_value = hi * 2 + lo;
			if (cards[0].suit == cards[1].suit)
				same_suit = 10000;
			int distance = hi - lo;
			if (distance < 4)
				distance_value = (14 - 4 * distance);
			break;
		case 5:
		case 6:
		case 7:
			// TODO: Implement postflop evaluation
			break;
		}
		return distance_value + sum_value + same_suit;
	}

	double calculate_pot_odds(long pot, long toCall){
		if (toCall <= 0)
			return 0.0;
		return cast(double) toCall / (pot + toCall);
	}

	double calculate_equity(Card[2] holeCards, Cards[5]* boardCards){
		// TODO: Implement equity calculation (Monte Carlo or approximate)
		return 0.5; // stub
	}

	bool bluff_decide(double potOdds, double perceivedEquity){
		// TODO: Implement bluffing logic based on personality
		return false; // stub
	}

	void decide_action(){
		// TODO: Implement AI logic for choosing action type (call, raise, fold)
	}

	long bet(){
		// TODO: Implement actual betting logic
		return 0; // stub
	}

	long calculate_raise_size(long pot, long toCall){
		// TODO: Implement raise sizing logic
		return toCall * 2; // stub
	}

	long calculate_call_amount(long toCall){
		// TODO: Implement exact call amount logic
		return toCall; // stub
	}




	long take_turn(long pot, long toCall){
		if (stack <= 0)
			return 0;

		double potOdds = calculate_pot_odds(pot, toCall);
		double equity = calculate_equity(hole, board);
		double perceivedEquity = equity * skill;

		bool profitableCall = perceivedEquity >= potOdds;
		bool bluffing = bluff_decide(potOdds, perceivedEquity);

		if (profitableCall){
			if (perceivedEquity > potOdds + 0.15 && aggression > 0.5)
				return calculate_raise_size(pot, toCall);
			return calculate_call_amount(toCall);
		}

		if (!profitableCall && bluffing)
			return calculate_raise_size(pot, toCall);

		// Fold
		return 0;
	}

	extern(c++){

		int ES_print();
		
		class funny;

	}

}

