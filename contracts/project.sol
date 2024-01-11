// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RentACar {
    address public owner;

    struct Car {
        string carModel;
        address renter;
        uint256 rentStartTime;
    }

    struct RentalHistory {
        uint256 carId;
        uint256 rentStartTime;
        uint256 rentEndTime;
        uint256 rentCost;
    }

    mapping(uint256 => Car) public cars;
    mapping(address => RentalHistory[]) public rentalHistory;
    uint256 public totalCars;
    uint256 public rentalRate; // Rate in wei per hour

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRenter(uint256 carId) {
        require(msg.sender == cars[carId].renter, "Only renter can call this function");
        _;
    }

        modifier validCarId(uint256 carId) {
        require(carId < totalCars, "Invalid car ID");
        _;
    }

    event CarRented(uint256  carId, address  renter, uint256 rentStartTime);
    event CarReturned(
        uint256  carId,
        address  renter,
        uint256 rentEndTime,
        uint256 rentDuration,
        uint256 rentCost
    );

    event RentalRateSet(uint256 newRate);

    constructor() {
        owner = msg.sender;
        rentalRate = 1 ether; //rent po satu
    }

    function setRentalRate(uint256 newRate) external onlyOwner {
        rentalRate = newRate;
        emit RentalRateSet(newRate);
    }

    function addCar(string memory _carModel) external onlyOwner {
        uint256 carId = totalCars++;
        cars[carId] = Car({
            carModel: _carModel,
            renter: address(0),
            rentStartTime: 0
        });
    }

        function deleteCar(uint256 carId) external onlyOwner {
            require(cars[carId].renter == address(0), "Cannot delete a rented car");
            delete cars[carId];
            totalCars--; 
        }


    function rentCar(uint256 carId) external payable validCarId(carId) {
        require(cars[carId].renter == address(0), "Car is already rented");

        cars[carId].renter = msg.sender;
        cars[carId].rentStartTime = block.timestamp;

        emit CarRented(carId, msg.sender, block.timestamp);
    }

    function returnCar(uint256 carId) external onlyRenter(carId) validCarId(carId) {
        require(cars[carId].renter != address(0), "Car is not rented");

        uint256 rentEndTime = block.timestamp;
        uint256 rentDuration = rentEndTime - cars[carId].rentStartTime;
        uint256 rentCost = calculateRentCost(rentDuration);

        emit CarReturned(carId, msg.sender, rentEndTime, rentDuration, rentCost);

        rentalHistory[msg.sender].push(RentalHistory(carId, cars[carId].rentStartTime, rentEndTime, rentCost));

        payable(owner).transfer(rentCost);

        delete cars[carId];
    }

    function calculateRentCost(uint256 rentDuration) internal view returns (uint256) {
        return rentDuration * rentalRate;
    }

    function getRentDetails(uint256 carId) external view returns (string memory carModel, address renter, uint256 rentStartTime) {
        carModel = cars[carId].carModel;
        renter = cars[carId].renter;
        rentStartTime = cars[carId].rentStartTime;
    }

    function getRentalHistory() external view returns (RentalHistory[] memory) {
        return rentalHistory[msg.sender];
    }

    function getAvailableCars() external view returns (uint256[] memory availableCarIds) {
    uint256 count = 0;
    
    // Iterate through all cars
    for (uint256 i = 0; i < totalCars; i++) {
        // Check if the car is not rented
        if (cars[i].renter == address(0)) {
            count++;
        }
    }

    // Initialize the array to store available car IDs
    availableCarIds = new uint256[](count);

    // Reset count for array population
    count = 0;

    // Populate the array with available car IDs
    for (uint256 i = 0; i < totalCars; i++) {
        if (cars[i].renter == address(0)) {
            availableCarIds[count] = i;
            count++;
        }
    }

    return availableCarIds;
}




}
