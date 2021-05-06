// Imports headers
#include "Timer.h"
#include "HC3Message.h"

// Defines the timer periods following the specific requests (Hz)
#define T0 (1000/1)
#define T1 (1000/3)
#define T2 (1000/5)

/* Defines the interfaces
   TIMERS : Each mote has his own timer
   SPLITCONTROL : Manipulates the radio status | ON or OFF
   PACKET : Used to modify the packets
*/
module HC3C @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as Timer0;
    interface Timer<TMilli> as Timer1;
    interface Timer<TMilli> as Timer2;
    interface SplitControl as AMControl;
    interface Packet;
    }
}

// Defines the app behaviour 
implementation {
    
    // Variables
    message_t packet;
    bool locked;
    uint16_t counter = 0;

    // BOOT event handler
    event void Boot.booted() {
        // Starts the radio
        call AMControl.start();
    }

    // START_DONE : Event triggered by the radio startup
    event void AMControl.startDone(error_t err) {
        // If the radio has started correctly...
        if (err == SUCCESS) {
		    // Starts the timer
		    if (TOS_NODE_ID == 1) {    
		        call Timer0.startPeriodic(T0);
		    }
		    else if (TOS_NODE_ID == 2) {
		        call Timer1.startPeriodic(T1);
		    }
		    else{
		        call Timer2.startPeriodic(T2);
		    }
	    }
        // Otherwise retry the radio startup
	    else {
		    call AMControl.start();
	    }
    }

    // STOP_DONE : Event triggered by the radio stop
    event void AMControl.stopDone() {
    // Do nothing
    }

    // TIMER_FIRED : Timer fired on the first mote
    event void Timer0.fired() {
        // Cheks if the radio is locked or not
        if (locked) {
            return;
        }
        // Performs actions : defining the message payload
        else {
            radioMessage* payload = (radioMessage*)call Packet.getPayload(&packet, sizeof(radioMessage));
            // Error management
            if (payload == NULL) {
                return;
            }
            // Creates the message configuring the payload
            payload->counter = counter;
            payload->moteSenderID  = TOS_NODE_ID;
            // Broadcasts the message
            if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radioMessage)) == SUCCESS) { 
                // Locks the radio
                locked = TRUE;
            }
        }
    }

    // TIMER_FIRED : Timer fired on the second mote
    event void Timer1.fired() {
        // Cheks if the radio is locked or not
        if (locked) {
            return;
        }
        // Performs actions : defining the message payload
        else {
            radioMessage* payload = (radioMessage*)call Packet.getPayload(&packet, sizeof(radioMessage));
            // Error management
            if (payload == NULL) {
                return;
            }
            // Creates the message configuring the payload
            payload->counter = counter;
            payload->moteSenderID  = TOS_NODE_ID;
            // Broadcasts the message
            if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radioMessage)) == SUCCESS) { 
                // Locks the radio
                locked = TRUE;
            }
        }
    }

    // TIMER_FIRED : Timer fired on the third mote
    event void Timer2.fired() {
        // Cheks if the radio is locked or not
        if (locked) {
            return;
        }
        // Performs actions : defining the message payload
        else {
            radioMessage* payload = (radioMessage*)call Packet.getPayload(&packet, sizeof(radioMessage));
            // Error management
            if (payload == NULL) {
                return;
            }
            // Creates the message configuring the payload
            payload->counter = counter;
            payload->moteSenderID  = TOS_NODE_ID;
            // Broadcasts the message
            if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radioMessage)) == SUCCESS) { 
                // Locks the radio
                locked = TRUE;
            }
        }
    }

    // MESSAGE_RECEIVE : The mote has received a message
    event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
        // Checks message size
        radioMessage* message;
        if (len != sizeof(radioMessage)) {
            // We'll skip the message
    	    return bufPtr;
        }
        else {
            // Increase the counter and read the payload
            counter++;
            message = (radioMessage*)payload;
            // Checks if the counter is a multiple of 10
            if ((message->counter) % 10 == 0) {
                // Turns off all the LEDs
                call Leds.led0Off();
                call Leds.led1Off();
                call Leds.led2Off();        
            }
            else {
                // Checks which mote has sent the message in order to toggle the relative LED
                if (message->moteSenderID == 1) {
                    call Leds.led0Toggle();
                }
                if (message->moteSenderID == 2) {
                    call Leds.led1Toggle();
                }
                if (message->moteSenderID == 3) {
                    call Leds.led2Toggle();
                }
            }      
            return bufPtr;
        }
    }
    
    // SEND_DONE : Free the radio when the sending phase ends
    event void AMSend.sendDone(message_t* bufPtr, error_t error) {
        if (&packet == bufPtr) {
            locked = FALSE;
        }
    }
}