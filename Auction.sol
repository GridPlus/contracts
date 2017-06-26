// An auction for bidding on BOLTs that have been sent to the contract.
pragma solidity ^0.4.8;
import "./ERC621.sol";

contract Auction {
  address private admin;
  address public BOLT;
  address public GRID;

  struct Period {
    mapping (address => uint) bids;
    uint bid_period_end;       // Time at which the bidding period ends
    uint reveal_period_end;    // Time at which the reveal period ends
    uint high_bid;             // Highest currently revealed bid
    address high_bidder;       // Current highest bidder
  }

  mapping (uint => Period) public periods;
  uint n;                             // Current bid number


  //============================================================================
  // AUCTION FUNCTIONS
  //============================================================================

  // Submit a bid during the bidding window.
  function SubmitBid(uint value) {
    if (periods[n].bid_period_end < now) { throw; }
    ERC621 grid = ERC621(GRID);
    if (!grid.transferFrom(msg.sender, address(this), value)) { throw; }
    else {
      periods[n].bids[msg.sender] = safeAdd(periods[n].bids[msg.sender], value);
    }
  }

  // Once the reveal period begins, each participant should reveal their bid.
  // If the bid is above the current highest, it displaces the
  function RevealBid() {
    if (periods[n].reveal_period_end < now) { throw; }
    else if (periods[n].bids[msg.sender] == 0) { throw; }
    else {
      // Capture the bid amount
      uint bid = periods[n].bids[msg.sender];
      // Zero out the bid
      periods[n].bids[msg.sender] = 0;

      if (periods[n].bids[msg.sender] < periods[n].high_bid) {
        // If the bid didn't win, refund it
        ERC621 grid = ERC621(GRID);
        if (!grid.transfer(msg.sender, bid)) { throw; }
      } else {
        // If the bid can displace the current leader, refund that participant
        if (!grid.transfer(periods[n].high_bidder, periods[n].high_bid)) { throw; }
        // Replace the bid
        periods[n].high_bid = bid;
        periods[n].high_bidder = msg.sender;
      }
    }
  }

  // Once the reveal period expires, the winner (publically viewable)
  // may claim the reward.
  function ClaimReward() {
    if (periods[n].reveal_period_end > now) { throw; }
    else if (msg.sender != periods[n].high_bidder) { throw; }
    else {
      // Get the total number of BOLTs held by this contract
      ERC621 bolt = ERC621(BOLT);
      ERC621 grid = ERC621(GRID);
      uint reward = bolt.balanceOf(address(this));

      // Transfer reward, decrease supply, and reset high bid params.
      if (!bolt.transfer(msg.sender, reward)) { throw; }
      else if (!grid.decreaseSupply(periods[n].high_bid, periods[n].high_bidder)) { throw; }
      else {
        periods[n].high_bid = 0;
        periods[n].high_bidder = address(0);
      }
    }
  }

  // If the reveal period has elapsed and a participant still has GRID locked up,
  // they can still withdraw until the next auction period (and incur a small
  // penalty)
  function PostRevealWithdraw() {
    if (periods[n].reveal_period_end > now) { throw; }
    else if (periods[n].bids[msg.sender] == 0) { throw; }
    else {
      // Capture the bid amount
      uint bid = periods[n].bids[msg.sender];
      // Zero out the bid
      periods[n].bids[msg.sender] = 0;
      ERC621 grid = ERC621(GRID);

      // Penalty of 5%
      uint penalty = bid/20;
      uint remainder = bid - penalty;
      if (!grid.transfer(msg.sender, remainder)) { throw; }
      else if (!grid.decreaseSupply(penalty, msg.sender)) { throw; }
    }
  }

  //============================================================================
  // UTIL
  //============================================================================

  // Get how many seconds are left in the bidding period
  function biddingRemaining() public constant returns (uint) {
    if (periods[n].bid_period_end <= now) { return 0; }
    else { return periods[n].bid_period_end - now; }
  }

  // Get how many seconds are left in the reveal period
  function revealRemaining() public constant returns (uint) {
    if (periods[n].reveal_period_end <= now) { return 0; }
    else { return periods[n].reveal_period_end - now; }
  }

  // Avoid numerical overflow
  function safeAdd(uint a, uint b) internal returns (uint) {
    if (a + b < a) throw;
    return a + b;
  }

  //============================================================================
  // ADMIN FUNCTIONS
  //============================================================================

  // Set a new period to start now.
  function NewPeriod(uint bid_end, uint reveal_end) onlyAdmin() {
    Period memory period;
    period.bid_period_end = bid_end;
    period.reveal_period_end = reveal_end;
    uint new_n = n + 1;
    periods[new_n] = period;
    n = new_n;
  }

  // Instantiate the Auction contract with GRID and BOLT addresses.
  function Auction(address _BOLT, address _GRID) {
    admin = msg.sender;
    BOLT = _BOLT;
    GRID = _GRID;
  }


	modifier onlyAdmin() {
		if (msg.sender != admin) { throw; }
		_;
	}

	function() { throw; }


}
