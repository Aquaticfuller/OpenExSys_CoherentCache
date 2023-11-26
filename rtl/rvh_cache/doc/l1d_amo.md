# l1d atomic spec

## 1 amo pipeline

  * s0
    * flush store buffer
  * s1 
    * the store buffer is cleared
    * send the amo req by store req port directly to the cache bank
    * cache bank read tag ram, read data ram, read lst (like a load req)
  * s2
    * compare tag, check lst state
      * if hit(state E/M), goto **alu**
      * if miss, allocate mshr, ReadUnique, goto **refill**
  * refill
    * in mlfb refill fsm, goto **alu**
  * alu
    * do alu calculation, goto **write_resp**
  * write_resp
    * finish refill/store by new data into data ram
    * update tag ram, lst if needed
    * resp to lsu with old data

## 2 lr/sc pipeline

Let lr get M permission, set the reservation table.

To clear the reservation table if:
  * a snoop from SCU hit the same cache line, no matter it is a snpS or snpM.
  * the reserved cache line is evicted
  * a store or sc to the reserved cache line
  * a younger lr would overwrite the older lr

To fail a sc if:
  * check for reservation table fail
  * check for M permission fail
  * tag miss

As snpS can clear the reservation table and fail the sc, this design has potential livelock risk if multithread frequently load or lr the lock. This can help to simplize hardware design. The livelock rick can be solved by lock lr resered cache line serval cycles after a given number of consecutive sc failures.

### 2.1 lr

  * s0
    * flush store buffer
  * s1
    * the store buffer is cleared
    * send the lr req by store req port directly to the cache bank
    * cache bank read tag ram, read data ram, read lst (like a load req)
  * s2
    * compare tag, check lst state
      * if hit(state E/M), goto **s3**
      * if miss, allocate mshr, ReadUnique, goto **refill**
  * s3
    * set reservation table in lst
    * resp to lsu with data
  * refill
    * in mlfb refill fsm, set reservation table in lst
    * finish refill/store by new data into data ram
    * update tag ram, lst if needed
    * resp to lsu with data

### 2.2 sc

  * s0
    * flush store buffer
  * s1
    * the store buffer is cleared
    * send the sc req by store req port directly to the cache bank
    * cache bank read tag ram, read lst (like a store req)
    * read reservation table
  * s2
    * compare tag, check lst state
      * if hit(state E/M, reservation table valid), goto **sc_succ**
      * else if miss goto **sc_fail**
  * sc_succ
    * clear reservation table in lst
    * resp 0 to lsu
    * write new data into data ram
  * sc_fail
    * clear reservation table in lst
    * resp 1 to lsu