module payouts.payout_structure;
import pot;


abstract class PayoutStructure{
    void distribute(Pot[] pots);
}