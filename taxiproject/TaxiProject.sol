pragma solidity >=0.7.0 <0.9.0;

contract TaxiProject{
    struct Participant{
        address addr;
        uint balance;
        bool approved_driver;     //used bools to check if a participant is trying to aprrove more than once
        bool approved_purchase;
    }
    
    struct TaxiDriver{
        address driver_addr;
        uint salary;            //used the same approval_state variable both for hiring and firing process
        uint approval_state;
        uint account;
    }

    struct ProposedCar{
        uint CarID;
        uint price;
        uint offer_valid_time;  //usedthe same struct both for purchasing and repurchasing
        uint approval_state;
        uint proposal_time;
    }

//variables for fixed values and initializations of some structs that will be used 
    uint OwnedCarID;
    uint participation_fee;
    uint six_month_expense;
    uint contract_balance;
    ProposedCar proposed_car;
    ProposedCar proposed_car_sell;
    TaxiDriver proposed_taxi_driver;
    TaxiDriver taxi_driver;

//time variables                                    used block.timestamp() function for getting the second value when function is called, later looked if the difference between second values are enough
    uint taxi_driver_last_salary;
    uint car_last_expense;
    uint dividend_last_paid;

    address payable car_dealer;

    Participant[] participants;         //participant array for paydividend and getdivide
                                       //also used for finding the participant count
    constructor(address payable cd_address){
        participation_fee = 100 ether;
        six_month_expense = 10 ;
        contract_balance = 0;
        car_dealer = cd_address;
        dividend_last_paid = block.timestamp;
    }

    function resetDriverApprove() private{
        for(uint i = 0; i < participants.length; i++){
            participants[i].approved_driver = false;        //these are to be used when a driver or car change occurs, in case there is 
        }                                                   //a new proposal approval states in the structs gets reseted
    }

    function resetPurchaseApprove() private{
        for(uint i = 0; i < participants.length; i++){
            participants[i].approved_purchase = false;
        }
    }

    function isParticipant(address addr) private returns(bool){
        for(uint i = 0; i < participants.length; i++){
            if (participants[i].addr == addr){                              
                return true;
            }
        }
        return false;
    }

    function join() public payable {
        require(participants.length < 9, "Contract is full.");
        require(msg.value == participation_fee, "Participation fee is not provided properly.");

        participants.push(Participant(msg.sender, 0, false, false));
        contract_balance += participation_fee;
    }

    function carProposeToBusiness(uint CarID, uint price, uint offer_valid_time, uint approval_state) public{
        require(msg.sender == car_dealer, "Only Car Dealer can call this function.");
        proposed_car = ProposedCar(CarID, price, offer_valid_time, approval_state, block.timestamp);
    }

    function approvePurchaseCar() public{
        require(isParticipant(msg.sender), "Only participants can call this function.");
        uint index;
        for(uint i = 0; i < participants.length; i++){
            if (participants[i].addr == msg.sender){
                index = i;
            }
        }
        require(participants[index].approved_driver == false, "Can't approve more than once.");
        proposed_car.approval_state++;
        participants[index].approved_driver = true;
        if(proposed_car.approval_state > (participants.length / 2)){
            purchaseCar();
        }
    }

    function purchaseCar() private{
        require(block.timestamp - proposed_car.proposal_time <= proposed_car.offer_valid_time, "Offer is not valid anymore.");
        car_dealer.transfer(proposed_car.price * (10**18));
        OwnedCarID = proposed_car.CarID;
        contract_balance -= proposed_car.price;
        car_last_expense = block.timestamp;
        resetPurchaseApprove();
    }


     function repurchaseCarPropose(uint CarID, uint price, uint offer_valid_time, uint approval_state) public{
        require(msg.sender == car_dealer, "Only Car Dealer can call this function.");
        proposed_car_sell = ProposedCar(CarID, price, offer_valid_time, approval_state, block.timestamp);
    }

    function approveSellProposal() public{
        require(isParticipant(msg.sender), "Only participants can call this function.");
        uint index;
        for(uint i = 0; i < participants.length; i++){
            if (participants[i].addr == msg.sender){
                index = i;
            }
        }
        require(participants[index].approved_purchase == false, "Can't approve more than once.");
        proposed_car_sell.approval_state++;
        participants[index].approved_purchase = true;
        if(proposed_car_sell.approval_state > (participants.length / 2)){
            repurchaseCar();
        }
    }

    function repurchaseCar() private{
        require(block.timestamp - proposed_car_sell.proposal_time <= proposed_car_sell.offer_valid_time, "Offer is not valid anymore.");
        car_dealer.transfer(proposed_car_sell.price * (10**18));
        OwnedCarID = 0;
        contract_balance += proposed_car_sell.price;
        resetPurchaseApprove();
    }

    function proposeDriver(uint salary) public {
        proposed_taxi_driver = TaxiDriver(msg.sender, salary, 0, 0);
    }

    function approveDriver() public {
        require(isParticipant(msg.sender), "Only participants can call this function.");
        uint index;
        for(uint i = 0; i < participants.length; i++){
            if (participants[i].addr == msg.sender){
                index = i;
            }
        }
        require(participants[index].approved_driver == false, "Can't approve more than once.");
        proposed_taxi_driver.approval_state++;
        participants[index].approved_driver = true;
        if(proposed_taxi_driver.approval_state > (participants.length / 2)){
            setDriver();
        }
    }

    function setDriver() private{
        taxi_driver = TaxiDriver(proposed_taxi_driver.driver_addr, proposed_taxi_driver.salary, 0, 0);
        taxi_driver_last_salary = block.timestamp;
        resetDriverApprove();
    }


    function proposeFireDriver() public{
        require(isParticipant(msg.sender), "Only participants can call this function.");
        uint index;
        for(uint i = 0; i < participants.length; i++){
            if (participants[i].addr == msg.sender){
                index = i;
            }
        }
        require(participants[index].approved_driver == false, "Can't approve more than once.");
        taxi_driver.approval_state++;
        participants[index].approved_driver = true;
        if(taxi_driver.approval_state > (participants.length / 2)){
            fireDriver();
        }
    }

    function fireDriver() private{
        delete taxi_driver;
        resetDriverApprove();
    }

    function leaveJob() public{
        require(msg.sender == taxi_driver.driver_addr, "Only driver can call this function.");
        fireDriver();
    }

    function getSalary() public{
        require(msg.sender == taxi_driver.driver_addr, "Only driver can call this function.");
        require(block.timestamp - taxi_driver_last_salary >= 2592000, "Salary time has not come yet.");
        taxi_driver_last_salary = block.timestamp;
        taxi_driver.account += taxi_driver.salary;
        payable(taxi_driver.driver_addr).transfer(taxi_driver.account * (10 ** 18));
        taxi_driver.account = 0;
        contract_balance -= taxi_driver.salary;
    }

    function getCharge() public payable{
        contract_balance += msg.value;
    }


    function carExpenses() public {
        require(isParticipant(msg.sender), "Only participants can call this function.");
        require(block.timestamp - car_last_expense >= 15552000, "Car expense time has not come yet.");
        car_dealer.transfer(six_month_expense * (10**18));
        contract_balance -= six_month_expense;
        car_last_expense = block.timestamp;
    }

    function payDividend() public {
        require(isParticipant(msg.sender), "Only participants can call this function.");
        require(block.timestamp - dividend_last_paid >= 15552000, "Can't call before 6 months.");
        uint temp_balance = contract_balance;
        if(block.timestamp - car_last_expense > 15552000){
            temp_balance -= six_month_expense / (10 * (10 ** 18));
        }
        if(block.timestamp - taxi_driver_last_salary > 2592000){
            temp_balance -= taxi_driver.salary;
        }

        temp_balance -= (participants.length * participation_fee) / (10 * (10 ** 18));  // temp_balance has only the profit value in it now

        uint dividend = temp_balance / participants.length;
        for(uint i = 0; i < participants.length; i++){
            participants[i].balance += dividend;
        }
        contract_balance -= temp_balance;
    }

    function getDividend() public {
        require(isParticipant(msg.sender), "Only participants can call this function.");
        for(uint i = 0; i < participants.length; i++){
            if(participants[i].addr == msg.sender){
                payable(msg.sender).transfer(participants[i].balance * (10 ** 18));
            }
        }
    }

    fallback () external payable {
        revert();
    }
}