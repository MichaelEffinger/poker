module players.computer_player;

import card;
import std.math : abs;
import players.player;
import evaluators.evaluator;
import deck;
import hand_util;
import std.random;
import std.algorithm.comparison;

class ComputerPlayer : Player{

	enum Types
	{
		NIT,        // Extremely tight, rarely plays hands
		MANIAC,     // Very loose and aggressive, bets wildly
		STANDARD,   // Balanced, average play style
		TAG,        // Tight-Aggressive, solid starting hands, aggressive when in
		LAG,        // Loose-Aggressive, plays many hands aggressively
		CALLER,     // Passive, calls a lot, rarely raises
		ROCK,       // Very tight, almost never bluffs
		ABC,        // Follows standard textbook strategy without deviations
		MANIPULATOR,// Trappy, tries to lure players into bad situations
		RANDOMIZER, // Plays unpredictably, hard to read
		HOTHEAD,    // Reacts strongly to bad beats, tilt spikes fast
		STOIC,      // Emotionally flat, barely reacts to wins or losses
		SHOWBOAT,   // Plays for drama, loves big pots regardless of odds
		TRAPPER,    // Slow plays constantly, rarely shows aggression until the river
		BULLY,      // Uses stack size to pressure, raises frequently regardless of hand
		GRINDER,    // Extremely patient, waits for spots, hates variance
		TILTER,     // Already on tilt before the game starts, erratic
		COWARD,     // Folds to any significant pressure even with good hands
		GAMBLER,    // Addicted to action, risk tolerance through the roof
		SHORTSTACK, // Plays desperately, shoves frequently due to stack anxiety
		NITPICKER,  // Obsesses over small edges, overthinks every decision
	}


	this(string name_, Types type, float skill_, long stack_size) {
		
		name = name_;
		skill = skill_;
		board_awareness = clamp(skill + uniform(-0.1f, 0.1f), 0.0f, 1.0f);
		tilt_resistance = clamp(skill + uniform(-0.15f, 0.15f), 0.0f, 1.0f);
		sim_count = cast(size_t)(10 + (skill ^^ 2 * 4990));

		confidence = 0.5;
		tilt = 0.0;
		boredom = 0.0;
		suspicion = 0;
		set_personality(type);
		stack = stack_size;
	}


	private void set_personality(Types type){
		aggression = 0.5f;
        tightness = 0.5f;
        bluff_frequency = 0.15f;
        risk_tolerance = 0.5f;
        adaptability = 0.5f;
        patience = 0.5f;
        trappiness = 0.2f;

		switch(type){
			case Types.NIT:
				tightness = 0.9f;
            	aggression = 0.2f;
                bluff_frequency = 0.05f;
                patience = 0.9f;
                break;
			case Types.MANIAC:
                aggression = 0.95f;
                tightness = 0.1f;
                bluff_frequency = 0.6f;
                risk_tolerance = 0.9f;
                patience = 0.1f;
                break;
			case Types.STANDARD:
                // Uses defaults
                break;
			case Types.TAG:
                tightness = 0.7f;
                aggression = 0.8f;
                bluff_frequency = 0.3f;
                patience = 0.7f;
                break;
			case Types.LAG: 
                tightness = 0.3f;
                aggression = 0.85f;
                bluff_frequency = 0.5f;
                break;
			case Types.CALLER:
                aggression = 0.1f;
                risk_tolerance = 0.7f;
                bluff_frequency = 0.08f;
                break;
			case Types.ROCK:
                tightness = 0.95f;
                bluff_frequency = 0.0f;
                aggression = 0.3f;
                patience = 1.0f;
                break;
			case Types.ABC:
                tightness = 0.6f;
                aggression = 0.5f;
                bluff_frequency = 0.2f;
                adaptability = 0.2f;
                break;
            case Types.MANIPULATOR:
                trappiness = 0.9f;
                bluff_frequency = 0.5f;
                adaptability = 0.8f;
                break;
			case Types.RANDOMIZER:
				bluff_frequency = uniform(0.1f,0.9f);
				risk_tolerance = uniform(0.1f, 0.9f);
                aggression = uniform(0.1f, 0.9f);
                tightness = uniform(0.1f, 0.9f);
                break;
            case Types.HOTHEAD:
                tilt_resistance = 0.1f;
                aggression = 0.7f;
                patience = 0.2f;
                break;
			case Types.STOIC:
                tilt_resistance = 1.0f;
                patience = 0.8f;
                break;
            case Types.SHOWBOAT:
                risk_tolerance = 1.0f;
                aggression = 0.8f;
                bluff_frequency = 0.45f;
                break;
			case Types.TRAPPER:
                trappiness = 1.0f;
                aggression = 0.7f;
                break;
			case Types.BULLY:
                aggression = 1.0f;
                bluff_frequency = 0.4f;
                risk_tolerance = 0.8f;
                break;
            case Types.GRINDER:
                patience = 1.0f;
                tightness = 0.7f;
                tilt_resistance = 0.9f;
                break;
			case Types.TILTER:
                tilt = 0.6f;
                aggression = 0.8f;
                risk_tolerance = 0.9f;
                break;
            case Types.COWARD:
                risk_tolerance = 0.0f;
                tightness = 0.8f;
                aggression = 0.1f;
                break;
			case Types.GAMBLER:
                risk_tolerance = 1.0f;
                bluff_frequency = 0.5f;
                patience = 0.0f;
                break;
            case Types.SHORTSTACK:
                risk_tolerance = 0.9f;
                tightness = 0.4f;
                aggression = 0.9f;
                break;
            case Types.NITPICKER:
                patience = 0.9f;
                adaptability = 0.9f;
                tightness = 0.8f;
                break;
			default:
				break;
		}
	}

