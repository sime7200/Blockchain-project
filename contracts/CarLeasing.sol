// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFT for BilBoyd's cars
 * @notice This contract allows to create BilBoyd's fleet of cars
 */
contract CarLeasing is ERC721, Ownable {

    // Structure to represent a car
    struct Car {
        uint256 id;                 // Car id
        string model;               // Car model
        string color;               // Car color
        uint16 year;                // Car production year
        uint40 originalValue;       // Car original value
        uint40 currentMileage;      // Car current mileage
    }

    // Structure to represent a lease
    struct Lease {
        uint40 monthlyQuota;       // Monthly lease payment
        uint40 mileageCap;         // Mileage cap for the lease
        uint8 contractDuration;    // Duration of the lease contract in years
        uint8 driverExperience;    // Driver's experience level
        bool isActive;             // Lease active status
        bool isExtended;           // Lease extension status
        address lessee;            // Address of the lessee
        uint256 startTime;         // Start time of the lease
        uint256 nextDueTime;       // Next payment due time
        uint256 extensionTime;     // Time of last successful extention
    }

    // Counter to generate the next car ID
    uint256 private _nextCarId;
    // Mapping from car ID to Car details
    mapping(uint256 => Car) private _cars;

    // Mapping from car ID to lease details
    mapping(uint256 => Lease) public _leases;

    // Array of possible mileage caps
    uint40[] private _mileageCaps = [10000, 20000, 30000, 40000];
    // Array of possible contract durations
    uint8[] private _contractDurations = [1, 2, 3, 4];

    uint256 _YEAR = 12 * 30 days;
    uint256 _MONTH = 30 days;
    uint256 _CUSTOMER_EXTENSION_WINDOW = 5 days;
    uint256 _CUSTOMER_OPTIONS_WINDOW = 10 days;

    /**
     * @notice Constructor to initialize the ERC721 token with a name and symbol, and set the initial owner
     * @param initialOwner The address of the initial owner of the contract
     */
    constructor(address initialOwner)
        ERC721("BilBoydCars", "BBC")
        Ownable(initialOwner)
    {}

    /**
     * @notice Function to safely mint a new Car token
     * @dev Only the owner of the contract can call this function. The new NFT is assigned to the contract owner.
     * @param model The model of the car
     * @param color The color of the car
     * @param year The manufacturing year of the car
     * @param originalValue The original value of the car
     * @param currentMileage The current mileage of the car
     */
    function safeCarMint(
        string memory model,
        string memory color,
        uint16 year,
        uint40 originalValue,
        uint40 currentMileage
    ) public onlyOwner {
        _cars[_nextCarId] = Car(_nextCarId, model, color, year, originalValue, currentMileage);
        _safeMint(owner(), _nextCarId);
        ++_nextCarId;
    }

    /**
     * @notice Function to retrieve all the available cars
     * @dev Returns an array of all cars available for leasing.
     * @return carsList An array of all cars where each car contains the model, color, year of matriculation, original value, and current mileage.
     */
    function getAllAvailableCars() public view returns (Car[] memory) {        
        Car[] memory carsList = new Car[](_nextCarId);
        uint256 i;

        for (uint256 id; id < _nextCarId; ++id) {
            if (ownerOf(id) == owner()) {
                carsList[i] = _cars[id];
            }
        }
        return carsList;
    }

    /**
     * @notice Retrieves the available mileage caps
     * @return An array of possible mileage caps
     */
    function getMileageCaps() public view returns (uint40[] memory) {
        return _mileageCaps;
    }

    /**
     * @notice Retrieves the available contract durations
     * @return An array of possible contract durations
     */
    function getContractDurations() public view returns (uint8[] memory) {
        return _contractDurations;
    }

    /**
     * @notice Checks if the provided mileage is valid
     * @param mileage The mileage cap to check
     * @return True if the mileage cap is valid, false otherwise
     */
    function isValidMileage(uint40 mileage) private view returns (bool) {
        for (uint8 i; i < _mileageCaps.length; ++i) {
            if (mileage == _mileageCaps[i]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Checks if the provided contract duration is valid
     * @param contractDuration The contract duration to check
     * @return True if the contract duration is valid, false otherwise
     */
    function isValidContractDuration(uint8 contractDuration) private view returns (bool) {
        for (uint8 i; i < _contractDurations.length; ++i) {
            if (_contractDurations[i] == contractDuration) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Calculates the monthly quota for leasing a car
     * @param carId The ID of the car
     * @param driverExperience The experience level of the driver
     * @param mileageCap The mileage cap selected
     * @param contractDuration The duration of the contract in years
     * @return The monthly quota amount
     */
    function calculateMonthlyQuota(
        uint256 carId, 
        uint8 driverExperience,
        uint40 mileageCap, 
        uint8 contractDuration
    ) public view returns (uint40) {
        require(isValidMileage(mileageCap), "Invalid mileage cap selected");
        require(isValidContractDuration(contractDuration), "Invalid contract duration selected");

        Car storage car = _cars[carId];
        /**
        * (car.originalValue * 108) / (10_000 + car.currentMileage) relation of original to been used (hardcoded numbers to correct proportion)
        * + (((45 * mileageCap * car.originalValue) / contractDuration ) / 1e8) benefitting a longer contract (hardcoded numbers to correct proportion)
        * - 8 * driverExperience benefitting a longer experience
        */
        return ((car.originalValue * 108) / (10_000 + car.currentMileage)) + (((45 * mileageCap * car.originalValue) / contractDuration ) / 1e8) - 8 * driverExperience;
    }

    /**
    * @notice Function to register a new leasing deal for a car
    * @dev The caller must send the correct down payment amount to register the deal. The car must be available (owned by the owner of contract).
    * @param carId The ID of the car to lease
    * @param driverExperience The experience level of the driver
    * @param mileageCap The selected mileage cap for the lease
    * @param contractDuration The duration of the lease contract in years
    * @return The ID of the car being leased
    */
    function registerDeal(
        uint256 carId,
        uint8 driverExperience,
        uint40 mileageCap, 
        uint8 contractDuration
    ) public payable returns (uint256) {
        require(ownerOf(carId) == owner(), "Car not available");
        uint40 monthlyQuota = calculateMonthlyQuota(
            carId,
            driverExperience,
            mileageCap,
            contractDuration
        );
        uint256 downPayment = monthlyQuota * 4; // 3 monthly quotas + first month's quota
        require(msg.value == downPayment, "Incorrect down payment");

        // Store lease information
        _leases[carId] = Lease(monthlyQuota, mileageCap, contractDuration, driverExperience, false, false, msg.sender, 0, 0, 0);

        return carId;
    }

 /**
     * @notice Confirms a leasing deal for a car
     * @dev This function can only be called by the owner of the contract. It transfers the car NFT to the lessee and transfers the down payment to the owner.
     * @param leaseId The ID of the lease to be confirmed
     * @return True if the deal is confirmed
     */
    function confirmDeal(uint256 leaseId) public onlyOwner returns (bool) {
        Lease storage lease = _leases[leaseId];
        require(!lease.isActive, "Deal already confirmed");

        // Transfer car NFT to the lessee
        _transfer(owner(), lease.lessee, leaseId);

        // Transfer down payment to the owner
        payable(owner()).transfer(lease.monthlyQuota * 4);

        lease.isActive = true;
        lease.startTime = block.timestamp;
        lease.nextDueTime = lease.startTime + _MONTH;
        return true;
    }

    /**
     * @notice Allows the lessee to pay the monthly quota
     * @dev The payment should be done up to the due date. If it's the first payment of an extension, the customer has _CUSTOMER_EXTENSION_WINDOW days to do it.
     * @param leaseId The ID of the lease for which the payment is made
     * @return True if the payment is successful
     */
    function payMonthlyQuota(uint256 leaseId) public payable returns (bool) {
        uint256 time = block.timestamp;
        Lease storage lease = _leases[leaseId];
        require(lease.isActive, "Lease not active");
        require(msg.sender == lease.lessee, "Not the lessee");

        // Check if customer extended the contract and reset flag
        if (lease.extensionTime != 0) {
            // Check if the customer is still in time to pay for the extension
            require(time <= lease.extensionTime + _CUSTOMER_EXTENSION_WINDOW, "Overdue payment");
            // Set variable to 0 to indicate the waiting for the extension payment is ended. This prevents termination of lease when checking of been insolvent
            lease.extensionTime = 0;
        } else {
            // Contract ended and therefore does not accept any payment anymore
            require(lease.nextDueTime < lease.startTime + lease.contractDuration * _YEAR, "Contract ended");
            // Payment not done -> leads to termination of contract
            require(time <= lease.nextDueTime, "Overdue payment");
        }

        require(msg.value == lease.monthlyQuota, "Incorrect amount");

        // Increase due date for customer to be able to continue with contract, else it would terminate in the check of insolvent
        lease.nextDueTime += _MONTH;
        payable(owner()).transfer(msg.value);
        return true;
    }


    /**
     * @notice Allows the owner to terminate the lease for insolvent customer
     * @dev This function can be called after the due date has passed. For the first payment of an extension, it can be called after the time given to cumtomers to pay the quota.
     * @param leaseId The ID of the lease to be terminated
     * @return True if the customer is insolvent
     */
    function isInsolvent(uint256 leaseId) public onlyOwner returns (bool) {
        Lease storage lease = _leases[leaseId];
        require(lease.isActive, "Lease not active");

        uint256 time = block.timestamp;
        // Check if customer extended the contract 
        if (lease.extensionTime != 0) {
            // Customer has _CUSTOMER_EXTENSION_WINDOW days since the extension date to pay for the first month of the extension 
            require(time > lease.extensionTime + _CUSTOMER_EXTENSION_WINDOW, "Insolvent customer check not available");
        } else {
            // Check if the customer has payed and the contract is not ended
            require(time > lease.nextDueTime && lease.nextDueTime < lease.startTime + lease.contractDuration * _YEAR , "Insolvent customer check not available");
        }
        // Terminate lease due to non-payment
        terminateLease(leaseId);
        return true;
    }

    /**
     * @notice Provides options at the end of the lease
     * @dev Lessee can choose to terminate, extend, or sign a new lease for another vehicle.
     * @param leaseId The ID of the lease
     * @param option The option chosen (1 for termination, 2 for extension, 3 for new lease)
     * @return The result of the option chosen. For option 2 it returns the new computed monthly quota
     */
    function endOfLeaseOption(uint256 leaseId, uint8 option) public returns (uint40) {
        Lease storage lease = _leases[leaseId];
        require(lease.isActive, "Lease not active");
        require(msg.sender == lease.lessee, "Not the lessee");
        uint256 time = block.timestamp;
        require(time > lease.startTime + (lease.contractDuration * _YEAR), "Lease period not yet ended");

        // Assumption that the customer used the car till the cap
        _cars[leaseId].currentMileage += lease.mileageCap;

        if (option == 1) {
            // Terminate the contract
            terminateLease(leaseId);
            return 1;
        } else if (option == 2) {
            // Extend lease by one year
            lease.contractDuration += 1; // Add 1 year
            // Add the experience gathered during the contract, if this contract was entended it only adds 1 to prevent wrong addition
            lease.driverExperience = lease.isExtended ? lease.driverExperience + 1 : lease.driverExperience + lease.contractDuration;
            uint40 newQuota = calculateMonthlyQuota(
                leaseId,
                lease.driverExperience,
                lease.mileageCap,
                lease.contractDuration
            );
            lease.monthlyQuota = newQuota;
            lease.isExtended = true;
            lease.extensionTime = time;
            return newQuota;
        } else if (option == 3) {
            // Sign a lease for a new vehicle
            terminateLease(leaseId);
            // Lessee can initiate a new deal for another car
            getAllAvailableCars();
            return 3;
        } else {
            revert("Invalid option");
        }
    }

    /**
     * @notice Allows the owner to forcefully end a lease
     * @dev This function can be called if the lease has ended and the customer didn't choose an option by _CUSTOMER_OPTIONS_WINDOW days.
     * @param leaseId The ID of the lease to be forcefully ended
     * @return True if the lease is forcefully ended
     */
    function forceEnd(uint256 leaseId) public onlyOwner returns (bool) {
        Lease storage lease = _leases[leaseId];
        require(lease.isActive, "Lease not active");
        uint256 time = block.timestamp;
        // Car can only be retrieved if the contract ended as well as the time to choose an option. 
        require(lease.extensionTime == 0 && time > lease.startTime + (lease.contractDuration * _YEAR) + _CUSTOMER_OPTIONS_WINDOW, "Force contract end not available");

        // Call function to retrieve car back and deactivate the contract
        terminateLease(leaseId);
        return true;
    }

    /**
     * @notice Internal function to terminate a lease
     * @dev This function transfers the car back to the contract owner and marks the lease as inactive.
     * @param carId The ID of the car whose lease is to be terminated
     */
    function terminateLease(uint256 carId) private {
        Lease storage lease = _leases[carId];

        // Transfer car back to the contract owner
        _transfer(lease.lessee, owner(), carId);
        // Set variable to false, so the contract can't be modified
        lease.isActive = false;
    }
}
