// translate rrv64 ruby tester req info to rvh l1d
// trans line resp to ruby store resp
// module resptype_rrv2rvh_ruby_trans
//     import rvh_pkg::*;
//     import uop_encoding_pkg::*;
//     import rvh_l1d_pkg::*;
//     import ruby_pkg::*; 
// (
//     input  rrv64_l1d_req_type_dec_t rvh_ld_resp_type_i,
//     output lsu_op_e                 rrv64_ruby_resp_type_o
// );

// assign rrv64_ruby_resp_type_o = rvh_ld_resp_type_i.is_ld

// endmodule


/*
module resptype_rrv2rvh_ruby_trans
    import rvh_pkg::*;
    import uop_encoding_pkg::*;
    import rvh_l1d_pkg::*;
    import ruby_pkg::*; 
(
    input  ldu_minor_op_t       rvh_ld_resp_type_i,
    output lsu_op_e             rrv64_ruby_resp_type_o
);

always_comb begin
    
    if     (rvh_ld_req_type_i == LDU_LB        ) begin rrv64_ruby_req_type_o = LSU_LB               ; end
    else if(rvh_ld_req_type_i == LDU_LBU       ) begin rrv64_ruby_req_type_o = LSU_LBU              ; end
    else if(rvh_ld_req_type_i == LDU_LH        ) begin rrv64_ruby_req_type_o = LSU_LH               ; end
    else if(rvh_ld_req_type_i == LDU_LHU       ) begin rrv64_ruby_req_type_o = LSU_LHU              ; end
    else if(rvh_ld_req_type_i == LDU_LW        ) begin rrv64_ruby_req_type_o = LSU_LW               ; end
    else if(rvh_ld_req_type_i == LDU_LWU       ) begin rrv64_ruby_req_type_o = LSU_LWU              ; end
    else if(rvh_ld_req_type_i == LDU_LD        ) begin rrv64_ruby_req_type_o = LSU_LD               ; end
    // else if(rvh_ld_req_type_i == STU_SB        ) begin rrv64_ruby_req_type_o = LSU_SB               ; end
    // else if(rvh_ld_req_type_i == STU_SH        ) begin rrv64_ruby_req_type_o = LSU_SH               ; end
    // else if(rvh_ld_req_type_i == STU_SW        ) begin rrv64_ruby_req_type_o = LSU_SW               ; end
    // else if(rvh_ld_req_type_i == STU_SD        ) begin rrv64_ruby_req_type_o = LSU_SD               ; end
    else if(rvh_ld_req_type_i == LDU_LRW       ) begin rrv64_ruby_req_type_o = LSU_LRW              ; end
    else if(rvh_ld_req_type_i == LDU_LRD       ) begin rrv64_ruby_req_type_o = LSU_LRD              ; end
    // else if(rvh_ld_req_type_i == STU_SCW       ) begin rrv64_ruby_req_type_o = LSU_SCW              ; end
    // else if(rvh_ld_req_type_i == STU_SCD       ) begin rrv64_ruby_req_type_o = LSU_SCD              ; end
    // else if(rvh_ld_req_type_i == STU_AMOSWAPW  ) begin rrv64_ruby_req_type_o = LSU_AMOSWAPW         ; end
    // else if(rvh_ld_req_type_i == STU_AMOSWAPD  ) begin rrv64_ruby_req_type_o = LSU_AMOSWAPD         ; end
    // else if(rvh_ld_req_type_i == STU_AMOADDW   ) begin rrv64_ruby_req_type_o = LSU_AMOADDW          ; end
    // else if(rvh_ld_req_type_i == STU_AMOADDD   ) begin rrv64_ruby_req_type_o = LSU_AMOADDD          ; end
    // else if(rvh_ld_req_type_i == STU_AMOANDW   ) begin rrv64_ruby_req_type_o = LSU_AMOANDW          ; end
    // else if(rvh_ld_req_type_i == STU_AMOANDD   ) begin rrv64_ruby_req_type_o = LSU_AMOANDD          ; end
    // else if(rvh_ld_req_type_i == STU_AMOORW    ) begin rrv64_ruby_req_type_o = LSU_AMOORW           ; end
    // else if(rvh_ld_req_type_i == STU_AMOORD    ) begin rrv64_ruby_req_type_o = LSU_AMOORD           ; end
    // else if(rvh_ld_req_type_i == STU_AMOXORW   ) begin rrv64_ruby_req_type_o = LSU_AMOXORW          ; end
    // else if(rvh_ld_req_type_i == STU_AMOXORD   ) begin rrv64_ruby_req_type_o = LSU_AMOXORD          ; end
    // else if(rvh_ld_req_type_i == STU_AMOMAXW   ) begin rrv64_ruby_req_type_o = LSU_AMOMAXW          ; end
    // else if(rvh_ld_req_type_i == STU_AMOMAXD   ) begin rrv64_ruby_req_type_o = LSU_AMOMAXD          ; end
    // else if(rvh_ld_req_type_i == STU_AMOMAXUW  ) begin rrv64_ruby_req_type_o = LSU_AMOMAXUW         ; end
    // else if(rvh_ld_req_type_i == STU_AMOMAXUD  ) begin rrv64_ruby_req_type_o = LSU_AMOMAXUD         ; end
    // else if(rvh_ld_req_type_i == STU_AMOMINW   ) begin rrv64_ruby_req_type_o = LSU_AMOMINW          ; end
    // else if(rvh_ld_req_type_i == STU_AMOMIND   ) begin rrv64_ruby_req_type_o = LSU_AMOMIND          ; end
    // else if(rvh_ld_req_type_i == STU_AMOMINUW  ) begin rrv64_ruby_req_type_o = LSU_AMOMINUW         ; end
    // else if(rvh_ld_req_type_i == STU_AMOMINUD  ) begin rrv64_ruby_req_type_o = LSU_AMOMINUD         ; end
    else if(rvh_ld_req_type_i == LDU_LW        ) begin rrv64_ruby_req_type_o = LSU_FLW              ; end
    // else if(rvh_ld_req_type_i == STU_SW        ) begin rrv64_ruby_req_type_o = LSU_FSW              ; end
    else if(rvh_ld_req_type_i == LDU_LD        ) begin rrv64_ruby_req_type_o = LSU_FLD              ; end
    // else if(rvh_ld_req_type_i == STU_SD        ) begin rrv64_ruby_req_type_o = LSU_FSD              ; end
    // else if(rvh_ld_req_type_i == STU_FENCE     ) begin rrv64_ruby_req_type_o = LSU_FENCE            ; end
    // else if(rvh_ld_req_type_i == STU_FENCEI    ) begin rrv64_ruby_req_type_o = LSU_FENCEI           ; end
    // else if(rvh_ld_req_type_i == STU_SFENCE_VMA) begin rrv64_ruby_req_type_o = LSU_SFENCEVMA_ALL    ; end
    // else if(rvh_ld_req_type_i == STU_SFENCE_VMA) begin rrv64_ruby_req_type_o = LSU_SFENCEVMA_ASID   ; end
    // else if(rvh_ld_req_type_i == STU_SFENCE_VMA) begin rrv64_ruby_req_type_o = LSU_SFENCEVMA_VA     ; end
    // else if(rvh_ld_req_type_i == STU_SFENCE_VMA) begin rrv64_ruby_req_type_o = LSU_SFENCEVMA_ASID_VA; end
    else rrv64_ruby_req_type_i = LSU_NONE;
    

end



endmodule
*/