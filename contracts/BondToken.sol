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

    constructor() 
        
        ERC1155("https://github.com/DavidCisar/Forschungsprojekt/{id}.json")
        
        { 
        IssuerAddress = msg.sender;
    }  

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
    
    address Regulator;
    address IssuerAddress;
    
    function setRegulator(
        address _regulator) 
        public
        onlyOwner
        {
        Regulator = _regulator;
    }
    
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

    mapping(uint => InvestorData) Investor;

    struct InvestorData {
        address [] Investors;
        mapping(address => bool) isInvestor;
    }

    uint public requestID;

    mapping(uint => ForcedTransferRequest) private RegulatoryRequests;

    struct ForcedTransferRequest{
        uint tokenID;
        uint amount;
        address investor;
        bool executed;
    }

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

    function returnInvestorLength(
        uint _tokenID)
        public
        view
        onlyOwner
        returns (uint investorLength)
        {
        return Investor[_tokenID].Investors.length;
    }

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

    mapping(uint => mapping(address => uint256)) private BuyBack;

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

    function burn(
        uint _tokenID)
        public
        onlyOwner
        {
        uint256 balance = balanceOf(msg.sender, _tokenID);
        _burn(msg.sender, _tokenID, balance);
        TokenData[_tokenID].burnedAmount += balance;
    }

    function returnPriceToPayETHER(
        uint _tokenID, 
        uint _amount)
        public
        view
        returns(uint)
        {
        return(TokenData[_tokenID].parValueETHER * _amount);    
    }

    function returnPriceToPayEUR(
        uint _tokenID, 
        uint _amount)
        public
        view
        returns(uint)
        {
        return(TokenData[_tokenID].parValueEUR * _amount);    
    }

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
