# cache coherence low bandwidth optimization

## 1 S->M dataless update
  
  Use CleanUnique transaction.

## 2 critical word first req data resp

  Separate the whole line into critical part and common part:
    1. send the critical part with higher qos priority;
    2. send the common part with common qos priority;
    3. in the data package, the data will be marked as: a) it is common/critical part; b) also has a critical/common part;

## 3 if `2` is enabled, critical word first snp data resp, and resp the critical data as soon as the critical part from snp data resp is received 

## 4 write back line with dirty bits, only write dirty part of the line

## 5 snp resp data with dirty bits, only write dirty part of the line

  As the snp resp data may be partial, all snp transaction which may have snp data resp need to read data ram.

## 6 provide data to a store only for the clean part of it, to optimize the store from store buffer condition

## 7 overlap the data resp and snp, if the data is latest at llc

## 8 inclusive llc, merge sharer list with tag ram

## 9 some qos support to balance latency

## 10 remove a lot of ack hsk to reduce traffic and release mshr faster

## 11 if the store is a memset, only need to snp for data and resp data
