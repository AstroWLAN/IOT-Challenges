#include "HCIVMessage.h"

configuration HCIVAppC {}

implementation {


// Wires the components to the interfaces
  components MainC, HCIVC as App;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new FakeSensorC();
  components ActiveMessageC;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);

  App.Boot -> MainC.Boot;
  App.AMSend -> AMSenderC;
  App.Packet -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.SplitControl -> ActiveMessageC;
  App.PacketAcknowledgements -> AMSenderC.Acks;
  App.Timer0 -> Timer0;
  App.Timer1 -> Timer1;
  App.Read -> FakeSensorC;
}