pragma solidity ^0.4.0;

contract Erc165 {
  bytes4 public constant INTERFACE_SIGNATURE = bytes4('');

  /// Check if interface is supported by contract
  /// @param _interfaceId description of interface.
  /// @return True if interface hash is supported.
  function supportsInterface(bytes4 _interfaceId)
      public
      pure
      returns (bool)
  {
      return (_interfaceId == INTERFACE_SIGNATURE);
  }
}
