module rvh_l1d_dec
    import uop_encoding_pkg::*;
    import rvh_l1d_pkg::*;
(
    input  logic                          is_ld_req_vld_i,
    input  logic                          is_st_req_vld_i,
    input  logic                          is_ptw_req_vld_i,
    input  logic [      LDU_OP_WIDTH-1:0] ls_pipe_l1d_ld_req_opcode_i,
    input  logic [      STU_OP_WIDTH-1:0] ls_pipe_l1d_st_req_opcode_i,
    output rrv64_l1d_req_type_dec_t req_type_dec_o
);

assign req_type_dec_o.is_ld = is_ld_req_vld_i & (
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LB)    |
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LBU)   |
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LH)    |
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LHU)   |
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LW)    |
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LWU)   |
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LD ));//    |
                            // (ls_pipe_l1d_ld_req_opcode_i == LSU_FLW)   |
                            // (ls_pipe_l1d_ld_req_opcode_i == LSU_FLD)) ;

assign req_type_dec_o.is_ptw_ld = is_ptw_req_vld_i;

assign req_type_dec_o.is_st = is_st_req_vld_i & (
                            (ls_pipe_l1d_st_req_opcode_i == STU_SB)    |
                            (ls_pipe_l1d_st_req_opcode_i == STU_SH)    |
                            (ls_pipe_l1d_st_req_opcode_i == STU_SW)    |
                            (ls_pipe_l1d_st_req_opcode_i == STU_SD));//    |
                            // (ls_pipe_l1d_st_req_opcode_i == LSU_FSW)   |
                            // (ls_pipe_l1d_st_req_opcode_i == LSU_FSD)) ;

assign req_type_dec_o.is_lr = is_st_req_vld_i & (
                            (ls_pipe_l1d_st_req_opcode_i == STU_LRW) |
                            (ls_pipe_l1d_st_req_opcode_i == STU_LRD));

assign req_type_dec_o.is_sc = is_st_req_vld_i & (
                            (ls_pipe_l1d_st_req_opcode_i == STU_SCW) |
                            (ls_pipe_l1d_st_req_opcode_i == STU_SCD));

assign req_type_dec_o.is_amo = is_st_req_vld_i & (
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOSWAPW) |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOSWAPD) |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOADDW)  |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOADDD)  |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOANDW)  |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOANDD)  |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOORW)   |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOORD)   |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOXORW)  |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOXORD)  |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXW)  |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXD)  |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXUW) |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXUD) |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOMINW)  |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOMIND)  |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOMINUW) |
                             (ls_pipe_l1d_st_req_opcode_i == STU_AMOMINUD));

assign req_type_dec_o.amo_u   = (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXUW) |
                                (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXUD) |
                                (ls_pipe_l1d_st_req_opcode_i == STU_AMOMINUW) |
                                (ls_pipe_l1d_st_req_opcode_i == STU_AMOMINUD);

assign req_type_dec_o.op_b = is_ld_req_vld_i & (
                           (ls_pipe_l1d_ld_req_opcode_i ==LDU_LB) |
                           (ls_pipe_l1d_ld_req_opcode_i == LDU_LBU)) |
                           is_st_req_vld_i &
                           (ls_pipe_l1d_st_req_opcode_i == STU_SB ) ;
assign req_type_dec_o.op_hw = is_ld_req_vld_i & (
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LH )|
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LHU)) |
                            is_st_req_vld_i &
                            (ls_pipe_l1d_st_req_opcode_i == STU_SH );
assign req_type_dec_o.op_w =  is_ld_req_vld_i & (
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LW)    |
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LWU)
                            // (ls_pipe_l1d_ld_req_opcode_i == LSU_FLW))   |
                            ) |
                            is_st_req_vld_i & (
                            (ls_pipe_l1d_st_req_opcode_i == STU_SW)    |
                            (ls_pipe_l1d_st_req_opcode_i == STU_LRW)   |
                            (ls_pipe_l1d_st_req_opcode_i == STU_SCW)   |
                            // (ls_pipe_l1d_st_req_opcode_i == LSU_FSW)   |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOSWAPW) |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOADDW ) |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOANDW ) |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOORW )  |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOXORW ) |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXW ) |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXUW) |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOMINW ) |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOMINUW));
assign req_type_dec_o.op_dw = is_ld_req_vld_i & (
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LD )
                            // (ls_pipe_l1d_ld_req_opcode_i == LSU_FLD))   |
                            ) |
                            is_st_req_vld_i & (
                            (ls_pipe_l1d_st_req_opcode_i == STU_SD)    |
                            (ls_pipe_l1d_st_req_opcode_i == STU_LRD)   |
                            (ls_pipe_l1d_st_req_opcode_i == STU_SCD)   |
                            // (ls_pipe_l1d_st_req_opcode_i == LSU_FSD)   |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOSWAPD)  |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOADDD)   |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOANDD)   |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOORD)    |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOXORD )  |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXD )  |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXUD ) |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOMIND )  |
                            (ls_pipe_l1d_st_req_opcode_i == STU_AMOMINUD)) |
                            is_ptw_req_vld_i;
assign req_type_dec_o.ld_u =  is_ld_req_vld_i & (
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LBU )  |
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LHU )  |
                            (ls_pipe_l1d_ld_req_opcode_i == LDU_LWU ));

assign req_type_dec_o.amo_type =  ((ls_pipe_l1d_st_req_opcode_i == STU_AMOSWAPW) |
                                   (ls_pipe_l1d_st_req_opcode_i == STU_AMOSWAPD))? AMOSWAP :
                                  ((ls_pipe_l1d_st_req_opcode_i == STU_AMOADDW)  |
                                   (ls_pipe_l1d_st_req_opcode_i == STU_AMOADDD)) ? AMOADD :
                                  ((ls_pipe_l1d_st_req_opcode_i == STU_AMOANDW)  |
                                   (ls_pipe_l1d_st_req_opcode_i == STU_AMOANDD)) ? AMOAND :
                                  ((ls_pipe_l1d_st_req_opcode_i == STU_AMOORW)   |
                                   (ls_pipe_l1d_st_req_opcode_i == STU_AMOORD))  ? AMOOR :
                                  ((ls_pipe_l1d_st_req_opcode_i == STU_AMOXORW)  |
                                   (ls_pipe_l1d_st_req_opcode_i == STU_AMOXORD)) ? AMOXOR :
                                  ((ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXW ) |
                                   (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXD ) |  
                                   (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXUW) |
                                   (ls_pipe_l1d_st_req_opcode_i == STU_AMOMAXUD)
                                  ) ? AMOMAX : AMOMIN;

endmodule
