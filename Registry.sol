pragma solidity ^0.4.8;

contract Registry {
	address private admin;
	mapping (address => bytes32) registry;  // Maps an address to a hash of its serial number
	mapping (address => address) wallets;   // Maps wallet address to an original setup address
	mapping (address => address) owners;    // Maps the wallet address to an owner
	event Register(address indexed agent, uint timestamp);
	event Wallet(address indexed agent, address indexed wallet, uint timestamp);
	event Claim(address indexed agent, address indexed owner, uint timestamp);

	function Registry() {
		admin = msg.sender;
	}

	// OWNER only
	// =========================

	// Register a agent address. This can only be called by the admin.
	// This must be called before a agent is turned online.
	// The serial hash is a keccak_256 hash of the serial number.
	function register(address agent, bytes32 serial_hash) isAdmin() returns (bool) {
		if (registry[agent] != bytes32(0)) { throw; }
		registry[agent] = serial_hash;
		Register(agent, now);
		return true;
	}

	// SETTERS
	// =========================

	// Set a wallet for a given agent. Must be called by the setup key.
	//
	// This will overwrite all functionality for the setup key and essentially transfer
	// all agency to the new wallet key.
	function setWallet(address wallet) public returns (bool) {
		if (registry[msg.sender] == bytes32(0)) { throw; }
		wallets[wallet] = msg.sender;
		// Transfer registration to the new wallet
		bytes32 serial_hash = registry[msg.sender];
		registry[msg.sender] = bytes32(0);
		registry[wallet] = serial_hash;
		Wallet(msg.sender, wallet, now);
		return true;
	}

	// Claim ownership of an agent with a verifiable keccak_256 hash of the serial number.
	// The agent must be registered and may not have been claimed by anyone else.
	//
	// A wallet key must also have been set. That wallet key is what is being claimed.
	function claim(address wallet, bytes32 serial_hash) public returns (bool) {
		if (registry[wallet] == bytes32(0)) { throw; }
		else if (owners[wallet] != address(0)) { throw; }
		else if (registry[wallet] != serial_hash) { throw; }
		else if (wallets[wallet] == address(0)) { throw; }
		owners[wallet] = msg.sender;
		Claim(wallet, msg.sender, now);
		return true;
	}

	// PUBLIC constant functions
	// =========================

	// Check if the agent is registered. Being registered essentially just means
	// being whitelisted to participate in the gridx network.
	function registered(address agent) public constant returns (bool) {
		if (registry[agent] == bytes32(0)) { return false; }
		else { return true; }
	}

	// Check if the wallet address has 1. been claimed, 2. been registered
	// param agent     The wallet address of the agent
	function claimed(address wallet) public constant returns (bool) {
		if (registry[wallet] == bytes32(0)) { return false; }
		else if (wallets[wallet] == address(0)) { return false; }
		else if (owners[wallet] == address(0)) { return false; }
		else { return true; }
	}

	// Get the agent's owner. An agent is identified by a setup key.
	function owner(address agent) public constant returns (address) {
		if (registry[agent] == bytes32(0)) { return 0x0; }
		return owners[agent];
	}

	// Get the serial number hash of a agent if you are the admin
	function getSerial(address agent) isAdmin() public constant returns (bytes32) {
		return registry[agent];
	}

	// MODIFIERS
	// ==========================
	modifier isAdmin() {
		if (msg.sender != admin) { throw; }
		_;
	}
}
