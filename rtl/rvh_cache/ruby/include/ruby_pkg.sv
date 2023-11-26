package ruby_pkg;
    import rrv64_top_macro_pkg::*;
    import rrv64_top_param_pkg::*;
    import rrv64_top_typedef_pkg::*;
    import rrv64_core_param_pkg::*;
    import rrv64_core_typedef_pkg::*;
    import rrv64_uncore_param_pkg::*;
    import rrv64_uncore_typedef_pkg::*;

    import rvh_pkg::*;
    import uop_encoding_pkg::*;
    import rvh_l1d_pkg::*;

// typedef enum logic[5:0] {//{{{
//     LSU_NONE                = 6'd0 ,
//     LSU_LB                  = 6'd1 ,
//     LSU_LBU                 = 6'd2 ,
//     LSU_LH                  = 6'd3 ,
//     LSU_LHU                 = 6'd4 ,
//     LSU_LW                  = 6'd5 ,
//     LSU_LWU                 = 6'd6 ,
//     LSU_LD                  = 6'd7 ,
//     LSU_SB                  = 6'd8 ,
//     LSU_SH                  = 6'd9 ,
//     LSU_SW                  = 6'd10,
//     LSU_SD                  = 6'd11,
//     LSU_LRW                 = 6'd12,
//     LSU_LRD                 = 6'd13,
//     LSU_SCW                 = 6'd14,
//     LSU_SCD                 = 6'd15,
//     LSU_AMOSWAPW            = 6'd16,
//     LSU_AMOSWAPD            = 6'd17,
//     LSU_AMOADDW             = 6'd18,
//     LSU_AMOADDD             = 6'd19,
//     LSU_AMOANDW             = 6'd20,
//     LSU_AMOANDD             = 6'd21,
//     LSU_AMOORW              = 6'd22,
//     LSU_AMOORD              = 6'd23,
//     LSU_AMOXORW             = 6'd24,
//     LSU_AMOXORD             = 6'd25,
//     LSU_AMOMAXW             = 6'd26,
//     LSU_AMOMAXD             = 6'd27,
//     LSU_AMOMAXUW            = 6'd28,
//     LSU_AMOMAXUD            = 6'd29,
//     LSU_AMOMINW             = 6'd30,
//     LSU_AMOMIND             = 6'd31,
//     LSU_AMOMINUW            = 6'd32,
//     LSU_AMOMINUD            = 6'd33,
//     LSU_FLW                 = 6'd34,
//     LSU_FSW                 = 6'd35,
//     LSU_FLD                 = 6'd36,
//     LSU_FSD                 = 6'd37,
//     LSU_FENCE               = 6'd38,
//     LSU_FENCEI              = 6'd39,
//     LSU_SFENCEVMA_ALL       = 6'd40,
//     LSU_SFENCEVMA_ASID      = 6'd41,
//     LSU_SFENCEVMA_VA        = 6'd42,
//     LSU_SFENCEVMA_ASID_VA   = 6'd43
//     //}}}
// }lsu_op_e;

// // typedef struct packed {
// //   logic[RRV64_LSU_ID_WIDTH -1:0]         lsu_id;
// //   logic[ROB_TAG_WIDTH -1:0]              rob_id;
// //   lsu_op_e                               req_type;
// //   logic [PADDR_WIDTH-1:0]                paddr;
// //   logic [PREG_TAG_WIDTH -1:0]            ld_rd_idx;
// //   logic[XLEN     -1:0]                   st_dat;
// //   logic                                  is_cacheable;
// // } rrv64_lsu_l1d_req_t;

// // typedef struct packed {
// //   logic[RRV64_LSU_ID_WIDTH -1:0]        lsu_id;
// //   logic[ROB_TAG_WIDTH -1:0]             rob_id;
// //   lsu_op_e                              req_type;
// //   logic[XLEN -1:0]                      ld_data;
// //   logic [PREG_TAG_WIDTH-1:0]            ld_rd_idx;
// //   logic                                 err;  
// // } rrv64_lsu_l1d_resp_t;

// typedef struct packed {
//   logic[RRV64_LSU_ID_WIDTH -1:0]         lsu_id;
//   logic[ROB_TAG_WIDTH -1:0]              rob_id;
//   lsu_op_e                               req_type;
//   logic [PADDR_WIDTH-1:0]                paddr;
//   logic [PREG_TAG_WIDTH -1:0]            ld_rd_idx;
//   logic[XLEN     -1:0]                   st_dat;
//   logic                                  is_cacheable;
//   logic                                  is_secure;
// } rrv64_lsu_l1d_req_t;

// typedef struct packed {
//   logic[RRV64_LSU_ID_WIDTH -1:0]        lsu_id;
//   logic[ROB_TAG_WIDTH -1:0]             rob_id;
//   lsu_op_e                              req_type;
//   logic[XLEN -1:0]                      ld_data;
//   logic [PREG_TAG_WIDTH-1:0]            ld_rd_idx;
//   logic                                 err;  
// } rrv64_lsu_l1d_resp_t;


endpackage