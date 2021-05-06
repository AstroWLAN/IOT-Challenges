#ifndef HC3_H
#define HC3_H

// Message structure : DATA
typedef nx_struct radioMessage {
  nx_uint16_t counter;
  nx_uint16_t moteSenderID; 
} radioMessage;

// Default setting | let it untouched
enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif