// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/access/Ownable.sol";
import "./BondToken.sol";
import "./SecuritiesRegister.sol";

contract KycContract is Ownable {
    
    // Contracts
    
    Bond BTC;
    CSRContract CSR;
    
    // Functions for contract management
    
    function setBondTokenContract(
        address _addr)
        public
        onlyOwner
        {
        BTC = Bond(_addr);
    }
    
    function setCSRContract(address _addr)
        public
        onlyOwner
        {
        CSR = CSRContract(_addr);
    }
    
    // Modifier
    
    modifier onlyKycProvider {
        require(
            KycProvider[msg.sender] == true, 
            "You are not authorized!"
            );
        _;
    }
    
    modifier onlyContract {
        require(
            BTC == Bond(msg.sender) || CSR == CSRContract(msg.sender), 
            "Only a Contract can use this function!"
            );
        _;
    }
    
    // Entities
    
    mapping(address => bool) KycProvider;
    
    // Functions for entity management
    
    function setKycProvider(
        address _kycProvider)
        public
        onlyOwner
        {
        KycProvider[_kycProvider] = true;
    }
    
    function updateKycProvider(
        address _kycProvider, 
        bool _update) 
        public
        onlyOwner
        {
        KycProvider[_kycProvider] = _update;
    }
    
    // Variables
    
    mapping(address => InvestorInfo) private Whitelist;
    
    struct InvestorInfo {
        bool whitelisted;
        uint investorType; // 0 stands for retail, 1 for institutional
    }
    
    // Functions
    
    function setKycCompleted(
        address _investor,
        uint _investorType)
        public
        onlyKycProvider
        {
        require(
            _investorType == 0 || _investorType == 1,
            "Not a valid investorType!"
            );    
        Whitelist[_investor].whitelisted = true;
        Whitelist[_investor].investorType = _investorType;
    }
    
    function setKycRevoked(
        address _investor)
        public
        onlyKycProvider
        {
        Whitelist[_investor].whitelisted = false;
    }
    
    function kycCompleted(
        address _investor)
        external 
        view
        onlyContract
        returns(bool)
        {
        return Whitelist[_investor].whitelisted;
    }
    
    function returnInvestorType(
        address _investor)
        external
        view
        onlyContract
        returns(uint)
        {
        return Whitelist[_investor].investorType;        
    }
    
}