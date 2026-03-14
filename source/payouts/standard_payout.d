module payouts.standard_payout;

import payouts.payout_structure;
import pot;


class StandardPayout : PayoutStructure {

    override void distribute(Pot[] pots) {
        foreach (ref pot; pots) {
            ulong numWinners = pot.winners.length;
            if (numWinners == 0) {
                continue;
            }
            long share = pot.amount / numWinners;
            long remainder = pot.amount % numWinners;

            foreach (i, winner; pot.winners) {
                winner.stack += share;
                if (i < remainder) {
                    winner.stack += 1;
                }
            }
        }
    }

}