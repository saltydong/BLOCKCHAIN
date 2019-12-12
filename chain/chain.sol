pragma solidity ^0.4.23;


contract TableFactory {
    function openTable(string memory) public view returns (Table); //open table
    function createTable(string memory,string memory,string memory) public returns(int); //create table
}

contract Condition {
    function EQ(string memory, int) public;
    function EQ(string memory, string memory) public;
    function NE(string memory, int) public;
    function NE(string memory, string memory)  public;
    function GT(string memory, int) public;
    function GE(string memory, int) public;
    function LT(string memory, int) public;
    function LE(string memory, int) public;
    function limit(int) public;
    function limit(int, int) public;
}

contract Entry {
    function getInt(string memory) public view returns(int);
    function getAddress(string memory) public view returns(address);
    function getBytes64(string memory) public view returns(byte[64] memory);
    function getBytes32(string memory) public view returns(bytes32);
    function getString(string memory) public view returns(string memory);
    
    function set(string memory, int) public;
    function set(string memory, string memory) public;
}


contract Entries {
    function get(int) public view returns(Entry);
    function size() public view returns(int);
}

//api
contract Table {

    function select(string memory, Condition) public view returns(Entries);

    function insert(string memory, Entry) public returns(int);

    function update(string memory, Entry, Condition) public returns(int);

    function remove(string memory, Condition) public returns(int);
    
    function newEntry() public view returns(Entry);
    function newCondition() public view returns(Condition);
}



contract Asset {
    // event
    event RegisterEvent(int256 ret, string account, uint256 asset_value);
    event TransferEvent(int256 ret, string from_account, string to_account, uint256 amount);
    event PayEvent(int256 ret);

    address constant master = 0xbAF9163Da71F944b2B26a8CBe6484563cbE3EB47;
    string constant lastdate = "2019-12-25";

    string[] accountList;
    mapping(string=>address) name2addr;
    mapping(address=>string) addr2name;

    constructor() public {
        createTable();
    }

    function createTable() private {
        TableFactory tf = TableFactory(0x1001);
        tf.createTable("t_asset", "account", "asset_value");
    }

    function openTable() private view returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("t_asset");
        return table;
    }

    /*登录*/
    function login() public view returns(int){
        if (name2addr[addr2name[msg.sender]] != address(0)){
            if (msg.sender == master){
                return 3;
            }
            return 1;
        }
        if (msg.sender == master){
            return 2;
        }
        return 0;
    }

    /*查询*/
    function select(string memory account) public view returns(int256, uint256) {
     
        Table table = openTable();
 
        Entries entries = table.select(account, table.newCondition());
        uint256 asset_value = 0;
        if (0 == uint256(entries.size())) {
            return (-1, asset_value);
        } else {
            Entry entry = entries.get(0);
            return (0, uint256(entry.getInt("asset_value")));
        }
    }

    /*信息 */
    function register(string memory account, uint256 asset_value) public returns(int256){
        int256 ret_code = 0;
        int256 ret = 0;
        uint256 temp_asset_value = 0;

        (ret, temp_asset_value) = select(account);
        if(ret != 0) {
            name2addr[account] = msg.sender;
            addr2name[msg.sender] = account;
            accountList.push(account);
            Table table = openTable();

            Entry entry = table.newEntry();
            entry.set("account", account);
            if(msg.sender == master){
                entry.set("asset_value", int256(asset_value));
            }else{
                entry.set("asset_value", int256(0));
            }

            int count = table.insert(account, entry);
            if (count == 1) {
  
                ret_code = 0;
                if (msg.sender == master){
                    ret_code = 1;
                }
            } else {
   
                ret_code = -2;
            }
        } else {

            ret_code = -1;
        }

        emit RegisterEvent(ret_code, account, asset_value);

        return ret_code;
    }

    /*转移*/
    function transfer(string memory to_account, uint256 amount) public returns(int256) {
     
        string memory from_account = addr2name[msg.sender];
        int ret_code = 0;
        int256 ret = 0;
        uint256 from_asset_value = 0;
        uint256 to_asset_value = 0;
        
 
        (ret, from_asset_value) = select(from_account);
        if(ret != 0) {
            ret_code = -1;
    
            emit TransferEvent(ret_code, from_account, to_account, amount);
            return ret_code;

        }

   
        (ret, to_asset_value) = select(to_account);
        if(ret != 0) {
            ret_code = -2;
      
            emit TransferEvent(ret_code, from_account, to_account, amount);
            return ret_code;
        }

        if(from_asset_value < amount) {
            ret_code = -3;
 
            emit TransferEvent(ret_code, from_account, to_account, amount);
            return ret_code;
        }

        if (to_asset_value + amount < to_asset_value) {
            ret_code = -4;
       
            emit TransferEvent(ret_code, from_account, to_account, amount);
            return ret_code;
        }

        Table table = openTable();

        Entry entry0 = table.newEntry();
        entry0.set("account", from_account);
        entry0.set("asset_value", int256(from_asset_value - amount));

        int count = table.update(from_account, entry0, table.newCondition());
        if(count != 1) {
            ret_code = -5;
   
            emit TransferEvent(ret_code, from_account, to_account, amount);
            return ret_code;
        }

        Entry entry1 = table.newEntry();
        entry1.set("account", to_account);
        entry1.set("asset_value", int256(to_asset_value + amount));

        table.update(to_account, entry1, table.newCondition());

        emit TransferEvent(ret_code, from_account, to_account, amount);

        return ret_code;
    }



    function pay() public returns(int256){
        Table table = openTable();
        for(uint i = 0; i < accountList.length; i++){
            Entry entry = table.newEntry();
            entry.set("account", accountList[i]);
            entry.set("asset_value", int256(0));
            table.update(accountList[i], entry, table.newCondition());
        }

        emit PayEvent(0);
        return 0;
    }


}