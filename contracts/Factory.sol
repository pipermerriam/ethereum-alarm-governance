import {transferableInterface, transferable} from "contracts/owned.sol";


contract FactoryInterface is transferableInterface {
    event Deployed(address addr);

    function deployContract(address creator) public onlyowner returns (address);
    function buildContract(address creator) internal returns (address);
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

    function deployContract(address creator) public onlyowner returns (address) {
        var addr = buildContract(creator);
        Deployed(addr);
        return addr;
    }
}
