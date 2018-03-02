pragma solidity ^0.4.18;


interface token {
  function transfer(address _to, uint256 _value) public view returns (bool);
  function balanceOf(address _owner) public view returns (uint256);
  function burn(uint256 _value) public;
}


/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
    return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
  // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
  // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract Crowdsale is Ownable{
  using SafeMath for uint256;

  // The token being sold
  token public AGR;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  uint256 public hardCap;

  bool public pause = false ;
  //event ChangePause();

  /**
  * event for token purchase logging
  * @param purchaser who paid for the tokens
  * @param beneficiary who got the tokens
  * @param value weis paid for purchase
  * @param amount amount of tokens purchased
  */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function Crowdsale(uint256 _startTime, uint256 _endTime, address _wallet,address _token,uint256 _hardcap) public {
    require(_startTime <= now);
    require(_endTime >= _startTime);
    require(_wallet != address(0));

    AGR = token(_token);
    startTime = _startTime;
    endTime = _endTime;
    rate = 125000;
    wallet = _wallet;
    hardCap = _hardcap.mul(1 ether);
  }


  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    require(pause==false);

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);
    tokens = tokens.div(1 ether);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    AGR.transfer(msg.sender,tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }


  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    //bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    bool minPurchase = msg.value >= SafeMath.div(1 ether,100);
    //bool isHardCap = weiRaised <= hardCap;
    //return withinPeriod && nonZeroPurchase && minPurchase && isHardCap;
    //return isHardCap && nonZeroPurchase && minPurchase;
    return nonZeroPurchase && minPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

  function burnTokens() onlyOwner public {
    uint256 _count = AGR.balanceOf(this);
    AGR.burn(_count);
  }

  function ChangePause() onlyOwner public   {
    pause = pause?false:true;   
  }
}