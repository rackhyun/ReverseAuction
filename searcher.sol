pragma solidity 0.4.18;

contract Auction {
    address private owner;  // 입찰제안자
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
    address public winningBidder; // 현재 최저 금액 서처
    mapping(address => uint) public bids; // 서처 주소와 입찰 금액 저장
// 입찰하는 항목에 대한 정의
    struct item {
        string i_id ;
        uint[5] i_category ;    // 카테고리는 최대 5개 까지 등록 가능, 0이면 빈칸
        item_State i_state ;
        string i_brand ;
        string i_buyer_loc ;
        string i_model ;
    }

// auction 생성시 deploy 할 때 불필요하게 등록할 수 있으므로 최대 지불 가능 금액을 설정하여 등록(payable)
    function Auction(string  _title, string _description) public payable {
        owner = msg.sender;
        title = _title;
        description = _description;
        winningBidder = 0 ;
        winningPrice = 0 ;
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
        if ( winningPrice > price || winningPrice == 0 ) {
          winningPrice = price;
          winningBidder = msg.sender;
        }
        return true;
    }
  //the owner can finalize the auction.
  //입찰 종료는 기한이 지나거나 사용자가 미리 마감 가능
    // final 하면 searcher 에게 입금할 금액을 제외하고 나머지 금액 withdraw
    function finalizeAuction(address selected_searcher) public OwnerOnly payable {
        // 선택한 사람이 입찰자여야 함
        if(selected_searcher != address(0)){
            winningBidder = selected_searcher ;
            winningPrice = bids[selected_searcher];
        }

        // searcher 에게 수수료 2% 추가하여 컨트랙트에 보관하고 잔여 금액은 구매자에게 돌려줌
        // auction 상태를 변경 하고 배송 상태로 바꿈
        msg.sender.transfer(address(this).balance - (winningPrice * 102 / 100));
        del_state = Delivery_State.Delevering ;
        auctionState = State.Finalized;
    }

 // 배송이 되면 구매 컨펌 시 서처에게 금액 전송
    function confirm_buy() public OwnerOnly {
        if (del_state == Delivery_State.Delevering) {
          winningBidder.transfer(address(this).balance);
          del_state = Delivery_State.Delivered ;
        }
    }

    // 진행 중인 입찰을 리턴 (현황 보기)
    function returnContents() public view returns(string, string, State) {
        return (title, description,auctionState);
    }
}
