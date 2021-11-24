pragma solidity ^0.6.0;
// SPDX-License-Identifier: MIT

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract pledge {
    using SafeMathChainlink for uint256; // I don't know why but it sounds nice 
    bool public date_reached=false;
    bool public steps_reached=false;
    uint256 public steps_target=100000;
    uint256 public date_target=20210101;
    uint256 private correct_password = 42;
    uint256 public minimumUSD = 50 * 10 ** 18; //require at least 50 usd in stupid units
    
    uint8 public max_donors = 20; // max number of donors so dont risk gas getting too expensive
    uint8 public donors_so_far = 0;
    
    // a new type to contain all relevant info about a depoit to the contract
    struct deposit{
        uint256 amount;
        address payable success_destination;
        address payable fail_destination;
    }
    mapping (address=>deposit) public address_to_deposit;
    address[] public userAddresses; // this is needed to iterate the mapping. mappings alone cannot be iterated
    

        //Not sure if/why we need this
        function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }
    
    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
         return uint256(answer * 10000000000);
    }
    
    // this converts however much eth they spend to usd
    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }
    
    //// These query functions will not be 'view' they will require transactions to the oracles
    function query_date() public view returns(uint256){
        //date obtained from oracle here
        return 20201220;
    }
    function query_steps() public view returns(uint256){
        //steps from fitbit API here
        return 100000;
    }
    
    
    constructor(uint256 _steps_target, uint256 _date_target) public payable{
        //owner = msg.sender; // What does this do?
        
        require(_steps_target > 100,"have some ambition dickhead");
        require(_date_target > 20211124, "that's in the past you twat" ); // Could query todays date here if it were worth the money to bother
        
        steps_target= _steps_target;
        date_target = _date_target;
        
        // code below same as fund() - see there for comments
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        address_to_deposit[msg.sender].amount += msg.value; 
        userAddresses.push(msg.sender); 
    }
    function fund() external payable{
        require(donors_so_far<max_donors, "Fuck off we're full");
        require(getConversionRate(msg.value) >= minimumUSD, "comeon cheapskate");
        address_to_deposit[msg.sender].amount += msg.value; /// Will the msg indicate what token too, do we need a dif function for every ERC-20
        userAddresses.push(msg.sender); //need an array to record these to iterate the mapping
    }
    
    //This is internal because nobody should have the power to distribute the eth other than the 'check' function
    function distribute_eth(bool _steps_reached) internal{
        //here goes the code to send the eth to the charity or the user depending if steps_reached is true or false
        if (_steps_reached){
                //for every deposit, transfer to success_destination
                for (uint i=0; i<userAddresses.length; i++) {
                    address add=userAddresses[i];
                    transfer( address_to_deposit[add].success_destination, address_to_deposit[add].amount); 
            }
        }
        else{
                // for every deposit, transfer to fail destination
                for (uint i=0; i<userAddresses.length; i++) {
                    address add=userAddresses[i];
                    transfer( address_to_deposit[add].fail_destination, address_to_deposit[add].amount);
            }
        }
    }
    
    
    function transfer(address payable to, uint256 amount) internal returns(bool){
        ///require(msg.sender==oracle address); no doing this elsewhere and with password
        to.transfer(amount);
    }
    
    
    
    // function for keeper to trigger which will check date and steps and distribute eth if appropriate
    function check(uint256 password) public returns(bool){
        
        //require(msg.sender==oracle address) ----------------------- do we want this? perhaps anyone should be able to trigger a check
        // Perhaps dont want the password either
        if (password != correct_password){
            return false;
        }
        
        uint256 date = query_date();
        uint256 steps = query_steps();
        
        if (date >= date_target){
            date_reached=true;
        }
        if (steps >= steps_target){
            steps_reached=true;
        }
        
        
        if (date_reached){
            // trigger eth distribution if date reached
            distribute_eth(steps_reached);
            return true;
            
        }
        else{
            return false;
        }
        
    }
    

    
    
    
}
