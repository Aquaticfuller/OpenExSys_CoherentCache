# l1d coherence spec

## 1 interface

### 1.1 cache miss req intf

### 1.2 snoop req intf
#### 1.2.1 channels
  
    // ace5 snoop channels
      // snoop addr
    input  logic              snp_req_if_acvalid_i,
    output logic              snp_req_if_acready_o,
    input  cache_mem_if_ac_t  snp_req_if_ac_i,
      // snoop resp
    output logic              snp_resp_if_crvalid_o,
    input  logic              snp_resp_if_crready_i,
    output cache_mem_if_cr_t  snp_resp_if_cr_o,
      // snoop data
    output logic              snp_resp_if_cdvalid_o,
    input  logic              snp_resp_if_cdready_i,
    output cache_mem_if_cd_t  snp_resp_if_cd_o,

#### 1.2.2 definition

    // ace5 snoop channels
      // snoop addr
    typedef struct packed {
      // mem_tid_t acid;
      logic [L1D_STB_LINE_ADDR_SIZE-1:0]  acaddr;
      logic [3:0]              acsoop;
      logic [2:0]              acprot;
    } cache_mem_if_ac_t;

      // snoop resp
    typedef struct packed {
      logic WasUnique;
      logic IsShared;
      logic PassDirty;
      logic Error; // for ECC, not used
      logic DataTransfer;
    } cr_crresp_t;

    typedef struct packed {
      // mem_tid_t crid;
      cr_crresp_t crresp;
    } cache_mem_if_cr_t;

      // snoop data
    typedef struct packed {
      // mem_tid_t cdid;
      logic [L1D_BANK_LINE_DATA_SIZE-1:0] cddata;
      logic                               cdlast;
    } cache_mem_if_cd_t;

## 2 micro architecture support

### 2.1 pipeline diagram

![l1d pipeline diagram](./l1d_coherence.png)

### 2.2 corner cases

  Some detailed corner case specification for snoop.

#### 2.2.1 snoop req conflict with pipeline

  If set idx conflict with valid req in pipeline, stall snoop buffer until no conflict in pipeline, meanwhile backpress all incoming req at s0.

#### 2.2.2 snoop req conflict with mshr

  If set idx conflict with valid req in mshr:
  
  * if the mshr req has handshaked with next level memory, stall snoop buffer until no conflict in mshr, meanwhile backpress all incoming req at s0;
  * else if the mshr req has not hankshaked with next level memory, no snoop req confict.

#### 2.2.3 snoop req conflict with lfb

  No need to check as a valid entry in lfb has to be a valid entry in mshr.

#### 2.2.4 snoop req conflict with ewrq

  If set idx conflict with valid req in ewrq, wait until ewrq finish the evict, meanwhile backpress all incoming req at s0. Then do the snoop.

  For the SCU or next level memory control, if there is a same-line-addr write back req from last level memory which hit a in flight coherent transaction, the write back cache line should be forwarded to the hitted coherence transaction, take it as the cohernce resp data, and no need to write it into the data ram.


## 3 protocol

  Use MESI protocol, each cache line has one of four states, the cache lines' state is maintained at private cache's line state table(LST) or directory/snoopy filter in shared snoop control unit(SCU)

### 3.1 stable states

| state/attribute | Valid | Dirty | Exclusive |
| --------------- | ----- | ----- | --------- |
| I (Invalid)     | N     | N     | -         |
| SC(SharedClean) | Y     | N     | N         |
| UC(UniqueClean) | Y     | N     | Y         |
| UD(UniqueDirty) | Y     | Y     | Y         |

### 3.2 transient states

<!-- |stete      |  attribute
| -->

### 3.3 messages

#### 3.3.1 request msg

| msg type class | msg type           | description                                                                                                                                                    |
| -------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| requestor req  | ReadNotSharedDirty | Read request to a Snoopable address region to carry out a load from the cache line. Data must be provided to the Requester in UC, UD, or SC states only.       |
|                | ReadUnique         |                                                                                                                                                                |
|                | ReadOnce           |                                                                                                                                                                |
|                | CleanUnique        | Request to a Snoopable address region to change the cache state at the Requester to Unique to carry out a store to the cache line.                             |
| evict req      | Evict              |                                                                                                                                                                |
|                | WriteBackFull      |                                                                                                                                                                |
|                | WriteEvictFull     |                                                                                                                                                                |
| scu snoop req  | SnpShared          | Snoop request to obtain a copy of the cache line in Shared state while leaving any cached copy in Shared state. Must not leave the cache line in Unique state. |
|                | SnpUnique          | Snoop request to obtain a copy of the cache line in Unique state while invalidating any cached copies. Must change the cache line to Invalid state.            |
|                | SnpCleanInvalid    | Snoop request to Invalidate the cache line at the Snoopee and obtain any Dirty copy, used in SF eviction.                                                      |

#### 3.3.2 dataless response msg

| msg type class     | msg type     | description                                                                                                                                     |
| ------------------ | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| responsor resp     | Comp_I       |                                                                                                                                                 |
|                    | Comp_UC      |                                                                                                                                                 |
|                    | Comp_SC      |                                                                                                                                                 |
| writeback req resp | CompDBIDResp | CopyBack requests' completion response. Comp: WriteData transaction is done. DBIDResp: resources are available to accept the WriteData response |
| snoop resp         | SnpAck       | L1 send to L2 when take the forwarded snoop req from L2                                                                                         |
|                    | SnpResp_I    |                                                                                                                                                 |
|                    | SnpResp_SC   |                                                                                                                                                 |
| resp final ack     | CompAck      | Sent by the Requester on receipt of the Completion response                                                                                     |

#### 3.3.3 data msg

| msg type class      | msg type          | description |
| ------------------- | ----------------- | ----------- |
| responsor resp data | CompData_I        |             |
|                     | CompData_UC       |             |
|                     | CompData_SC       |             |
|                     | CompData_UD_PD    |             |
| copy back req data  | CBWrData_UC       |             |
|                     | CBWrData_SC       |             |
|                     | CBWrData_UD_PD    |             |
|                     | CBWrData_I        |             |
| snoop resp data     | SnpRespData_I     |             |
|                     | SnpRespData_I_PD  |             |
|                     | SnpRespData_SC    |             |
|                     | SnpRespData_SC_PD |             |
|                     | SnpRespData_UC    |             |
|                     | SnpRespData_UD    |             |


### 3.4 states transition

#### 3.4.1 cpu ld/st req fsm

