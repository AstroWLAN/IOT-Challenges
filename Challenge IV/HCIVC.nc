// Imports libraries
#include "HCIVMessage.h"
#include "Timer.h"

module HCIVC {
    // Defines the interfaces
    uses {
        interface Boot; 
        interface PacketAcknowledgements;

        // Communication
        interface SplitControl;
        interface Packet;
  	    interface AMSend;
  	    interface Receive;

	    // Timer 
        interface Timer<TMilli> as Timer0;	
 	    interface Timer<TMilli> as Timer1;

        // Sensor reading
	    interface Read<uint16_t>;
    }
} 
implementation {
    
    // Local variables
    uint8_t localCounter = 0;
    uint8_t receiverID;
    message_t packet;
    
    // Function prototypes
    void sendRequest();
    void sendResponse();
  
    // Function definitions with TOSSIM support
    void sendRequest() {
        radioMessage* receivedMessage = (radioMessage*)call Packet.getPayload(&packet, sizeof(radioMessage));
        // TOSSIM : DGB takes two strings [ Channel | Console output ]
	    dbg("radio_send", "Creating the message...\n");
	    // Creates the message : if the received message is NULL...
        if (receivedMessage == NULL) 
            return;
        // Otherwise...
        receivedMessage->messageType = REQ;
	    receivedMessage->messageCounter = localCounter;
	    receivedMessage->messageValue = 0;
	    dbg("radio_send", "Sending the request... | Counter = %d\n", receivedMessage->messageCounter);
	    // Sets the ACK flag inside the packet
	    if (call PacketAcknowledgements.requestAck(&packet) == SUCCESS) 
		    dbg("radio_send", "ACK has been enabled!\n");
	    else 
    	    dbgerror("radio_send", "Something messed up with the ACK! | Counter = %d\n", receivedMessage->messageCounter);

	    // UNICAST : Sends the message to the right node 
        if(call AMSend.send(2, &packet,sizeof(radioMessage)) == SUCCESS) {
	        dbg("radio_pack","Packet sent!\n \t Payload size : %hhu \n", call Packet.payloadLength(&packet));
            // The differences between the DBG types is the amount of information provided
		    dbg_clear("radio_pack", "\t\t Packet type : %hhu [ 1: Request | 2: Response ]\n", receivedMessage->messageType);
		    dbg_clear("radio_pack", "\t\t Counter : %hhu \n", receivedMessage->messageCounter);
		    dbg_clear("radio_pack", "\t\t Value : %hhu\n", receivedMessage->messageValue);	 
  	    }
    }        
    void sendResponse() {
	    dbg("radio_send", "Reading sensor data...\n");
	    call Read.read();
    }

    // EVENT : Boot
    event void Boot.booted() {
        dbg("boot","Application booted at %s\n Current Node : %d\n", sim_time_string(), TOS_NODE_ID);
	    call SplitControl.start();
    }
    
    // EVENT : StartDone
    event void SplitControl.startDone(error_t err){
        if ( err == SUCCESS) {
            dbg("radio", "Radio successfully started!\n");
            if (TOS_NODE_ID == 1) {
                dbg("radio", "Node %d : starting timer...\n", TOS_NODE_ID);
                call Timer0.startPeriodic(1000);
            }
        }
    }
    
    // EVENT : StopDone
    event void SplitControl.stopDone(error_t err) {
	    dbg("role", "Shutting down the mote %d... \n", TOS_NODE_ID);
	    dbg("role", "Done! \n");
    }

    // EVENT : Timer0 Fired
    event void Timer0.fired() {
	    dbg("boot", "Timer0 fired!\n");
        sendRequest();
    }
    
    // EVENT : Timer1 Fired
    event void Timer1.fired() {
	    dbg("role", "Ending operations on the mote %d... \n", TOS_NODE_ID);
	    call SplitControl.stop();
    }
  
    // EVENT : SendDone
    event void AMSend.sendDone(message_t* buf,error_t err) {
        radioMessage* receivedMessage = (radioMessage*)call Packet.getPayload(&packet, sizeof(radioMessage));
	    // Checks if the packet has been sent
        if (&packet == buf && err == SUCCESS) {
            dbg("radio_send", "Packet sent at time %s \n", sim_time_string());
		    localCounter++;
		    if(receivedMessage->messageType == REQ)
                dbg("radio_send", "Counter increased! New value = %d\n", localCounter);
        }
        else
      	    dbgerror("radio_send", "There is a problem with the message sending!");

        // Checks if the ACK has been received
	    if (call PacketAcknowledgements.wasAcked(&packet)) {
            dbg_clear("radio_ack", "\t\tACK message received at time %s\n", sim_time_string());
 	  	    dbg_clear("radio_ack", "\t\tCounter of the received message : %hhu \n", receivedMessage->messageCounter);
		    // Stops the times
		    if(receivedMessage->messageType == RESP)
		        call SplitControl.stop();
		    else {
			    dbg("radio", "Timer stopped\n");
			    call Timer0.stop();
		    }
        }
        else
            dbgerror("radio_ack", "Ack not received!\n");
    }

    // EVENT : Received message
    event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	    if (len != sizeof(radioMessage)) {
      	    dbgerror("radio_rec", "An error occured while receiving the message!\n");
		    return buf;
	    }
        else {
    	    radioMessage* receivedMessage = (radioMessage*)payload;
		    // Reads the content of the message
    	    dbg("radio_rec", "Packket as been received at time : %s\n", sim_time_string());
            dbg("radio_pack","\t\tPayload size : %hhu\n", call Packet.payloadLength(buf));
		    dbg_clear("radio_pack", "\t\tPacket type : %hhu [ 1: Request | 2: Response ]\n", receivedMessage->messageType);
		    dbg_clear("radio_pack", "\t\tCounter : %hhu\n", receivedMessage->messageCounter);
		    dbg_clear("radio_pack", "\t\tValue : %hhu\n", receivedMessage->messageValue);	 

		    // Checks if the packet is a REQUEST
		    if (receivedMessage->msg_type == REQ) {
			    dbg("radio_rec", "Request received, sending the response...\n");
			    // Saves the counter value
			    receiverID = receivedMessage->messageCounter;
			    // Sends the response
			    sendResponse();
		    } 
            else {
			    // The message is a RESPONSE
			    dbg("radio_rec", "Response received! Value of the sensor = %hhu\n", receivedMessage->messageValue);
			    call Timer1.startOneShot(1);
		    }
            return buf;
        }
    }
  
    // EVENT : Read interface done
    event void Read.readDone(error_t result, uint16_t data) {
	    // Prepares the response
	    radioMessage* receivedMessage = (radioMessage*)call Packet.getPayload(&packet, sizeof(radioMessage));
	    dbg("role","Read value : %hhu\n", data);
	    if (receivedMessage == NULL) 
		    return;
        
        receivedMessage->messageType = RESP;
	    receivedMessage->messageCounter = receiverID;
	    receivedMessage->messageValue = data;
	    dbg("radio_send", "Sending the response...\n");
	    // Enables the ACK 
	    if (call PacketAcknowledgements.requestAck(&packet) == SUCCESS) 
		    dbg("radio_send", "ACK has been enabled!\n");
	    else 
            dbgerror("radio_send", "Something messed up with the ACK! | Counter = %d\n", receivedMessage->messageCounter);

        // UNICAST : Sends the message to the right node 
        if(call AMSend.send(1, &packet,sizeof(radioMessage)) == SUCCESS) {
            dbg("radio_pack","Packet sent!\n \t Payload size : %hhu \n", call Packet.payloadLength(&packet));
            dbg_clear("radio_pack", "\t\t Packet type : %hhu [ 1: Request | 2: Response ]\n", receivedMessage->messageType);
		    dbg_clear("radio_pack", "\t\t Counter : %hhu \n", receivedMessage->messageCounter);
		    dbg_clear("radio_pack", "\t\t Value : %hhu\n", receivedMessage->messageValue);	 
        }
    }
}