	// Personality factors 
	float aggression;
	float tightness;
	float bluff_frequency;
	float risk_tolerance;
	float adaptability;
	float patience;
	float trappiness;
	//Difficulty factors
	float skill;
	float board_awareness;
	size_t sim_count;
	float tilt_resistance;

	//Factors that change mid game
	float tilt;
	float confidence;
	float boredom;
	float suspicion;
	long sunk_cost;


	double calculate_pot_odds(long pot, long toCall){
		if (toCall <= 0)
			return 0.0;
		return cast(double) toCall / (pot + toCall);
	}

	int evaluate_starting_hand(Card[] cards) {
		int hi = max(cards[0].rank, cards[1].rank);
		int lo = min(cards[0].rank, cards[1].rank);
		
		if (hi == lo) return 45 + hi * 3;
		
		int score = (hi * 2) + lo;
		
		if (cards[0].suit == cards[1].suit) {
			score += 10 + cast(int)(30 * (1.0f - skill)); 
		}

		int distance = hi - lo;
		if (distance < 4) score += (14 - 4 * distance);
		
		return score;
	}

	bool should_play_preflop(int handScore, long toCall, long pot) {
		// 1. Determine base threshold based on tightness
		// High tightness (0.9) = high threshold (approx 65-70)
		// Low tightness (0.1) = low threshold (approx 30)
		float threshold = 25.0f + (effective_tightness() * 50.0f);

		threshold -= (boredom * 15.0f);

		// tolerance for risk. If the bet is small compared to the pot, we might as well gamble.... like riley
		double potOdds = calculate_pot_odds(pot, toCall);
		threshold *= (1.0f - (risk_tolerance * (1.0f - cast(float)potOdds)));

		return cast(float)handScore >= threshold;
	}


	void detect_overplay(long raiseAmount, long pot, bool isAllIn) {
		float pressure = cast(float)raiseAmount / (pot + 1);    
		if (isAllIn || pressure > 1.2f) {
			suspicion += (0.1f + (adaptability * 0.2f));
			suspicion = min(suspicion, 1.0f);
		}
	}

	void update_reputation() {
		if (suspicion > 0) {
			suspicion -= 0.04f; 
			if (suspicion < 0){
				 suspicion = 0;
			} 
		}
		return;
	}


	double calculate_equity(Card[] boardCards, size_t players_in, Evaluator eval) {
		if (sim_count == 0) return 0.0;

		size_t wins = 0;
		size_t ties = 0;
		
		eval.deck.shuffle_deck(); 
		eval.deck.remove_cards(this.hole);
		eval.deck.remove_cards(boardCards);

		const size_t simStartTop = eval.deck.top;

		for (size_t i = 0; i < sim_count; i++) {
			randomShuffle(eval.deck.deck[simStartTop .. $], eval.deck.rng);
			
			eval.deck.top = simStartTop;

			Card[] simBoard = boardCards.dup; 
			while (simBoard.length < 5) {
				simBoard ~= eval.deck.draw_card();
			}

			long myValue = eval(simBoard, this.hole);
			bool lost = false;
			bool tied = false;

			foreach (_; 1 .. players_in) {
				Card[2] oppHole = [eval.deck.draw_card(), eval.deck.draw_card()];
				long oppValue = eval(simBoard, oppHole);

				if (oppValue > myValue) {
					lost = true;
					break; 
				} else if (oppValue == myValue) {
					tied = true;
				}
			}

			if (!lost) {
				if (tied) ties++;
				else wins++;
			}
		}

		return (wins + (ties * 0.5)) / cast(double)sim_count;
	}
	
