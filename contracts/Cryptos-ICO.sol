//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) external returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Cryptos is ERC20Interface {
    string public name = "Cryptos";
    string public symbol = "CRPT";
    uint public decimals = 0; //18
    uint public override totalSupply;
    
    address public founder;
    mapping(address => uint) public balances;
 
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() {
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address to, uint tokens) public virtual override returns (bool success) {
        require(balances[msg.sender] >= tokens);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) view public override returns (uint) {
        return allowed[_owner][_spender];
    }
    
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value);   
        require(_value > 0);
        
        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool success) {
        require(allowed[_from][_to] >= _value);
        require(balances[_from] >= _value);
        
        balances[_from] -= _value;
        balances[_to] += _value;
        
        allowed[_from][_to] -= _value;
        
        return true;
    }
}


contract CryptosICO is Cryptos {
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.001 ether; // 1ETH = 1000 CRPT, 1 CRPT = 0.001
    uint public hardCap = 300 ether;
    uint public raisedAmount;
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800; // ICO ends in 1 week
    uint public tokenTradeStart = saleEnd + 604800; // 1 week after ICO end
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;
    
    enum State{beforeStart, running, afterEnd, halted}
    State public icoState;
    
    event Invest(address investor, uint value, uint tokens);
    
    constructor(address payable _deposit) {
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "You're not the admin.");
        _;
    }
    
    function halt() public onlyAdmin {
        icoState = State.halted;
    }
    
    function resume() public onlyAdmin {
        icoState = State.running;
    }
    
    function changeDepositAddress(address payable _newDeposit) public onlyAdmin {
        deposit = _newDeposit;
    }
    
    function getCurrentState() public view returns(State){
        if (icoState == State.halted) {
            return State.halted;
        } else if (block.timestamp < saleStart) {
            return State.beforeStart;
        } else if (block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return State.running;
        } else {
            return State.afterEnd;
        }
    }
    
    function invest() payable public returns (bool) {
        require(getCurrentState() == State.running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);
        uint tokens = msg.value / tokenPrice;
        
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        
        deposit.transfer(msg.value);
        
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
    }
    
    receive() payable external {
        invest();
    }
    
    function transfer(address to, uint tokens) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart);
        super.transfer(to, tokens);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart);
        super.transferFrom(_from, _to, _value);
        return true;
    }

    function burn() public returns(bool) {
        require(getCurrentState() == State.afterEnd);
        balances[founder] = 0;
        return true;
    }
}