| current state/[output/next state]/input       | default next state                     | default output     | cpu_req_load | cpu_req_store | scu_resp_data_UC         | scu_resp_data_SC         | scu_resp_data_UD         | scu_resp_UD              | scu_SnpShared               | scu_SnpUnique               | scu_SnpCleanInvalid         | refill_evict     |
| --------------------------------------------- | -------------------------------------- | ------------------ | ------------ | ------------- | ------------------------ | ------------------------ | ------------------------ | ------------------------ | --------------------------- | --------------------------- | --------------------------- | ---------------- |
| I                                             | -                                      | -                  | /I_LD_S1     | /I_ST_S1      | -                        | -                        | -                        | -                        | /I_SNP_SHARED_S1            | /I_SNP_UNIQUE_S1            | /I_SNP_CLEANINVALID_S1      | -                |
| I_LD_S1(tag, lst check)                       | I_LD_S2_MISS(miss)                     | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall at snp buf            | stall at snp buf            | stall at snp buf            | -                |
| I_LD_S2_MISS(new mshr)                        | I_LD_IN_MSHR_NOTSENT                   | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall at snp buf            | stall at snp buf            | stall at snp buf            | -                |
| I_LD_IN_MSHR_NOTSENT                          | I_LD_IN_MSHR_SENT                      | ReadNotSharedDirty | stall input  | stall input   | -                        | -                        | -                        | -                        | snp fsm run/I_LD_SNP_STALL  | snp fsm run/I_LD_SNP_STALL  | snp fsm run/I_LD_SNP_STALL  | -                |
| I_LD_IN_MSHR_SENT                             |                                        | -                  | stall input  | stall input   | CompAck/I_UC_DATA_REFILL | CompAck/I_SC_DATA_REFILL | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| I_UC_DATA_REFILL                              | UC                                     | load_lsu_resp      | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| I_SC_DATA_REFILL                              | SC                                     | load_lsu_resp      | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| I_UD_DATA_REFILL                              | UD                                     | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| I_ST_S1(tag, lst check)                       | I_LD_S2_MISS(miss)                     | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall at snp buf            | stall at snp buf            | stall at snp buf            | -                |
| I_ST_S2_MISS(new mshr)                        | I_ST_IN_MSHR_NOTSENT                   | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall at snp buf            | stall at snp buf            | stall at snp buf            | -                |
| I_ST_IN_MSHR_NOTSENT                          | I_ST_IN_MSHR_SENT                      | SendReadUnique     | stall input  | stall input   | -                        | -                        | -                        | -                        | snp fsm run/I_ST_SNP_STALL  | snp fsm run/I_ST_SNP_STALL  | snp fsm run/I_ST_SNP_STALL  | -                |
| I_ST_IN_MSHR_SENT                             |                                        | -                  | stall input  | stall input   | -                        | -                        | CompAck/I_UD_DATA_REFILL | -                        | stall input                 | stall input                 | stall input                 | -                |
| I_SNP_SHARED_S1(tag, lst check)               | I_SNP_x_S2                             | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| I_SNP_UNIQUE_S1(tag, lst check)               | I_SNP_x_S2                             | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| I_SNP_CLEANINVALID_S1(tag, lst check)         | I_SNP_x_S2                             | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| I_SNP_x_S2(snp resp)                          | I                                      | SnpResp_I          | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| I_LD_SNP_STALL                                | I_LD_IN_MSHR_NOTSENT(when snp finish)  | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| I_ST_SNP_STALL                                | I_ST_IN_MSHR_NOTSENT(when snp finish)  | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| UC                                            | -                                      | -                  | /UC_LD_S1    | /UC_ST_S1     | -                        | -                        | -                        | -                        | /UC_SNP_SHARED_S1           | /UC_SNP_UNIQUE_S1           | /UC_SNP_CLEANINVALID_S1     | /UC_EVICT_S1     |
| UC_LD_S1(tag, lst check)                      | UC_LD_S2_HIT(hit)                      | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall at snp buf            | stall at snp buf            | stall at snp buf            | stall evict      |
| UC_LD_S2_HIT(hit resp)                        | UC                                     | load_lsu_resp      | stall input  | stall input   | -                        | -                        | -                        | -                        | snp fsm run                 | snp fsm run                 | snp fsm run                 | stall evict      |
| UC_ST_S1(tag, lst check)                      | UC_ST_S2_HIT(hit)                      | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall at snp buf            | stall at snp buf            | stall at snp buf            | stall evict      |
| UC_ST_S2_HIT(wr data, tag ram, lst)           | UD                                     | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | snp fsm run                 | snp fsm run                 | snp fsm run                 | stall evict      |
| UC_SNP_SHARED_S1(tag, lst check)              | UC_SNP_SHARED_S2                       | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| UC_SNP_SHARED_S2(wr lst; snp resp)            | SC                                     | SnpResp_SC         | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| UC_SNP_UNIQUE_S1(tag, lst check)              | UC_SNP_UNIQUE_S2                       | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| UC_SNP_UNIQUE_S2(wr lst; snp resp)            | I                                      | SnpResp_I          | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| UC_SNP_CLEANINVALID_S1(tag, lst check)        | UC_SNP_CLEANINVALID_S2                 | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| UC_SNP_CLEANINVALID_S2(wr lst; snp resp)      | I                                      | SnpResp_I          | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| UC_EVICT_S1(rd tag, lst; choose way)          | UC_EVICT_S2                            | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| UC_EVICT_S2(wr lst)                           | I                                      | Evict              | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| SC                                            | -                                      | -                  | /SC_LD_S1    | /SC_ST_S1     | -                        | -                        | -                        | -                        | /SC_SNP_SHARED_S1           | /SC_SNP_UNIQUE_S1           | /SC_SNP_CLEANINVALID_S1     | /SC_EVICT_S1     |
| SC_LD_S1(tag, lst check)                      | SC_LD_S2_HIT(hit)                      | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall at snp buf            | stall at snp buf            | stall at snp buf            | stall evict      |
| SC_LD_S2_HIT(hit resp)                        | SC                                     | load_lsu_resp      | stall input  | stall input   | -                        | -                        | -                        | -                        | snp fsm run                 | snp fsm run                 | snp fsm run                 | stall evict      |
| SC_ST_S1(tag, lst check)                      | SC_ST_S2_MISS(access)                  | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall at snp buf            | stall at snp buf            | stall at snp buf            | stall evict      |
| SC_ST_S2_MISS                                 | SC_ST_IN_MSHR_NOTSENT                  | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall at snp buf            | stall at snp buf            | stall at snp buf            | stall evict      |
| SC_ST_IN_MSHR_NOTSENT                         | SC_ST_IN_MSHR_SENT                     | CleanUnique        | stall input  | stall input   | -                        | -                        | -                        | -                        | snp fsm run/SC_ST_SNP_STALL | snp fsm run/SC_ST_SNP_STALL | snp fsm run/SC_ST_SNP_STALL | stall evict      |
| SC_ST_IN_MSHR_SENT                            |                                        | -                  | stall input  | stall input   | -                        | -                        | -                        | CompAck/SC_UD_ACC_UPDATE | stall input                 | stall input                 | stall input                 | stall evict      |
| SC_UD_ACC_UPDATE (wr data ram, lst)           | UD                                     | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | snp fsm run                 | snp fsm run                 | snp fsm run                 | stall evict      |
| SC_SNP_SHARED_S1(tag, lst check)              | SC_SNP_SHARED_S2                       | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| SC_SNP_SHARED_S2(wr lst; snp resp)            | SC                                     | SnpResp_SC         | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| SC_SNP_UNIQUE_S1(tag, lst check)              | SC_SNP_UNIQUE_S2                       | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| SC_SNP_UNIQUE_S2(wr lst; snp resp)            | I                                      | SnpResp_I          | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| SC_SNP_CLEANINVALID_S1(tag, lst check)        | SC_SNP_CLEANINVALID_S2                 | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| SC_SNP_CLEANINVALID_S2(wr lst; snp resp)      | I                                      | SnpResp_I          | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| SC_ST_SNP_STALL                               | SC_ST_IN_MSHR_NOTSENT(when snp finish) | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| SC_EVICT_S1(rd tag, lst; choose way)          | SC_EVICT_S2                            | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| SC_EVICT_S2(wr lst)                           | I                                      | Evict              | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| UD                                            | -                                      | -                  | /UD_LD_S1    | /UD_ST_S1     | -                        | -                        | -                        | -                        | /UD_SNP_SHARED_S1           | /UD_SNP_UNIQUE_S1           | /UD_SNP_CLEANINVALID_S1     | /UD_WriteBack_S1 |
| UD_LD_S1(tag, lst check)                      | UD_LD_S2_HIT(hit)                      | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall at snp buf            | stall at snp buf            | stall at snp buf            | stall evict      |
| UD_LD_S2_HIT(hit resp)                        | UD                                     | load_lsu_resp      | stall input  | stall input   | -                        | -                        | -                        | -                        | snp fsm run                 | snp fsm run                 | snp fsm run                 | stall evict      |
| UD_ST_S1(tag, lst check)                      | UD_ST_S2_HIT(hit)                      | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall at snp buf            | stall at snp buf            | stall at snp buf            | stall evict      |
| UD_ST_S2_HIT(wr data, tag ram, lst)           | UD                                     | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | snp fsm run                 | snp fsm run                 | snp fsm run                 | stall evict      |
| UD_SNP_SHARED_S1(tag, lst check)              | UD_SNP_SHARED_S2                       | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| UD_SNP_SHARED_S2(wr lst; snp data resp)       | SC                                     | SnpRespData_SC_PD  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| UD_SNP_UNIQUE_S1(tag, lst check)              | UD_SNP_UNIQUE_S2                       | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| UD_SNP_UNIQUE_S2(wr lst; snp data resp)       | I                                      | SnpRespData_I_PD   | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| UD_SNP_CLEANINVALID_S1(tag, lst check)        | UD_SNP_CLEANINVALID_S2                 | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| UD_SNP_CLEANINVALID_S2(wr lst; snp data resp) | I                                      | SnpRespData_I_PD   | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | stall evict      |
| UD_WriteBack_S1(rd tag ram, lst; choose way)  | UD_WriteBack_S2                        | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| UD_WriteBack_S2(rd data ram)                  | UD_WriteBack_S3                        | CBWrData_UD_PD     | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |
| UD_WriteBack_S3(wr lst)                       | I                                      | -                  | stall input  | stall input   | -                        | -                        | -                        | -                        | stall input                 | stall input                 | stall input                 | -                |

