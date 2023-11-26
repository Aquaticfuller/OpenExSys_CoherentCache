package ebi_pkg;
import rvh_l1d_cc_pkg::*;
import rvh_noc_pkg::*;
import rvh_uncore_param_pkg::*;

localparam LAR_W = $bits(io_port_t);
// single channel information
localparam REQ_MESSAGE_LENGTH = $bits(cache_scu_cc_req_t) + 1 + VC_ID_NUM_MAX_W + LAR_W;
localparam RESP_MESSAGE_LENGTH = $bits(cache_scu_cc_resp_t) + 1 + VC_ID_NUM_MAX_W + LAR_W;
localparam EVICT_MESSAGE_LENGTH = $bits(cache_scu_cc_req_t) + 1 + VC_ID_NUM_MAX_W + LAR_W;
localparam DATA_MESSAGE_LENGTH = $bits(cache_scu_cc_data_t) + 1 + VC_ID_NUM_MAX_W + LAR_W + DATA_BURST_NUM_W + 1;
                                                            // these bits indicate which bits are filled with valid data
localparam DATA_VALID_LOCATION = $bits(cache_scu_cc_data_t) - DATA_LINE_W - DATA_BURST_NUM;


localparam DATA_ID_TYPE_LENGTH = $bits(scu_cc_resp_tid_t) + $bits(cache_scu_cc_data_type_e);

localparam SNP_MESSAGE_LENGTH = $bits(cache_scu_cc_snp_t) + 1 + VC_ID_NUM_MAX_W + LAR_W;
localparam CR_MESSAGE_LENGTH = VC_ID_NUM_MAX_W;

// total channels information
localparam M1_M2_CHANNEL_NUM = 10;
localparam M1_M2_CHANNEL_NUM_WIDTH = $clog2(M1_M2_CHANNEL_NUM);
localparam M2_M1_CHANNEL_NUM = 10;
localparam M2_M1_CHANNEL_NUM_WIDTH = $clog2(M2_M1_CHANNEL_NUM);

// typedef enum logic [M1_M2_CHANNEL_NUM_WIDTH-1:0] {ID_AR, ID_AW, ID_W, ID_CR, ID_CD} m1_m2_channel_id_t;
// typedef enum logic [M1_M2_CHANNEL_NUM_WIDTH-1:0] {ID_B, ID_R, ID_AC} m2_m1_channel_id_t;

typedef enum logic [M1_M2_CHANNEL_NUM_WIDTH-1:0] {ID_REQ, ID_RESP, ID_EVICT, ID_DATA, ID_SNP, ID_CR_REQ, ID_CR_RESP, ID_CR_EVICT, ID_CR_DATA, ID_CR_SNP} m1_m2_channel_id_t;
typedef m1_m2_channel_id_t m2_m1_channel_id_t;

parameter int unsigned M1_M2_CHANNEL_LENGTH_LIST[M1_M2_CHANNEL_NUM] = '{REQ_MESSAGE_LENGTH, RESP_MESSAGE_LENGTH, EVICT_MESSAGE_LENGTH, DATA_MESSAGE_LENGTH, SNP_MESSAGE_LENGTH, CR_MESSAGE_LENGTH, CR_MESSAGE_LENGTH, CR_MESSAGE_LENGTH, CR_MESSAGE_LENGTH, CR_MESSAGE_LENGTH};

localparam MAX_M1_M2_MESSAGE_LENGTH = DATA_MESSAGE_LENGTH;
localparam MAX_M1_M2_MESSAGE_WIDTH = $clog2(MAX_M1_M2_MESSAGE_LENGTH);

localparam MAX_M2_M1_MESSAGE_LENGTH = DATA_MESSAGE_LENGTH;
localparam MAX_M2_M1_MESSAGE_WIDTH = $clog2(MAX_M1_M2_MESSAGE_LENGTH);

// transmition config
localparam PARITY_LENGTH = 8;
localparam PARITY_WIDTH = $clog2(PARITY_LENGTH);
localparam CREDIT_LENGTH = 2;
localparam CREDIT_WIDTH = 2;
localparam EBI_BUFFER_DEPTH = VC_DEPTH_MAX * VC_ID_NUM_MAX;

`ifdef SYNTHESIS
localparam OFF_DIE_WD = 1;
`else
localparam OFF_DIE_WD = 32;
`endif
`define PARITY_ON

// type definition
typedef enum logic [2:0] {RCREDIT_IDLE, RRECV_CREDIT, RCREDIT_CHECK} recv_credit_state_t;
typedef enum logic [CREDIT_WIDTH-1:0] {NO_CREDIT, SUCCESS, FAILURE} credit_t;
typedef enum logic[3:0] {SEND_IDLE, START_BIT, MESSAGE_SEND, INSERT_PARITY, END_BIT, WAIT_CREDIT} send_state_t;
typedef enum logic [3:0] {RECV_IDLE, GET_VC_NUM, RECV_MESSSAGE, MAKE_CREDIT} recv_state_t;
typedef enum logic [2:0] {SCREDIT_IDLE, SCREDIT_START_BIT, SCREDIT_VALUE_SEND}send_credit_state_t;

typedef struct packed {
    logic [REQ_MESSAGE_LENGTH-1:0] c0;
    logic [RESP_MESSAGE_LENGTH-1:0] c1;
    logic [EVICT_MESSAGE_LENGTH-1:0] c2;
    logic [DATA_MESSAGE_LENGTH-1:0] c3;
    logic [SNP_MESSAGE_LENGTH-1:0] c4;
    logic [VC_ID_NUM_MAX_W-1:0] c5;
    logic [VC_ID_NUM_MAX_W-1:0] c6;
    logic [VC_ID_NUM_MAX_W-1:0] c7;
    logic [VC_ID_NUM_MAX_W-1:0] c8;
    logic [VC_ID_NUM_MAX_W-1:0] c9;
} ebi_type_union;

endpackage