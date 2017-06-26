pragma solidity ^0.4.8;

contract Registry {
	address private admin;
	mapping (bytes32 => address) private registry;  // Maps a serial number hash to its setup address (later wallet)
	mapping (bytes32 => address) private owners;    // Maps the serial hash to the owner
	/*event Register(bytes32 indexed serial_hash, uint timestamp);
	event Wallet(address indexed agent, address indexed wallet, uint timestamp);
	event Claim(bytes32 indexed serial_hash, address indexed owner, uint timestamp);*/

	function Registry() {
		admin = msg.sender;
	}

	// OWNER only
	// =========================

	function transferAdmin(address new_admin) isAdmin() returns (bool) {
		admin = new_admin;
		return true;
	}

	// Register a agent address. This can only be called by the admin.
	// This must be called before a agent is turned online.
	// The serial hash is a keccak_256 hash of the serial number.
	function register(address agent, bytes32 serial_hash) isAdmin() returns (bool) {
		if (registry[serial_hash] != address(0)) { throw; }
		registry[serial_hash] = agent;
		/*Register(serial_hash, now);*/
		return true;
	}

	// SETTERS
	// =========================

	// Set a wallet for a given agent. Must be called by the setup key.
	//
	// This will overwrite all functionality for the setup key and essentially transfer
	// all agency to the new wallet key.
	function setWallet(address wallet, bytes32 serial_hash) public returns (bool) {
		if (registry[serial_hash] == address(0)) { throw; }
		else if (registry[serial_hash] != msg.sender) { throw;}
		// Transfer registration to the new wallet
		registry[serial_hash] = wallet;
		/*Wallet(msg.sender, wallet, now);*/
		return true;
	}

	// Claim ownership of an agent with a verifiable keccak_256 hash of the serial number.
	// The agent must be registered and may not have been claimed by anyone else.
	//
	// A wallet key must also have been set. That wallet key is what is being claimed.
	function claim(bytes32 serial_hash) public returns (bool) {
		if (registry[serial_hash] == address(0)) { throw; }
		else if (owners[serial_hash] != address(0)) { throw; }
		owners[serial_hash] = msg.sender;
		/*Claim(serial_hash, msg.sender, now);*/
		return true;
	}

	// PUBLIC constant functions
	// =========================

	// Check if the agent is registered.
	function registered(bytes32 serial_hash) public constant returns (bool) {
		if (registry[serial_hash] == address(0)) { return false; }
		return true;
	}

	// Check if the agent has been claimed
	function claimed(bytes32 serial_hash) public constant returns (bool) {
		if (registry[serial_hash] == address(0)) { return false; }
		else if (owners[serial_hash] == address(0)) { return false; }
		else { return true; }
	}

	// Check if a specific address is mapped to the serial hash
	function check_registry(bytes32 serial_hash, address registrant) public constant returns (bool) {
		if (registry[serial_hash] == registrant) { return true; }
		return false;
	}

	// Check if a specific owner is mapped to the serial hash
	function check_owner(bytes32 serial_hash, address owner) public constant returns (bool) {
		if (owners[serial_hash] == owner) { return true; }
		return false;
	}

	// Given an owner and a serial_hash, get the wallet address
	function get_owner_wallet(bytes32 serial_hash, address owner) public constant returns (address) {
		if (owners[serial_hash] != owner) { throw; }
		return registry[serial_hash];
	}

	// Check if an address is the admin
	function checkAdmin(address addr) public constant returns (bool) {
		if (admin == addr) { return true; }
		else { return false; }
	}


	// MODIFIERS
	// ==========================
	modifier isAdmin() {
		if (msg.sender != admin) { throw; }
		_;
	}

	function() { throw; }
}
