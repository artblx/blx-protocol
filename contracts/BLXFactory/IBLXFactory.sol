pragma solidity ^0.5.0;

interface IBLXFactory {
    function isValidUtilityContract(address test)
        external view returns(bool);
}