#### 3.4.2 scu snp req fsm

## 4 l1d snoop control

### 4.1 SnpShared

#### 4.1.1 description

  Snoop request to obtain a copy of the cache line in Shared state while leaving any cached 
  copy in Shared state. Must not leave the cache line in Unique state.

#### 4.1.2 fsm

  * all (during the whole snoop transaction):
    * 1. stop l1d bank from receiving new st, ptw, ld req from core
    * 2. stall mlfb refill transaction [mlfb_cache_peek_valid, mlfb_cache_check_valid, mlfb_cache_evict_valid, mlfb_cache_evict_bypass, mlfb_cache_refill_valid] if no sent-out line addr hit in mshr(cond s0.3)

  * s0:
    * 1. if s1 is a store hit need to write data ram, wait for 1 cycle
    * 2. check pipeline, mshr, ewrq for same line addr, if any hit:

      | no.  | line state                                                       | next stage                          |
      | ---- | ---------------------------------------------------------------- | ----------------------------------- |
      | s0.1 | in mshr not sent out, last stable state: I (I->UC, I->SC, I->UD) | **goto s1**: read tag ram, read lst |
      | s0.2 | in mshr not sent out, last stable state: SC(SC->UD)              | **goto s1**: read tag ram, read lst |
      | s0.3 | in mshr sent out                                                 | stall snp until mshr no conflict    |
      | s0.4 | in ewrq                                                          | stall snp until ewrq no conflict    |
      | s0.5 | in pipeline                                                      | stall snp until pipe no conflict    |
      | s0.6 | no conflict                                                      | **goto s1**: read tag ram, read lst |

  * s1:
    * 1. read tag ram, read lst, then **goto s2**

  * s2:
    * 1. compare tag, check lst
    * 2. read data ram if needed(cond s2.3, s2.4, s2.5)
    * 3. write lst if needed(cond s2.4, s2.5)

    | no.  | line state | next stage                            |
    | ---- | ---------- | ------------------------------------- |
    | s2.1 | tag miss   | **goto s3**: dataless resp: SnpResp_I |
    | s2.2 | I          | **goto s3**: dataless resp: SnpResp_I |
    | s2.3 | SC         | **goto s3**: data resp: SnpResp_SC    |
    | s2.4 | UC         | **goto s3**: data resp: SnpResp_SC    |
    | s2.5 | UD         | **goto s3**: data resp: SnpResp_SC_PD |

  * s3:
    * 1. dataless resp if needed(cond s2.1, s2.2), **finish snoop transaction**
    * 2. or data resp if needed(cond s2.3, s2.4, s2.5), **finish snoop transaction**

