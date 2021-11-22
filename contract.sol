pragma solidity >=0.7.0 <0.9.0;

contract pledge {
    
    
    bool public date_reached=false;
    bool public steps_reached=false;
    uint256 public steps_target=100000;
    uint256 public date_target=20210101;
    uint256 private correct_password = 42;
    
    //this tracks who sent how much
    
    // a new type to contain all relevant info about a depoit to the contract
    struct deposit{
        uint256 amount;
        address success_destination;
        address fail_destination;
    }
    
    mapping (address=>deposit) public address_to_deposit;
    address[] public userAddresses; // this is needed to iterate the mapping. mappings alone cannot be iterated
    
    
    //To withdraw a token balance, you need to execute the transfer() function on the token contract. So in order to withdraw all tokens, you need to execute the transfer() function on all token contracts.
    //You can create a function that withdraws any ERC-20 token based on the token contract address that you pass as an input.
    
    //pragma solidity ^0.8;
    
    // what is external keyword - changed to internal - this is only to be called by this contract itself
    // external is the same as public, but to be used when you will never call it internally. due to some technical details
    // public functions use more gas than external
    // what is an interface - i forgot
    interface IERC20 {
        function transfer(address _to, uint256 _amount) internal returns (bool);
    }
    
    // Figure out exactly how this is called
    function fund() external payable{
        //There needs to be a limit to the ammoung of people thaat can fund as iterating through them uses gas and there is a block gas limit
        // could end up with a contract that would require too much gas to excecute
        address_to_deposit[msg.sender].amount += msg.value; /// Will the msg indicate what token too, do we need a dif function for every ERC-20
        userAddresses.push(msg.sender); //need an array to record these to iterate the mapping
        
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
    
    //This is internal because nobody should have the power to distribute the eth other than the 'check' function
    function distribute_eth(bool steps_reached) internal{
        //here goes the code to send the eth to the charity or the user depending if steps_reached is true or false
        if (steps_reached){
                //for every deposit, transfer to success_destination
                for (uint i=0; i<studentList.length; i++) {
                    transfer( address_to_deposit[i].success_destination, address_to_deposit[i].amount) 
            }
        }
        else{
                // for every deposit, transfer to fail destination
                for (uint i=0; i<studentList.length; i++) {
                    transfer( address_to_deposit[i].fail_destination, address_to_deposit[i].amount) 
            }
        }
    }
    
    // function for keeper to trigger which will check date and steps and distribute eth if appropriate
    function check(uint256 password) public returns(bool){
        
        if (password != correct_password){
            return false;
        }
        
        date = query_date();
        steps = query_steps();
        
        if (date >= date_target){
            data_reached=true;
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
