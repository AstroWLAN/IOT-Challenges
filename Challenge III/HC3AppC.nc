// Imports the message structure
#include "HC3Message.h"
// Wires the interfaces to the components
configuration HC3AppC {}
implementation {
  components MainC, HC3C as App, LedsC;
  // Printf
  components PrintfC;
  components SerialStartC;
  // Radio
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  // Timers
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2; 
  // Active message 
  components ActiveMessageC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.Timer0 -> Timer0;
  App.Timer1 -> Timer1;
  App.Timer2 -> Timer2;  
  App.Packet -> AMSenderC;
}



