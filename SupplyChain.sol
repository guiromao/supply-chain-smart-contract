pragma solidity ^0.6.0;

contract Ownable {
    
    address payable owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(isOwner(), "Only the contract owner can perform this operation.");
        _;
    }
    
    function isOwner() public view returns(bool) {
        return(msg.sender == owner);
    }
    
}

contract Item {
    
    uint public priceInWei;
    uint public pricePaid;
    uint public index;
    
    ItemManager parentContract;
    
    constructor(uint _priceInWei, uint _index, ItemManager _parentContract) public {
        priceInWei = _priceInWei;
        pricePaid = 0;
        index = _index;
        parentContract = _parentContract;
    }
    
    receive() external payable {
        require(pricePaid == 0, "Item is paid already!");
        require(priceInWei == msg.value, "Money sent must be the same as the price of item!");
        pricePaid += msg.value;
        (bool success, ) = address(parentContract).call.value(msg.value)(abi.encodeWithSignature("triggerPayment(uint256)", index));
        require(success, "Transaction must be succesfful. Reverting it!");
    }
    
    fallback() external {
        
    }
    
}

contract ItemManager is Ownable {
    
    enum SupplyChainState{ Created, Paid, Delivered }
    
    struct S_Item {
        Item _item;
        string _identifier;
        uint _itemPrice;
        ItemManager.SupplyChainState _state;
    }
    
    mapping(uint => S_Item) public items;
    uint itemIndex;
    
    event SupplyChainEvent(uint _itemIndex, uint _step, address _itemAddress);
    
    function createItem(string memory _identifier, uint _itemPrice) public onlyOwner {
        Item item = new Item(_itemPrice, itemIndex, this);
        items[itemIndex]._identifier = _identifier;
        items[itemIndex]._itemPrice = _itemPrice;
        items[itemIndex]._state = SupplyChainState.Created;
        emit SupplyChainEvent(itemIndex, uint(items[itemIndex]._state), address(item));
        itemIndex += 1;
    }
    
    function triggerPayment(uint _itemIndex) public payable {
        require(items[_itemIndex]._itemPrice == msg.value, "Must fully pay for the item!");
        require(items[_itemIndex]._state == SupplyChainState.Created, "Item is further in the chain.");
        emit SupplyChainEvent(_itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));
        items[_itemIndex]._state = SupplyChainState.Paid;
    }
    
    function triggerDelivery(uint _itemIndex) public onlyOwner {
        require(items[_itemIndex]._state == SupplyChainState.Paid, "Item is further in the chain.");
        emit SupplyChainEvent(_itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));
        items[_itemIndex]._state = SupplyChainState.Delivered;
    }
    
}