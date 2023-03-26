// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract PlantProtection{
    address platformAdministratorAddr;
    //the information of the plant protection demand
    uint orderID;  
    address farmerAddress;         
    uint[2] fieldLocation;
    uint area;                
    uint[2] timeWindow;       
    string pesticideType;       
    uint[2] temperatureWindow;
    uint   dosageRequired;                
    //the information of the drone providing the service
    uint droneID;        
    address droneAddress; 
    //the information about the process of the service
    uint   createOrderTime;
    uint   updataOrderTime;
    enum  OrderState {
        waiting, heading, arrived, spraying, sprayed, completed, assessed
    }
    OrderState public state;
    uint[][] gpsSensor;       
    uint[] tempSensor;      
    uint[2] pressureSensor;
    uint   actualArrivedTime; 
    uint   actualStartTime;
    uint   actualEndTime;
    uint[][] sprayingGPS;
    uint   money;           
    uint   payTime;
    // the information about the farmer's assessment of the service     
    uint   satisfactionLevel;
    string assessmentMessage;    
    uint   assessmentTime;  

    // Modifiers for validation
    modifier onlyDrone(){  //only Drone
        require(msg.sender == droneAddress);
        _;
    }
    modifier onlyFarmer(){//only Farmer
        require(msg.sender == farmerAddress);
        _;
    }
    modifier costs(){  
        require(msg.value == money);
        _;
    }

    // event
    event DeploySuccessful(string msg);
    event DeployUnSuccessful(string msg);              
    event WaitingMsg(string msg);

    event HeadingMsg(string msg,address drone);       
    event ArrivedMsg(string msg,address drone);      
    event SprayingMsg(string msg,address drone);      
    event PayMoneyMsg(string msg,address drone);       
    event PaySuccessfulMsg(string msg,address farmer);  
    event PayUnSuccessfulMsg(string msg,address farmer);   
    event AssessmentMsg(string msg,address farmer); 

    event UpdateSuccessful(string msg); 
    event UpdateUnsuccessful(string msg);

   function  deploy(uint orderIdNum, uint[2] memory orderFieldLocation, uint orderArea, uint[2] memory orderTimeWindow, string memory orderPesticideType, uint[2] memory pesticideTempWindow, uint dosageReq, uint droneIdNum, address farmerAddr, address droneAddr) public{
        require(farmerAddress == address(0x0));
        if(farmerAddr != address(0x0) && droneAddr != address(0x0)){
            orderID = orderIdNum;                            
            fieldLocation = orderFieldLocation;      
            area = orderArea;                               
            timeWindow = orderTimeWindow;             
            pesticideType = orderPesticideType;                      
            temperatureWindow = pesticideTempWindow;      
            dosageRequired = dosageReq;      
            money = 50;                                      
            droneID = droneIdNum; 

            farmerAddress = farmerAddr;    
            droneAddress = droneAddr;
            platformAdministratorAddr = msg.sender;      

            state = OrderState.waiting;         
            createOrderTime = block.timestamp;              

            emit DeploySuccessful("Successful! The order has been created and is waiting for service.");
            emit WaitingMsg("The order is waiting to be served.");
        }else{
            emit DeployUnSuccessful("Wrong! The address of farmerAddr and droneAddr is wrong.");
        }
    }

    function deployNew(uint orderIdNum, uint newDroneIdNum, address newDroneAddr) public{
        require(platformAdministratorAddr == msg.sender);
        if(orderID == orderIdNum && newDroneAddr != address(0x0)){
            droneID = newDroneIdNum;         
            droneAddress = newDroneAddr;     
            state = OrderState.waiting;        
            updataOrderTime = block.timestamp; 
            emit UpdateSuccessful("Successful! This order information has been updated");
            emit WaitingMsg("The order is to be served.");
            }else{
                emit UpdateUnsuccessful("Wrong! The order redeployment failed");
            }                              
    }

    function heading(uint[2] memory gpsData) onlyDrone public{
        state = OrderState.heading;                  
        gpsSensor.push(gpsData); 
        emit HeadingMsg("The drone is heading.",msg.sender);
    }

    function droneArrived(uint[2] memory gpsData, uint dosagePressure) onlyDrone public{
        require(state == OrderState.heading);                  
        gpsSensor.push(gpsData); 
        pressureSensor[0] = dosagePressure;
        state = OrderState.arrived;  
        actualArrivedTime = block.timestamp;  
        emit ArrivedMsg("The drone has been arrived.",msg.sender);
    }

    function switchOn() onlyDrone public {
        require(state == OrderState.arrived);
        state = OrderState.spraying;      
        actualStartTime = block.timestamp;
        emit SprayingMsg("The drone starts spraying pesticides.",msg.sender);
    }

    function spraying(uint[2] memory gpsData,uint temperature) onlyDrone public{
        require(state == OrderState.spraying);
        sprayingGPS.push(gpsData); 
        tempSensor.push(temperature); 
        emit SprayingMsg("The drone is spraying pesticides.",msg.sender);
    }
    function switchOff(uint dosagePressure) onlyDrone public{
        require(state == OrderState.spraying);
        pressureSensor[1] = dosagePressure; 
        actualEndTime = block.timestamp;                     
        state = OrderState.sprayed;          
        emit PayMoneyMsg("The drone has finished spraying.",msg.sender);
    }
    
    function pay() onlyFarmer costs public payable{
        if(state == OrderState.sprayed){                  
            state = OrderState.completed;
            payTime = block.timestamp;      
            emit PaySuccessfulMsg("The order has been paid.",msg.sender);  
            payable(droneAddress).transfer(msg.value); 
        }else{
            emit PayUnSuccessfulMsg("Wrong! Payment failure, please confirm the order state.",msg.sender);
        }          
    }

    function assessment(uint satisfaction,string memory assessedMsg) onlyFarmer public{
        require(state == OrderState.completed);
        satisfactionLevel = satisfaction;
        assessmentMessage = assessedMsg;    
        assessmentTime = block.timestamp;                  
        state = OrderState.assessed;        
        emit AssessmentMsg("The order has been assessed.",msg.sender);
    }
}