### 4.2 SnpUnique

#### 4.2.1 description
  Snoop request to obtain a copy of the cache line in Unique state while invalidating any 
  cached copies. Must change the cache line to Invalid state.

#### 4.2.2 fsm

  * all (during the whole snoop transaction):
    * 1. stop l1d bank from receiving new st, ptw, ld req from core
    * 2. stall mlfb refill transaction [mlfb_cache_peek_valid, mlfb_cache_check_valid, mlfb_cache_evict_valid, mlfb_cache_evict_bypass, mlfb_cache_refill_valid] if no sent-out line addr hit in mshr(cond s0.3)

  * s0:
    * 1. if s1 is a store hit need to write data ram, wait for 1 cycle
    * 2. check pipeline, mshr, ewrq for same line addr, if any hit:

      | no.  | line state                                                       | next stage                          |
      | ---- | ---------------------------------------------------------------- | ----------------------------------- |
      | s0.1 | in mshr not sent out, last stable state: I (I->UC, I->SC, I->UD) | **goto s1**: read tag ram, read lst |
      | s0.2 | in mshr not sent out, last stable state: SC(SC->UD)              | **goto s1**: read tag ram, read lst |
      | s0.3 | in mshr sent out                                                 | stall snp until mshr no conflict    |
      | s0.4 | in ewrq                                                          | stall snp until ewrq no conflict    |
      | s0.5 | in pipeline                                                      | stall snp until pipe no conflict    |
      | s0.6 | no conflict                                                      | **goto s1**: read tag ram, read lst |

  * s1:
    * 1. read tag ram, read lst if needed, then **goto s2**

  * s2:
    * 1. compare tag, check lst
    * 2. read data ram if needed(cond s2.3, s2.4, s2.5)
    * 3. write lst if needed(cond s2.3, s2.4, s2.5)

    | no.  | line state | next stage                            |
    | ---- | ---------- | ------------------------------------- |
    | s2.1 | tag miss   | **goto s3**: dataless resp: SnpResp_I |
    | s2.2 | I          | **goto s3**: dataless resp: SnpResp_I |
    | s2.3 | SC         | **goto s3**: data resp: SnpResp_I     |
    | s2.4 | UC         | **goto s3**: data resp: SnpResp_I     |
    | s2.5 | UD         | **goto s3**: data resp: SnpResp_I_PD  |

  * s3:
    * 1. dataless resp if needed(cond s2.1, s2.2), **finish snoop transaction**
    * 2. or data resp if needed(cond s2.3, s2.4, s2.5), **finish snoop transaction**

