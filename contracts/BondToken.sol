// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./KnowYourCustomer.sol";
import "./Documents.sol";
import "./SecuritiesRegister.sol";

contract Bond is ERC1155 {
    

// When first deploying the contract, the constructor requires the addresses of the KYC, CSR and Documents contract.
// As an option to pay via a stablecoin should be included, a stablecoin's contract address can be submitted.

    constructor() 
        
        ERC1155("https://github.com/DavCsr/BondTokenMasterThesis/{id}.json")
        
        { 
        IssuerAddress = msg.sender;
    }
    
    // Events

    // To foster transparency, the bond token contract emits events in the following cases:    

    event TokenMinted (
        uint _tokenID, 
        uint256 indexed _timestamp
        );

    event CouponPaid (
        uint _tokenID, 
        address _to, 
        uint256 _amouont, 
        uint256 indexed _timestamp
        );

    event RedemptionPaid (
        uint _tokenID, 
        address indexed _to, 
        uint256 _amouont, 
        uint256 indexed _timestamp
        );

    event TokenBought (
        uint _tokenID, 
        address indexed _to, 
        uint256 _amount, 
        uint256 indexed _timestamp
        );

    event TokenTransfered (
        uint _tokenID, 
        address indexed _to, 
        address indexed _from, 
        uint256 _amount, 
        uint256 indexed _timestamp
        );

    event RedemptionBuyBack (
        uint _tokenID, 
        address indexed _from, 
        uint256 _amount, 
        uint256 indexed _timestamp
        );

    event RequestForcedTransfer (
        uint indexed requestID, 
        uint _tokenID, 
        address _investor, 
        uint256 _amount
        );

    event ForcedTokenTransfered (
        uint _tokenID, 
        address indexed _to, 
        address indexed _from, 
        uint256 _amount, 
        uint256 indexed _timestamp
        );
    
    // Contracts 
    
    KycContract KYC;
    CSRContract CSR;
    DocumentContract Documents;
    IERC20 _stableCoin;

    function setKycContract(address _addr)
        public
        onlyOwner
        {
        KYC = KycContract(_addr);
    }

    function setCSRContract(address _addr)
        public
        onlyOwner
        {
        CSR = CSRContract(_addr);
    }

    function setDocumentsContract(address _addr)
        public
        onlyOwner
        {
        Documents = DocumentContract(_addr);
    }

    function setStableCoinContract(address _addr)
        public
        onlyOwner
        {
        _stableCoin = IERC20(_addr);
    }
    
    // Modifier

    modifier onlyRegulator {
        require(
            msg.sender == Regulator, 
            "Only Regulator!"
            );
        _;
    }

    modifier onlyOwner {
        require(
            msg.sender == IssuerAddress, 
            "Only Owner!"
            );
        _;
    }
    
    // Entities
    
    address Regulator;
    address IssuerAddress;
    
    // Functions for entity management
    
    function setRegulator(
        address _regulator) 
        public
        onlyOwner
        {
        Regulator = _regulator;
    }
        
    // Variables

    
    // Each token ID has a so-called TokenDataStruct.
    // This struct contains important variables.
    
    mapping(uint => TokenDataStruct) private TokenData;

    struct TokenDataStruct {
        uint volume;
        uint parValueETHER;
        uint parValueEUR;
        uint coupon;
        uint issuedAmount;
        uint redemptionAmount;
        uint burnedAmount;
        uint256 settlementDate;
        uint256 maturityDate;
    }
    
    // Each bond token ID potentially has unlimited investors.
    // To get the investor count, these investors are stored in a list called Investor.
    // Additionally, the InvestorData allows to answer the question, whether the balance
    // of the investor is 0 => 'false', or >0 => 'true'.

    mapping(uint => InvestorData) Investor;

    struct InvestorData {
        address [] Investors;
        mapping(address => bool) isInvestor;
    }

    // The bond token prototype allows to request forced transfers.
    // Each request has a specific requestID, which serves to identify
    // the request for later execution. 
    // The Regulator has to store information about the tokenID, the amount
    // and the investor address. If the request gets executed, the bool executed
    // gets set to 'true' .

    uint public requestID;

    mapping(uint => ForcedTransferRequest) private RegulatoryRequests;

    struct ForcedTransferRequest{
        uint tokenID;
        uint amount;
        address investor;
        bool executed;
    }
    
    // The function tokenState returns the token's state of a tokenID.
    // - 2: The bond is already matured.
    // - 1: The bond is settled and can be traded.
    // - 0: The bond is not settled yet and can initially be purchased.

    function tokenState(
        uint _tokenID)
        public
        view 
        returns(uint state)
        {
            
        if (block.timestamp > TokenData[_tokenID].maturityDate){
            return 2;
        }
        
        if (block.timestamp > TokenData[_tokenID].settlementDate && 
            block.timestamp < TokenData[_tokenID].maturityDate) {
            return 1;
        }
        
        if (block.timestamp < TokenData[_tokenID].settlementDate) {
            return 0;   
        }
    }
    
    // Function for the initial issuance

    // The mintToken function requires to input a specific TokenID.
    // Only the IssuerAddress can execute this function.
    // The function delegateCalls the CSR contracts function
    // 'dataComplete', which returns a bool for the tokenID.
    // If 'true', the bond token pulls specific TokenData from the CSR.
    // Then an internal _mint function gets executed, which distributes 
    // the volume of the bond token ID to the IssuerAddress.
    // The event TokenMinted gets emitted.
    // The function returns 'true' if executed correctly.
    
    function mintToken(
        uint _tokenID)
        public
        onlyOwner
        returns (bool)
        {
    
        require(
            CSR.dataComplete(_tokenID),
            "CSR not initialized!"
            );
        
        (TokenData[_tokenID].volume, 
        TokenData[_tokenID].parValueETHER, 
        TokenData[_tokenID].parValueEUR, 
        TokenData[_tokenID].coupon) = CSR.returnTokenDataOne(_tokenID);
        
        (TokenData[_tokenID].settlementDate, 
        TokenData[_tokenID].maturityDate) = CSR.returnTokenDataTwo(_tokenID);
        
        _mint(
            IssuerAddress, 
            _tokenID, 
            TokenData[_tokenID].volume, 
            ""
            );
        
        emit TokenMinted(
            _tokenID, 
            block.timestamp
            ); 
            
        return true;
    }
    
    // The function returnTokenData returns the token's specific data,
    // which will be used later on in the smart contract.

    function returnTokenData(
        uint _tokenID)
        public
        view
        returns (
            uint volume, 
            uint parValueETHER, 
            uint parValueEUR, 
            uint coupon, 
            uint issuedAmount, 
            uint redemptionAmount, 
            uint burnedAmount)
        {
            
        return(
            TokenData[_tokenID].volume,
            TokenData[_tokenID].parValueETHER,
            TokenData[_tokenID].parValueEUR,
            TokenData[_tokenID].coupon,
            TokenData[_tokenID].issuedAmount,
            TokenData[_tokenID].redemptionAmount,
            TokenData[_tokenID].burnedAmount
        );    
    }
    
    // The function returnTokenDates returns the token's Dates,
    // which will be used later on in the smart contract.

    function returnTokenDates(
        uint _tokenID)
        public
        view
        returns(
            uint256 settlementDate, 
            uint256 maturityDate)
        {

        return(
            TokenData[_tokenID].settlementDate,
            TokenData[_tokenID].maturityDate
        );    
    }
    
    // Functions for corporate actions
    
    // In order to be able to execute corporate actions, the function
    // returnInvestorLength returns the amount of investors for a specific tokenID

    function returnInvestorLength(
        uint _tokenID)
        public
        view
        onlyOwner
        returns (uint investorLength)
        {
        return Investor[_tokenID].Investors.length;
    }
    
    // In order to be able to execute corporate actions, the function
    // returnInvestorAddress returns the address of a specific investor
    // and if the investor's bond token amount is equal to or higher than 0
    // by accessing the investor list of a tokenID with an _index.

    function returnInvestorAddress(
        uint _tokenID,
        uint _index)
        public
        view
        onlyOwner
        returns (
            address investorAdress, 
            bool isInvestor)
        {
            
        return (
            Investor[_tokenID].Investors[_index], 
            Investor[_tokenID].isInvestor[Investor[_tokenID].Investors[_index]]); 
    }
    
    // The IssuerAddress can payCoupon for a specific tokenID
    // to a specific investor address _to of a specific amount
    // in WEI.
    // The function checks whether the msg.value has the intended
    // value, then transfers the amount to the investor address _to.
    // For documentation, the function emits a event CouponPaid.

    function payCoupon(
        uint _tokenID,
        address payable _to,
        uint256 _valueInWEI)
        public
        payable
        onlyOwner
        {
        require(
            msg.value == _valueInWEI,
            "Check msg.value"
        );
        
        _to.transfer(_valueInWEI);
        
        emit CouponPaid(
            _tokenID, 
            _to, 
            _valueInWEI, 
            block.timestamp);
    }
    
    // Redemption Buy Back
    // To get a redemption, the investor has to
    // send the bond tokens back to the IssuerAddress

    mapping(uint => mapping(address => uint256)) private BuyBack;
    
    // Via the function redemptionBuyBack, an investor
    // or an authorized operator may send the tokens of 
    // a specific tokenID back to the IssuerAddress
    // after the bond is matured. The function automatically
    // retrieves the balance from a delegateCall of the CSR
    // contract and then transfers the balance.
    // The CSR gets updated, the amount gets documented
    // and the event RedemptionBuyBack gets emitted.

    function redemptionBuyBack(
        address _from,
        uint _tokenID)
        public
        {
        require(
            block.timestamp > TokenData[_tokenID].maturityDate,
            "Bond not matured yet"
        );
        require(
            _from == _msgSender() || 
            isApprovedForAll(_from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        uint balance = CSR.balanceOf(_tokenID, _from);
        
        _safeTransferFrom(
            _from, 
            IssuerAddress, 
            _tokenID, 
            balance, 
            "[]"
            );
            
        CSR.updateCSRbyContractSell(
            _tokenID, 
            msg.sender,
            balance
            );
            
        BuyBack[_tokenID][_from] = balance;

        emit RedemptionBuyBack(
            _tokenID, 
            _from, 
            balance, 
            block.timestamp
            );
    }

    // Via the returnRedemptionPTP, the IssuerAddress
    // may get information about the price to pay for
    // a specific tokenID and investor address.

    function returnRedemptionPTP(
        uint _tokenID,
        address _to)
        public
        view
        onlyOwner
        returns (uint256)
        {
        return returnPriceToPayETHER(
            _tokenID, 
            BuyBack[_tokenID][_to]) 
            * (10**18);    
    }

    // After the investors sent the bond tokens back to
    // the IssuerAddress, the redemption follows. For a 
    // specific tokenID and investor address _to, the
    // IssuerAddress transfers the value of the bond tokens
    // back to the investor. The function checks the msg.value
    // and emits the event RedemptionPaid.

    function payRedemtion(
        uint _tokenID,
        address payable _to)
        public
        payable
        onlyOwner
        {
        require(
            block.timestamp > TokenData[_tokenID].maturityDate,
            "Redemption not possible yet"
        );    
        
        require(
            msg.value == (returnPriceToPayETHER(_tokenID, BuyBack[_tokenID][_to]) * (10**18)),
            "Check msg.value"
            );
            
        _to.transfer(msg.value);
        
        TokenData[_tokenID].redemptionAmount += BuyBack[_tokenID][_to];
        
        emit RedemptionPaid(
            _tokenID, 
            _to, 
            msg.value, 
            block.timestamp
            );
    }
    
    // After the bond matured, the IssuerAddress may
    // burn the bond tokens in balance.

    function burn(
        uint _tokenID)
        public
        onlyOwner
        {
        uint256 balance = balanceOf(msg.sender, _tokenID);
        _burn(msg.sender, _tokenID, balance);
        TokenData[_tokenID].burnedAmount += balance;
    }
    
    // Functions for investors
    
    // The function returnPriceToPayEther 
    // returns the price to pay in Ether
    // for a specific tokenID and amount.

    function returnPriceToPayETHER(
        uint _tokenID, 
        uint _amount)
        public
        view
        returns(uint)
        {
        return(TokenData[_tokenID].parValueETHER * _amount);    
    }

    // The function returnPriceToPayEUR 
    // returns the price to pay in euro
    // for a specific tokenID and amount.

    function returnPriceToPayEUR(
        uint _tokenID, 
        uint _amount)
        public
        view
        returns(uint)
        {
        return(TokenData[_tokenID].parValueEUR * _amount);    
    }
    
    // The function buyTokensEther allows
    // an investor to purchase the bond with
    // a specific tokenID and amount via sending
    // ether to the IssuerAddress. The tokenState
    // needs to be equal to 0, thus being pre-
    // settlement state. The msg.sender needs to 
    // be whitelisted, and the msg.value needs to
    // be equal to the price to pay in Ether.
    // By sending Ether, the function transfers
    // the purchased bond tokens to the investor.
    // Both the Investor and the tokenData struct get 
    // updated, as well as the CSR. Finally, the event
    // TokenBought gets emitted. 

    function buyTokensETHER(
        uint _tokenID, 
        uint _amount)
        public 
        payable
        returns(bool)
        {
        require(
            tokenState(_tokenID) == 0,
            "TS closed."
        );
        require(
            KYC.kycCompleted(msg.sender),
            "Not whitelisted."
        );
        require(
            msg.value == (returnPriceToPayETHER(_tokenID, _amount)*(10**18)),
            "Check msg.value"
        );
        
        payable(IssuerAddress).transfer(msg.value);
        
        _safeTransferFrom(
            IssuerAddress, 
            msg.sender, 
            _tokenID, 
            _amount, 
            "[]"
            );
        
        if (!Investor[_tokenID].isInvestor[msg.sender]) {
            Investor[_tokenID].Investors.push(msg.sender);
            Investor[_tokenID].isInvestor[msg.sender] = true;
        }
        
        TokenData[_tokenID].issuedAmount += _amount;
        
        CSR.updateCSRbyContractBuy(
            _tokenID, 
            msg.sender,
            _amount
            );
        
        emit TokenBought(
            _tokenID, 
            msg.sender, 
            _amount, 
            block.timestamp
            );
            
        return true;
    }
    
    // The function buyTokensEUR allows
    // an investor to purchase the bond with
    // a specific tokenID and amount via sending
    // euro to the IssuerAddress. The tokenState
    // needs to be equal to 0, thus being pre-
    // settlement state. The msg.sender needs to 
    // be whitelisted, and the msg.value needs to
    // be equal to the price to pay in Ether.
    // By sending euro, the function transfers
    // the purchased bond tokens to the investor.
    // Both the Investor and the tokenData struct get 
    // updated, as well as the CSR. Finally, the event
    // TokenBought gets emitted. 

    function buyTokensEUR(
        uint _tokenID, 
        uint _amount)
        public 
        payable
        returns(bool)
        {
        require(
            tokenState(_tokenID) == 0,
            "TS closed."
        );
        require(
            KYC.kycCompleted(msg.sender),
            "Not whitelisted!"
        );
        
        address from = msg.sender;
        uint256 ptp = returnPriceToPayEUR(_tokenID, _amount);
        
        _stableCoin.transferFrom(from, IssuerAddress, ptp);
        
        _safeTransferFrom(
            IssuerAddress, 
            msg.sender, 
            _tokenID, 
            _amount, 
            "[]"
            );
        
        if (!Investor[_tokenID].isInvestor[msg.sender]) {
            Investor[_tokenID].Investors.push(msg.sender);
            Investor[_tokenID].isInvestor[msg.sender] = true;
        }
        
        TokenData[_tokenID].issuedAmount += _amount;
        
        CSR.updateCSRbyContractBuy(
            _tokenID, 
            msg.sender, 
            _amount
            );
        
        emit TokenBought(
            _tokenID, 
            msg.sender, 
            _amount, 
            block.timestamp
            );
            
        return true;
    }
    
    // Functions for token transfers

    // The function safeTransferFrom
    // allows the owner of bond tokens
    // or an authorized operator to
    // transfer tokens of a specific
    // amount of a specific id to 
    // another investor to, who needs 
    // to be whitelisted. The transfer
    // is only allowed before maturity.
    // InvestorStruct and the CSR get
    // updated and the event TokenTransferred
    // gets emitted.
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
        )
        public
        virtual override
        {

        require(
            block.timestamp < TokenData[id].maturityDate,
            "MD reached!"
        );
        require(
            KYC.kycCompleted(to),
            "Not whitelisted!"
        );
        require(
            from == _msgSender() || 
            isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        
        _safeTransferFrom(
            from, 
            to, 
            id, 
            amount, 
            data
            );
        
        if (!Investor[id].isInvestor[to]) {
            Investor[id].Investors.push(to);
            Investor[id].isInvestor[to] = true;
        }
        
        CSR.updateCSRbyContractBuy(id, to, amount); 
        CSR.updateCSRbyContractSell(id, msg.sender, amount);
        
        emit TokenTransfered(
            id, 
            to, 
            msg.sender, 
            amount, 
            block.timestamp
            );
        
    }
    
    // Forced transfers by regulatory authority
    
    // The regulator can request a forced transfer
    // of a specific _investor, _tokenID and _amount.
    // The request is then stored within the struct
    // RegulatoryRequests and the event
    // RegulatoryForcedTransfer gets emitted.

     function requestForcedTransfer(
         uint _tokenID,
         address _investor,
         uint _amount)
         public
         onlyRegulator
         {
         RegulatoryRequests[requestID].tokenID = _tokenID;
         RegulatoryRequests[requestID].investor = _investor;
         RegulatoryRequests[requestID].amount = _amount;
         requestID ++;
         
         emit RequestForcedTransfer(
             requestID-1, 
             _tokenID, 
             _investor, 
             _amount
             );
     }
    
    // The IssuerAddress is able to execute
    // the id of a requested forced transfer.
    // The IssuerAddress gets a temporary 
    // EmergencyApprocal and transfers the tokens
    // from the _investor.
    // The CSR gets updated and the event
    // ForcedTokenTransfered gets emitted.
    
    function forcedTransfer(
        uint _id)
        public
        onlyOwner
        {
        require(
            RegulatoryRequests[_id].executed == false
            );
        
        uint _tokenID = RegulatoryRequests[_id].tokenID;
        uint _amount = RegulatoryRequests[_id].amount;
        address _investor = RegulatoryRequests[_id].investor;
        
        setEmergencyApproval(_investor, true);
        safeTransferFrom(_investor, IssuerAddress, _tokenID, _amount, "[]");
        setEmergencyApproval(_investor, false);
        
        CSR.updateCSRbyContractSell(_tokenID, _investor, _amount);
        
        emit ForcedTokenTransfered(
            _tokenID, 
            IssuerAddress, 
            _investor, 
            _amount, 
            block.timestamp
            );
    }
}