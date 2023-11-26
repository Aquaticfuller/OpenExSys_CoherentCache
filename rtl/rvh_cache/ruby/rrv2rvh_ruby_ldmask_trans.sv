// translate rrv64 ruby tester req info to rvh l1d
// trans ruby ld req to line req
module rrv2rvh_ruby_ldmask_trans
    import rvh_pkg::*;
    import uop_encoding_pkg::*;
    import rvh_l1d_pkg::*;
    import ruby_pkg::*; 
    import rrv64_core_param_pkg::*;
(
    input  logic [L1D_OFFSET_WIDTH-1:0]         ld_offset_i,
    input  logic [LDU_OP_WIDTH-1:0]             ld_opcode_i,
    output logic [L1D_STB_DATA_WIDTH/8-1:0]     ls_pipe_l1d_ld_req_data_byte_mask_o // data byte mask from stb
);

rrv64_l1d_req_type_dec_t        ld_opcode_dec;
logic [L1D_STB_DATA_WIDTH/8-1:0]    ls_pipe_l1d_ld_req_data_byte_mask_mid;

rvh_l1d_dec l1dc_dec_ruby_rvh_trans_u
(
    .is_ld_req_vld_i                (1'b1           ),
    .is_st_req_vld_i                (1'b0           ),
    .is_ptw_req_vld_i               (1'b0           ),
    .ls_pipe_l1d_ld_req_opcode_i    (ld_opcode_i    ),
    .ls_pipe_l1d_st_req_opcode_i    ('0             ),
    .req_type_dec_o                 (ld_opcode_dec  )
);
assign ls_pipe_l1d_ld_req_data_byte_mask_mid  = ld_opcode_dec.op_b  ? {{(L1D_STB_DATA_WIDTH/8-1){1'b0}}, 1'b1} :
                                                ld_opcode_dec.op_hw ? {{(L1D_STB_DATA_WIDTH/8-2){1'b0}}, 2'b11} :
                                                ld_opcode_dec.op_w  ? {{(L1D_STB_DATA_WIDTH/8-4){1'b0}}, 4'b1111} :
                                                ld_opcode_dec.op_dw ? {{(L1D_STB_DATA_WIDTH/8-8){1'b0}}, 8'b11111111} :
                                                                      '0;
assign ls_pipe_l1d_ld_req_data_byte_mask_o = ls_pipe_l1d_ld_req_data_byte_mask_mid << ld_offset_i;

endmodule