### 4.3 SnpCleanInvalid

#### 4.3.1 description

  Snoop request to Invalidate the cache line at the Snoopee and obtain any Dirty copy. Might 
  also be generated by the interconnect without a corresponding request. Must change the 
  cache line to Invalid state.

#### 4.3.2 fsm

  * all (during the whole snoop transaction):
    * 1. stop l1d bank from receiving new st, ptw, ld req from core
    * 2. stall mlfb refill transaction [mlfb_cache_peek_valid, mlfb_cache_check_valid, mlfb_cache_evict_valid, mlfb_cache_evict_bypass, mlfb_cache_refill_valid] if no sent-out line addr hit in mshr(cond s0.3)

  * s0:
    * 1. if s1 is a store hit need to write data ram, wait for 1 cycle
    * 2. check pipeline, mshr, ewrq for same line addr, if any hit:

      | no.  | line state                                                       | next stage                          |
      | ---- | ---------------------------------------------------------------- | ----------------------------------- |
      | s0.1 | in mshr not sent out, last stable state: I (I->UC, I->SC, I->UD) | **goto s1**: read tag ram, read lst |
      | s0.2 | in mshr not sent out, last stable state: SC(SC->UD)              | **goto s1**: read tag ram, read lst |
      | s0.3 | in mshr sent out                                                 | stall snp until mshr no conflict    |
      | s0.4 | in ewrq                                                          | stall snp until ewrq no conflict    |
      | s0.5 | in pipeline                                                      | stall snp until pipe no conflict    |
      | s0.6 | no conflict                                                      | **goto s1**: read tag ram, read lst |

  * s1:
    * 1. read tag ram, read lst if needed, then **goto s2**

  * s2:
    * 1. compare tag, check lst
    * 2. read data ram if needed(cond s2.3, s2.4, s2.5)
    * 3. write lst if needed(cond s2.3, s2.4, s2.5)

    | no.  | line state | next stage                            |
    | ---- | ---------- | ------------------------------------- |
    | s2.1 | tag miss   | **goto s3**: dataless resp: SnpResp_I |
    | s2.2 | I          | **goto s3**: dataless resp: SnpResp_I |
    | s2.3 | SC         | **goto s3**: dataless resp: SnpResp_I |
    | s2.4 | UC         | **goto s3**: dataless resp: SnpResp_I |
    | s2.5 | UD         | **goto s3**: data resp: SnpResp_I_PD |

  * s3:
    * 1. dataless resp if needed(cond s2.1, s2.2), **finish snoop transaction**
    * 2. or data resp if needed(cond s2.3, s2.4, s2.5), **finish snoop transaction**