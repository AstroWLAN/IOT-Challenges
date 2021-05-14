#ifndef HCIV_H
#define HCIV_H

// Defines constants
#define REQUEST 1
#define RESPONSE 2 

// Message structure : DATA
typedef nx_struct radioMessage {
    nx_uint8_t 	messageType;
	nx_uint16_t messageCounter;
	nx_uint16_t	messageValue;
} radioMessage;

enum {
    AM_MY_MSG = 6,
};

#endif