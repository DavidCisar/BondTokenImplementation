// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/access/Ownable.sol";
import "./BondToken.sol";
import "./DateTime.sol";
import "./KnowYourCustomer.sol";

contract CSRContract is Ownable, DateTime {
    
    // Events
    
    event TokenDataEntry (
        uint indexed _tokenID, 
        uint _volume, 
        uint _parValue, 
        uint _parValueEUR, 
        uint _coupon, 
        string _rating, 
        string _issuer, 
        string _entryType
        );

    event TokenDatesEntry (
        uint indexed _tokenID, 
        uint256 [] _settlementDate, 
        uint256 [] _maturityDate
        );

    event TermSheetEntry (
        uint indexed _tokenID, 
        string [] _tokenTerms, 
        string _isin, 
        string _wkn, 
        string _itin
        );

    event ChangeOfRegister (
        uint _tokenID, 
        string [] _data, 
        uint256 _timestamp
        );

    event ChangeOfRegisterInvestorData (
        address _investor, 
        bytes32 [] _data, 
        uint256 _timestamp
        );

    event ChangeOfRegisterInvestorBalance (
        uint _timestamp, 
        address _changingAddress, 
        uint _tokenID, 
        address _investor, 
        uint _amount
        );
    
    // Contracts
    
    Bond BTC;
    KycContract KYC;
    
    // Functions for contract management
    
    function setBondTokenContract(
        address _addr)
        public
        onlyOwner
        {
        BTC = Bond(_addr);
    }
    
    function setKycContract(address _addr)
        public
        onlyOwner
        {
        KYC = KycContract(_addr);
    }
    
    // Modifier
    
    modifier onlyRegistrar {
        require(
            msg.sender == Registrar, 
            "You are not authorized!"
            );
        _;
    }
    
    modifier onlyRegulator {
        require(
            msg.sender == Regulator, 
            "You are not authorized!"
            );
        _;
    }
    
    modifier onlyContract {
        require(
            BTC == Bond(msg.sender) || 
            KYC == KycContract(msg.sender), 
            "Only a contract can call this function!"
            );
        _;
    }
    
    // Entities
    
    address public Registrar;
    address public Regulator;
    
    // Functions for entity management
    
    function setRegistrar(
        address _addr)
        public
        onlyOwner
        {
        Registrar = _addr;    
    }
    
    function changeRegistrar(
        address _addr)
        public
        onlyOwner
        {
        require(
            Registrar != _addr, 
            "Already registrar!"
        );
        Registrar = _addr;
    }
    
    function setRegulator(
        address _addr)
        public
        onlyOwner
        {
        Regulator = _addr;    
    }
    
    function changeRegulator(
        address _addr)
        public
        onlyOwner
        {
        require(
            Regulator != _addr, 
            "Already regulator"
        );
        Regulator = _addr;
    }
    
    // Crypto Securities Register
    
    mapping(uint => CSRStruct) private SecuritiesRegister;
    
    struct CSRStruct {
        TermSheet termsheet;
        InvestorStructure investorstructure;
        uint volume;
        uint parValueETHER;
        uint parValueEUR;
        uint coupon;
        string issuer;
        string rating;
        string entryType;
        uint256 settlementDate;
        uint256 maturityDate;
        bool dataComplete;
        bool regulatorApproval;
        mapping(address => InvestorInformationStruct) InvestorInformation;
    }
    
    struct TermSheet {
        string [] TokenTerms;
        string ISIN;
        string WKN;
        string ITIN;
    }
    
    struct InvestorStructure {
        uint AmountSingleEntry;
        uint AmountCollectiveEntry;
    }
    
    struct InvestorInformationStruct {
        uint balanceOf;
        bytes32 [] DisposalRestrictions;
        bytes32 [] ThirdPartyRights;
        bytes32 [] OtherDisposalRestrictions;
        bytes32 [] LegalCapacityOwner;
    }
    
    // Functions for CSR management
    
    function setDates(
        uint _tokenID, 
        uint256 [] memory _settlementDate, 
        uint256 [] memory _maturityDate)
        public
        onlyRegistrar
        {
        require(
            SecuritiesRegister[_tokenID].regulatorApproval == false
        );
        
        SecuritiesRegister[_tokenID].settlementDate = toTimestamp(
            uint16(_settlementDate[0]), 
            uint8(_settlementDate[1]), 
            uint8(_settlementDate[2])
            );

        SecuritiesRegister[_tokenID].maturityDate = toTimestamp(
            uint16(_maturityDate[0]), 
            uint8(_maturityDate[1]), 
            uint8(_maturityDate[2])
            );
        
        emit TokenDatesEntry(
            _tokenID, 
            _settlementDate, 
            _maturityDate
            );
    }
    
    function setTokenData(
        uint _tokenID,
        uint _volume,
        uint _parValueETHER,
        uint _parValueEUR,
        uint _coupon,
        string memory _rating,
        string memory _issuer,
        string memory _entryType)
        public
        onlyRegistrar
        {
        require(
            SecuritiesRegister[_tokenID].regulatorApproval == false
        );
        
        SecuritiesRegister[_tokenID].volume = _volume;
        SecuritiesRegister[_tokenID].parValueETHER = _parValueETHER;
        SecuritiesRegister[_tokenID].parValueEUR = _parValueEUR;
        SecuritiesRegister[_tokenID].coupon = _coupon;
        SecuritiesRegister[_tokenID].rating = _rating;
        SecuritiesRegister[_tokenID].issuer = _issuer;
        SecuritiesRegister[_tokenID].entryType = _entryType;
        
        emit TokenDataEntry(
            _tokenID,
            _volume,
            _parValueETHER,
            _parValueEUR,
            _coupon, 
            _rating, 
            _issuer, 
            _entryType
            );
    }
    
    function setTermSheet(
        uint _tokenID, 
        string [] memory _tokenTerms,
        string memory _isin,
        string memory _wkn)
        public
        onlyRegistrar
        {
        require(
            SecuritiesRegister[_tokenID].regulatorApproval == false
        );
        
        return setTermSheet(
            _tokenID, 
            _tokenTerms, 
            _isin,
            _wkn, 
            "");
    }
    
    function setTermSheet(
        uint _tokenID,
        string [] memory _tokenTerms,
        string memory _isin,
        string memory _wkn,
        string memory _itin)
        public
        onlyRegistrar
        {
        require(
            SecuritiesRegister[_tokenID].regulatorApproval == false
        );
            
        SecuritiesRegister[_tokenID].termsheet.TokenTerms = _tokenTerms;
        SecuritiesRegister[_tokenID].termsheet.ISIN = _isin;
        SecuritiesRegister[_tokenID].termsheet.WKN = _wkn;
        SecuritiesRegister[_tokenID].termsheet.ITIN = _itin;
        
        emit TermSheetEntry(
            _tokenID, 
            _tokenTerms, 
            _isin, 
            _wkn, 
            _itin
            );
    }
    
    function setIssuerInformation(
        uint _tokenID,
        string memory _issuer,
        string memory _rating)
        public
        onlyRegistrar
        {
        SecuritiesRegister[_tokenID].issuer = _issuer;
        SecuritiesRegister[_tokenID].rating = _rating;
    }
    
    function setInvestorInformation(
        uint [] memory _tokenIDs,
        address _investor,
        bytes32 [] memory _disposalRestrictions,
        bytes32 [] memory _thirdPartyRights,
        bytes32 [] memory _otherDisposalRestrictions,
        bytes32 [] memory _legalCapacityOwner,
        bytes32 [] memory _summary)
        public
        onlyRegistrar
        {
        for (uint i=0; i< _tokenIDs.length; i++) {
            SecuritiesRegister[_tokenIDs[i]].InvestorInformation[_investor].DisposalRestrictions = _disposalRestrictions;
            SecuritiesRegister[_tokenIDs[i]].InvestorInformation[_investor].ThirdPartyRights = _thirdPartyRights;
            SecuritiesRegister[_tokenIDs[i]].InvestorInformation[_investor].OtherDisposalRestrictions = _otherDisposalRestrictions;
            SecuritiesRegister[_tokenIDs[i]].InvestorInformation[_investor].LegalCapacityOwner = _legalCapacityOwner;
        }
        
        emit ChangeOfRegisterInvestorData(
            _investor,
            _summary,
            block.timestamp
            );
    }
    
    function setDataComplete(
        uint _tokenID)
        public
        onlyRegistrar
        {
        SecuritiesRegister[_tokenID].dataComplete = true;
    }
    
    function setRegulatoryApproval(
        uint _tokenID)
        public
        onlyRegulator
        {
        require(
            SecuritiesRegister[_tokenID].dataComplete == true
            );
        SecuritiesRegister[_tokenID].regulatorApproval = true;
    }
    
    // View functions
    
    function balanceOf(
        uint _tokenID, 
        address _addr)
        external
        view
        returns(uint) 
        {
        require(
            msg.sender == _addr || 
            msg.sender == owner() || 
            msg.sender == Registrar || 
            BTC == Bond(msg.sender), 
            "You are not allowed to view this!"
        );
        
        return SecuritiesRegister[_tokenID].InvestorInformation[_addr].balanceOf;    
    }
    
    function dataComplete(
        uint _tokenID)
        external
        view
        onlyContract
        returns(bool)
        {
        return (SecuritiesRegister[_tokenID].dataComplete && 
            SecuritiesRegister[_tokenID].regulatorApproval);     
    }
    
    function returnTokenDataOne(
        uint _tokenID)
        external
        view
        onlyContract
        returns(uint, uint, uint, uint)
        {
        
        return (
            SecuritiesRegister[_tokenID].volume, 
            SecuritiesRegister[_tokenID].parValueETHER,
            SecuritiesRegister[_tokenID].parValueEUR,
            SecuritiesRegister[_tokenID].coupon
            );     
    }
    
    function returnTokenDataTwo(
        uint _tokenID)
        external
        view
        onlyContract
        returns(uint256, uint256)
        {
        
        return (
            SecuritiesRegister[_tokenID].settlementDate,
            SecuritiesRegister[_tokenID].maturityDate
            );     
    }
    
    function returnTokenDistribution(
        uint _tokenID)
        public
        view
        returns(
            uint256 SingleEntryAmount, 
            uint256 CollectiveEntryAmount)
        {
        return (
            SecuritiesRegister[_tokenID].investorstructure.AmountSingleEntry, 
            SecuritiesRegister[_tokenID].investorstructure.AmountCollectiveEntry
            );    
    }
    
    // Functions for CSR-Update
    
    function updateCSRbyContractBuy(
        uint _tokenID, 
        address _addr, 
        uint _amount)
        external
        onlyContract
        {
        
        uint investorType = KYC.returnInvestorType(_addr);
        
        SecuritiesRegister[_tokenID].InvestorInformation[_addr].balanceOf += _amount;
        
        if (investorType == 0) {
            SecuritiesRegister[_tokenID].investorstructure.AmountSingleEntry += _amount;
        }
        
        if (investorType == 1) {
            SecuritiesRegister[_tokenID].investorstructure.AmountCollectiveEntry += _amount;
        }
        
        emit ChangeOfRegisterInvestorBalance (
            block.timestamp, 
            msg.sender, 
            _tokenID, 
            _addr, 
            _amount);
    }
    
    function updateCSRbyContractSell(
        uint _tokenID, 
        address _addr, 
        uint _amount)
        external
        onlyContract
        {
        
        uint investorType = KYC.returnInvestorType(_addr);
        
        SecuritiesRegister[_tokenID].InvestorInformation[_addr].balanceOf -= _amount;
            
        if (investorType == 0) {
            SecuritiesRegister[_tokenID].investorstructure.AmountSingleEntry -= _amount;
        }
        
        if (investorType == 1) {
            SecuritiesRegister[_tokenID].investorstructure.AmountCollectiveEntry -= _amount;
        }
        
        emit ChangeOfRegisterInvestorBalance (
            block.timestamp, 
            msg.sender, 
            _tokenID, 
            _addr, 
            _amount);
    }
    
    // Exemplary functions for changing or deleting data in the register for a specific token (neither complete nor conclusive)
    
    function changeTokenTermSheetProposal(
        uint _tokenID,
        string [] memory _tokenTerms,
        string memory _isin,
        string memory _wkn,
        string memory _itin,
        string [] memory _summary) 
        public
        onlyRegistrar
        {
        require(
            SecuritiesRegister[_tokenID].regulatorApproval == false
            );
            
        TermSheetProposal[_tokenID].tokenTerms = _tokenTerms;
        TermSheetProposal[_tokenID].isin = _isin;
        TermSheetProposal[_tokenID].wkn = _wkn;
        TermSheetProposal[_tokenID].itin = _itin;
        
        if (msg.sender == owner()) {
            approveChangeTokenTermSheet(_tokenID, _summary);
        }
    }
    
    mapping (uint => changeTokenTermSheetProposalData) private TermSheetProposal;
    
    struct changeTokenTermSheetProposalData {
        string [] tokenTerms;
        string isin;
        string wkn;
        string itin;
    }
    
    function viewTokenTermSheetProposal(
        uint _tokenID)
        public
        view
        onlyOwner
        returns (
            string [] memory,
            string memory, 
            string memory, 
            string memory)
        {
        return (
            TermSheetProposal[_tokenID].tokenTerms,
            TermSheetProposal[_tokenID].isin,
            TermSheetProposal[_tokenID].wkn,
            TermSheetProposal[_tokenID].itin);    
    }
    
    function approveChangeTokenTermSheet(
        uint _tokenID, 
        string [] memory _summary)
        public
        onlyOwner
        {
            
        setTermSheet(
            _tokenID,
            TermSheetProposal[_tokenID].tokenTerms,
            TermSheetProposal[_tokenID].isin,
            TermSheetProposal[_tokenID].wkn,
            TermSheetProposal[_tokenID].itin);
            
        delete TermSheetProposal[_tokenID];
        
        emit ChangeOfRegister (
            _tokenID, 
            _summary,
            block.timestamp
            );
    }
}