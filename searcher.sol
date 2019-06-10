// We will be using Solidity version 0.5.3
pragma solidity 0.5.3;
// Importing OpenZeppelin's SafeMath Implementation
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract AuctionBox{

    Auction[] public auctions;

    function createAuction (
        string memory _title,
        uint _startPrice,
        string memory _description
        ) public{
        // set the new instance
        Auction newAuction = new Auction(msg.sender, _title, _description);
        // push the auction address to auctions array
        auctions.push(newAuction);
    }

    function returnAllAuctions() public view returns(Auction[] memory){
        return auctions;
    }
}

contract Auction {

    using SafeMath for uint256;

    address payable private owner;  // 입찰제안자
    string title; // 입찰 제목
    string description; // 입찰 설명


    enum State{Default, Running, Finalized}
    enum item_State{Brandnew, Preowned}
    enum Delivery_State{Ready, Delevering, Delivered}
    State public auctionState;  // 제안 상태
    item itemname ;     // 제안 아이템
    uint starttime ;    // 시작 시간
    Delivery_State public del_state;

    uint public winningPrice; // 사용자가 만족한 금액이나 현재 가장 최저가 일 때 입찰 마감을 위함
    address public winningBidder;
    mapping(address => uint) public bids;


    // 입찰하는 항목에 대한 정의
    struct item {
        string i_id ;
        uint[5] i_category ;    // 카테고리는 최대 5개 까지 등록 가능, 0이면 빈칸
        item_State i_state ;
        string i_brand ;
        string i_buyer_loc ;
        string i_model ;
    }

    constructor(
        address payable _owner,
        string memory _title,
        string memory _description

        ) public {
        // initialize auction
        owner = _owner;
        title = _title;
        description = _description;
        auctionState = State.Running;
        starttime = now ; // 현재 시간으로 설정
        del_state = Delivery_State.Ready ;
    }

    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }

    modifier OwnerOnly(){
        require(msg.sender == owner);
        _;
    }

    // searcher는 가격과 모델을 입찰 함
    function placeBid(uint price) public notOwner returns(bool) {
        require(auctionState == State.Running); // 항목이 입찰 중이어야 함

        // mapping 으로 지금 입찰자의 주소에 현재 입찰 금액을 넣어 줌
        bids[msg.sender] = price;
        // update the winning price
        if ( winningPrice > price) {
          winningPrice = price;
          winningBidder = msg.sender;
        }
        return true;
    }

    //the owner can finalize the auction.
    //입찰 종료는 기한이 지나거나 사용자가 미리 마감 가능
    // final 하면 구매자가 searcher 에게 입금
    function finalizeAuction(address selected_searcher) public OwnerOnly payable {
        // 선택한 사람이 입찰자여야 함
        if(bids[selected_searcher] > 0){
            winningBidder = selected_searcher ;
            winningPrice = bids[selected_searcher];
        }


        address(this).transfer(winningPrice); // searcher 에게 수수료 3% 추가하여 컨트랙에 전송
        auctionState = State.Finalized;
    }

    // 컨펌 시 금액 전송
    function confirm_buy() public OwnerOnly {
        if (del_state == Delivery_State.Delevering) {
          winningBidder.transfer(address(this).balance);
          del_state = Delivery_State.Delivered ;
        }
    }


  // 진행 중인 입찰을 리턴

    function returnContents() public view returns(
        string memory,
        string memory,
        State
        ) {
        return (
            title,
            description,
            auctionState
        );
    }
}
