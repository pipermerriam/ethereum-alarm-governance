import {transferableInterface, transferable} from "contracts/owned.sol";


contract FactoryOwnerInterface {
    function submitMotion(address _address) public;
}


contract FactoryInterface is transferableInterface {
    event Constructed(address addr, bytes32 argsHash);

    function submitMotion(address _address) internal {
        FactoryOwnerInterface(owner).submitMotion(_address);
    }
}


contract FactoryBase is transferable, FactoryInterface {
    // The URI where the source code for this contract can be found.
    string public sourceURI;
    // The compiler version used to compile this contract.
    string public compilerVersion;
    // The compile flags used during compilation.
    string public compilerFlags;

    function FactoryBase(string _sourceURI, string _compilerVersion, string _compilerFlags) {
        sourceURI = _sourceURI;
        compilerVersion = _compilerVersion;
        compilerFlags = _compilerFlags;
    }
}
