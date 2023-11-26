// translate rrv64 ruby tester req info to rvh l1d
// trans ruby store req to line req
module rrv2rvh_ruby_reqtype_trans
    import rvh_pkg::*;
    import uop_encoding_pkg::*;
    import rvh_l1d_pkg::*;
    import ruby_pkg::*; 
(
    input  lsu_op_e             rrv64_ruby_req_type_i,
    output ldu_minor_op_t       rvh_ld_req_type_o,
    output stu_minor_op_t       rvh_st_req_type_o,
    output logic                is_ld_o
);

always_comb begin
    rvh_ld_req_type_o = '0;
    rvh_st_req_type_o = '0;
    if     (rrv64_ruby_req_type_i == LSU_NONE             ) begin rvh_st_req_type_o = '0                   ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_LB               ) begin rvh_ld_req_type_o = LDU_LB               ; is_ld_o = 1'b1; end
    else if(rrv64_ruby_req_type_i == LSU_LBU              ) begin rvh_ld_req_type_o = LDU_LBU              ; is_ld_o = 1'b1; end
    else if(rrv64_ruby_req_type_i == LSU_LH               ) begin rvh_ld_req_type_o = LDU_LH               ; is_ld_o = 1'b1; end
    else if(rrv64_ruby_req_type_i == LSU_LHU              ) begin rvh_ld_req_type_o = LDU_LHU              ; is_ld_o = 1'b1; end
    else if(rrv64_ruby_req_type_i == LSU_LW               ) begin rvh_ld_req_type_o = LDU_LW               ; is_ld_o = 1'b1; end
    else if(rrv64_ruby_req_type_i == LSU_LWU              ) begin rvh_ld_req_type_o = LDU_LWU              ; is_ld_o = 1'b1; end
    else if(rrv64_ruby_req_type_i == LSU_LD               ) begin rvh_ld_req_type_o = LDU_LD               ; is_ld_o = 1'b1; end
    else if(rrv64_ruby_req_type_i == LSU_SB               ) begin rvh_st_req_type_o = STU_SB               ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_SH               ) begin rvh_st_req_type_o = STU_SH               ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_SW               ) begin rvh_st_req_type_o = STU_SW               ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_SD               ) begin rvh_st_req_type_o = STU_SD               ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_LRW              ) begin rvh_st_req_type_o = STU_LRW              ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_LRD              ) begin rvh_st_req_type_o = STU_LRD              ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_SCW              ) begin rvh_st_req_type_o = STU_SCW              ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_SCD              ) begin rvh_st_req_type_o = STU_SCD              ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOSWAPW         ) begin rvh_st_req_type_o = STU_AMOSWAPW         ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOSWAPD         ) begin rvh_st_req_type_o = STU_AMOSWAPD         ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOADDW          ) begin rvh_st_req_type_o = STU_AMOADDW          ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOADDD          ) begin rvh_st_req_type_o = STU_AMOADDD          ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOANDW          ) begin rvh_st_req_type_o = STU_AMOANDW          ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOANDD          ) begin rvh_st_req_type_o = STU_AMOANDD          ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOORW           ) begin rvh_st_req_type_o = STU_AMOORW           ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOORD           ) begin rvh_st_req_type_o = STU_AMOORD           ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOXORW          ) begin rvh_st_req_type_o = STU_AMOXORW          ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOXORD          ) begin rvh_st_req_type_o = STU_AMOXORD          ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOMAXW          ) begin rvh_st_req_type_o = STU_AMOMAXW          ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOMAXD          ) begin rvh_st_req_type_o = STU_AMOMAXD          ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOMAXUW         ) begin rvh_st_req_type_o = STU_AMOMAXUW         ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOMAXUD         ) begin rvh_st_req_type_o = STU_AMOMAXUD         ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOMINW          ) begin rvh_st_req_type_o = STU_AMOMINW          ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOMIND          ) begin rvh_st_req_type_o = STU_AMOMIND          ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOMINUW         ) begin rvh_st_req_type_o = STU_AMOMINUW         ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_AMOMINUD         ) begin rvh_st_req_type_o = STU_AMOMINUD         ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_FLW              ) begin rvh_ld_req_type_o = LDU_LW               ; is_ld_o = 1'b1; end
    else if(rrv64_ruby_req_type_i == LSU_FSW              ) begin rvh_st_req_type_o = STU_SW               ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_FLD              ) begin rvh_ld_req_type_o = LDU_LD               ; is_ld_o = 1'b1; end
    else if(rrv64_ruby_req_type_i == LSU_FSD              ) begin rvh_st_req_type_o = STU_SD               ; is_ld_o = 1'b0; end
    else if(rrv64_ruby_req_type_i == LSU_FENCE            ) begin rvh_st_req_type_o = STU_FENCE            ; is_ld_o = 1'b0; end
    // else if(rrv64_ruby_req_type_i == LSU_FENCEI           ) begin rvh_st_req_type_o = STU_FENCEI           ; is_ld_o = 1'b0; end
    // else if(rrv64_ruby_req_type_i == LSU_SFENCEVMA_ALL    ) begin rvh_st_req_type_o = STU_SFENCE_VMA       ; is_ld_o = 1'b0; end
    // else if(rrv64_ruby_req_type_i == LSU_SFENCEVMA_ASID   ) begin rvh_st_req_type_o = STU_SFENCE_VMA       ; is_ld_o = 1'b0; end
    // else if(rrv64_ruby_req_type_i == LSU_SFENCEVMA_VA     ) begin rvh_st_req_type_o = STU_SFENCE_VMA       ; is_ld_o = 1'b0; end
    // else if(rrv64_ruby_req_type_i == LSU_SFENCEVMA_ASID_VA) begin rvh_st_req_type_o = STU_SFENCE_VMA       ; is_ld_o = 1'b0; end
    

end



endmodule
