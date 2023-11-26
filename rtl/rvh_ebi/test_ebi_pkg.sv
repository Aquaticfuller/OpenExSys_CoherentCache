package test_ebi_pkg;
import rvh_noc_pkg::*;
import rvh_uncore_param_pkg::*;

localparam LAR_W = $bits(io_port_t);
// single channel information
localparam TEST_MESSAGE_LENGTH = $bits(cache_scu_cc_test_t) + 1 + VC_ID_NUM_MAX_W + LAR_W;
localparam CR_MESSAGE_LENGTH = VC_ID_NUM_MAX_W;
// total channels information
localparam M1_M2_CHANNEL_NUM = 2;
localparam M1_M2_CHANNEL_NUM_WIDTH = $clog2(M1_M2_CHANNEL_NUM);
localparam M2_M1_CHANNEL_NUM = 2;
localparam M2_M1_CHANNEL_NUM_WIDTH = $clog2(M2_M1_CHANNEL_NUM);

// typedef enum logic [M1_M2_CHANNEL_NUM_WIDTH-1:0] {ID_AR, ID_AW, ID_W, ID_CR, ID_CD} m1_m2_channel_id_t;
// typedef enum logic [M1_M2_CHANNEL_NUM_WIDTH-1:0] {ID_B, ID_R, ID_AC} m2_m1_channel_id_t;

typedef enum logic [M1_M2_CHANNEL_NUM_WIDTH-1:0] {ID_TEST, ID_CR} m1_m2_channel_id_t;
typedef m1_m2_channel_id_t m2_m1_channel_id_t;

parameter int unsigned M1_M2_CHANNEL_LENGTH_LIST[M1_M2_CHANNEL_NUM] = '{TEST_MESSAGE_LENGTH, CR_MESSAGE_LENGTH};

localparam MAX_M1_M2_MESSAGE_LENGTH = TEST_MESSAGE_LENGTH;
localparam MAX_M1_M2_MESSAGE_WIDTH = $clog2(MAX_M1_M2_MESSAGE_LENGTH);

localparam MAX_M2_M1_MESSAGE_LENGTH = TEST_MESSAGE_LENGTH;
localparam MAX_M2_M1_MESSAGE_WIDTH = $clog2(MAX_M1_M2_MESSAGE_LENGTH);

// transmition config
localparam PARITY_LENGTH = 8;
localparam PARITY_WIDTH = $clog2(PARITY_LENGTH);
localparam CREDIT_LENGTH = 2;
localparam CREDIT_WIDTH = 2;
// localparam EBI_BUFFER_DEPTH = VC_DEPTH_MAX;
localparam EBI_BUFFER_DEPTH = 20;
localparam OFF_DIE_WD = 16;

// type definition
typedef enum logic [2:0] {RCREDIT_IDLE, RRECV_CREDIT, RCREDIT_CHECK} recv_credit_state_t;
typedef enum logic [CREDIT_WIDTH-1:0] {NO_CREDIT, SUCCESS, FAILURE} credit_t;
typedef enum logic[3:0] {SEND_IDLE, START_BIT, MESSAGE_SEND, INSERT_PARITY, END_BIT, WAIT_CREDIT} send_state_t;
typedef enum logic [3:0] {RECV_IDLE, GET_VC_NUM, RECV_MESSSAGE, MAKE_CREDIT} recv_state_t;
typedef enum logic [2:0] {SCREDIT_IDLE, SCREDIT_START_BIT, SCREDIT_VALUE_SEND}send_credit_state_t;

endpackage