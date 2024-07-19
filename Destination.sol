// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BridgeToken.sol";

contract Destination is AccessControl {
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    mapping(address => address) public underlying_tokens;
    mapping(address => address) public wrapped_tokens;
    address[] public tokens;

    event Creation(address indexed underlying_token, address indexed wrapped_token);
    event Wrap(address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount);
    event Unwrap(address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CREATOR_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);
    }

    function createToken(address _underlying_token, string memory name, string memory symbol) public onlyRole(CREATOR_ROLE) returns (address) {
        // Check if the token is already registered
        require(wrapped_tokens[_underlying_token] == address(0), "Token already registered");

        // Create a new BridgeToken contract
        BridgeToken newToken = new BridgeToken(_underlying_token, name, symbol, msg.sender);

        // Store the addresses in the mappings
        underlying_tokens[address(newToken)] = _underlying_token;
        wrapped_tokens[_underlying_token] = address(newToken);

        // Add the new token to the list
        tokens.push(address(newToken));

        // Emit the Creation event
        emit Creation(_underlying_token, address(newToken));

        // Return the address of the new token
        return address(newToken);
    }

    function wrap(address _underlying_token, address _recipient, uint256 _amount) public onlyRole(WARDEN_ROLE) {
        // Check if the token is registered
        address wrapped_token = wrapped_tokens[_underlying_token];
        require(wrapped_token != address(0), "Token not registered");

        // Mint the wrapped tokens
        BridgeToken(wrapped_token).mint(_recipient, _amount);

        // Emit the Wrap event
        emit Wrap(_underlying_token, wrapped_token, _recipient, _amount);
    }

    function unwrap(address _wrapped_token, address _recipient, uint256 _amount) public {
        BridgeToken wrappedToken = BridgeToken(_wrapped_token);

        // Check if the sender has enough balance
        require(wrappedToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");

        // Check if the wrapped token is registered
        address underlying_token = underlying_tokens[_wrapped_token];
        require(underlying_token != address(0), "Token not registered");

        // Burn the wrapped tokens
        wrappedToken.burnFrom(msg.sender, _amount);

        // Emit the Unwrap event
        emit Unwrap(underlying_token, _wrapped_token, msg.sender, _recipient, _amount);
    }
}