	bool should_raise(double perceivedEquity, double potOdds) {
        float edge = perceivedEquity - potOdds;
        return edge > (0.15f * (1.0f - aggression));
    }

	bool should_trap(double equity) {
        if (equity < 0.7) return false;
        return uniform(0.0f, 1.0f) > 1-trappiness;
    }


	bool bluff_decide(Card[] board, double potOdds, double equity) {
        if (equity > 0.65) return false;

        float score = bluff_frequency;
        score *= (0.5f + aggression);
        score *= (1.0f + tilt * 0.5f);
        score *= confidence;

        if (has_flush_draw(hole, board) || has_straight_draw(hole, board)){
            score *= 1.4f;
		}

		score *= (1.0f - (skill * potOdds * 0.7f));
        return uniform(0.0f, 1.0f) < clamp(score, 0.0f, 1.0f);
    }

	float effective_tightness() {
        return clamp((tightness - boredom), 0.0f, 1.0f);
    }


	void on_bad_beat() {
        tilt = clamp((tilt + (1.0f - tilt_resistance) * 0.4f), 0.0f, 1.0f);
        confidence = clamp((confidence - (1.0f - tilt_resistance) * 0.2f), 0.0f, 1.0f);
    }

	void on_win_hand() {
        tilt *= 0.7f;
        confidence = clamp((confidence + 0.1f), 0.0f, 1.0f);
    }

	void on_win_bluff(){
		tilt *=.2;
		confidence = clamp((confidence + 0.3f), 0.0f, 1.0f);
	}

	long calculate_raise_size(long pot, long toCall, double equity, double potOdds){
		double edge = equity - potOdds;

		if (edge <= 0){
			return 0;
		}
		double aggressionScale = 0.5 + aggression * 1.5;

		double raise = pot * (1 + edge * aggressionScale * 3);

		long finalRaise = cast(long)raise;

		if (finalRaise < toCall * 2){
			finalRaise = toCall * 2;
		}
		if (finalRaise > stack){
			finalRaise = stack;
		}
		return finalRaise;
	}
	
	float boredom_pressure() {
 		boredom += ((1.0 - patience) / 10.0);
		return boredom;
	}

	float detect_board_danger(Card[] board) {
		if (board.length < 3) return 0.0;
		
		Card[] emptyHole; 
		float danger = 0.0;

		if (has_flush_draw(emptyHole, board)) danger += 0.3;
		if (has_straight_draw(emptyHole, board)) danger += 0.2;
		
		return danger * board_awareness;
	}

	bool confident_enough(double equity, long pot, long toCall) {
		if (toCall <= 0) return true; 

		double potOdds = calculate_pot_odds(pot, toCall);
		
		double threshold = potOdds + (tightness * 0.15f);

		// sunk cost, this only effect bad players, the better you are the less it impacts you.
		float weight = (1.0f - skill) * risk_tolerance;
		float commitment = cast(float)sunk_cost / (stack + sunk_cost + 1);
		
		//i got some money in, might as well play
		threshold -= (commitment * weight * 0.2f);

		// I am angry I am going to play
		threshold -= (tilt * (1.0f - tilt_resistance) * 0.2f);

		return equity >= clamp(threshold, 0.05, 0.95);
	}

	override long take_turn(Card[] board, long pot, long toCall, size_t players_in, Evaluator eval) {
		if (stack <= 0) return 0;

		if (board.length == 0) {
			int handScore = evaluate_starting_hand(hole);
			if (!should_play_preflop(handScore, toCall, pot)) {
				boredom_pressure(); 
				return -1; 
			}
		}

		double potOdds = calculate_pot_odds(pot, toCall);
		double equity = calculate_equity(board, players_in, eval);

		double perceived_equity = equity + (suspicion * adaptability * 0.2f);

		if (board.length >= 3) {
			float danger = detect_board_danger(board);
			perceived_equity -= danger;
		}

		// 4. Emotional Confidence Check (The "Riley" Factor)
		if (!confident_enough(perceived_equity, pot, toCall)) {
			if (bluff_decide(board, potOdds, equity))
				return calculate_raise_size(pot, toCall, equity, potOdds);
			
			boredom_pressure();
			return -1; // fold
		}

		if (should_trap(perceived_equity)) {
			return toCall;
		}

		double judgment_error = uniform(-0.3, 0.3) * (1.0f - skill);
		if (perceived_equity >= (potOdds + judgment_error)) {
			if (should_raise(perceived_equity, potOdds)) {
				return calculate_raise_size(pot, toCall, equity, potOdds);
			}
			return toCall;
		}

		if (bluff_decide(board, potOdds, equity))
			return calculate_raise_size(pot, toCall, equity, potOdds);
		
		return -1; // Fold
	}


}

