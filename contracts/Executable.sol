import {transferableInterface, transferable} from "contracts/owned.sol";


contract ExecutableInterface is transferableInterface {
    // The URI where the source code for this contract can be found.
    string public sourceURI;
    // The compiler version used to compile this contract.
    string public compilerVersion;
    // The compile flags used during compilation.
    string public compilerFlags;

    // TODO: this needs to be defined for how multi-step execution works.
    function execute() public onlyowner;
}


contract ExecutableBase is transferable, ExecutableInterface {
    function ExecutableBase() {
    }
}
