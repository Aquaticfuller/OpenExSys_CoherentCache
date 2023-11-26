module rvh_l1d_alu
    import rvh_pkg::*;
    import uop_encoding_pkg::*;
(
    // Issue
    input  logic [      ALU_OP_WIDTH-1:0] issue_opcode_i,
    input  logic                          issue_op_w_i,
    input  logic [              XLEN-1:0] issue_operand0_i,
    input  logic [              XLEN-1:0] issue_operand1_i,

    // Write Back
    output logic [              XLEN-1:0] wb_data_o
);
    logic                     is_slt_type;

    // assign  issue_op_w_i =  (issue_opcode_i == ALU_ADDW)  |
    //                         (issue_opcode_i == ALU_SLLW)  |
    //                         (issue_opcode_i == ALU_SRLW)  |
    //                         (issue_opcode_i == ALU_SUBW)  |
    //                         (issue_opcode_i == ALU_SRAW)  ;

    assign is_slt_type   =  (issue_opcode_i == ALU_SLT)  |
                            (issue_opcode_i == ALU_SLTU)  ;


    // Add & Sub
    logic            is_unsigned;
    logic            is_sub;
    logic [XLEN+1:0] adder_operand0;
    logic [XLEN+1:0] adder_operand1;
    logic [  XLEN:0] adder_operand1_comp;

    logic [  XLEN:0] adder_result;
    logic            adder_result_is_neg;

    assign is_sub = (issue_opcode_i == ALU_SUB) | (issue_opcode_i == ALU_SUBW) |
        (issue_opcode_i == ALU_SLT) | (issue_opcode_i == ALU_SLTU);

    assign is_unsigned = (issue_opcode_i == ALU_SLTU);

    assign adder_operand1_comp = {issue_operand1_i, 1'b0} ^ {XLEN + 1{is_sub}};

    assign adder_operand0 = {
        ~is_unsigned & issue_operand0_i[XLEN-1], {issue_operand0_i[XLEN-1:0]}, 1'b1
    };
    assign adder_operand1 = {~is_unsigned & issue_operand1_i[XLEN-1], adder_operand1_comp};
    assign {adder_result_is_neg, adder_result} = adder_operand0 + adder_operand1;

    logic [XLEN-1:0] add_rslt;  // Add or Sub


    assign add_rslt =   is_slt_type ? {{XLEN-1{1'b0}},~adder_result_is_neg} :
                        issue_op_w_i ? XLEN'({{XLEN{adder_result[32]}},adder_result[32:1]}) :
                        adder_result[XLEN:1];

    // Shift
    logic                    is_logic_shf;
    logic                    is_inv_shf;
    logic [        XLEN-1:0] rshf_data_inv;
    logic [        XLEN : 0] rshf_data_inv_fin;
    logic [        XLEN : 0] rshf_data_no_inv_fin;
    logic [        XLEN : 0] rshf_data;
    logic [        XLEN : 0] rshf_rslt;
    logic [        XLEN-1:0] rshf_rslt64_inv;
    logic [          32-1:0] rshf_rslt32_inv;
    logic [$clog2(XLEN)-1:0] rshf_amt;
    logic [        XLEN-1:0] shf_rslt;


    assign is_logic_shf = (issue_opcode_i == ALU_SLL) | (issue_opcode_i == ALU_SRL) |
        (issue_opcode_i == ALU_SLLW) | (issue_opcode_i == ALU_SRLW);
    assign is_inv_shf = (issue_opcode_i == ALU_SLL) | (issue_opcode_i == ALU_SLLW);
    generate
        for(genvar i=0;i<XLEN;i++)begin : GEN_RSHF_DATA64_INV
            assign  rshf_data_inv[i]    = issue_operand0_i[XLEN-1-i];
            assign  rshf_rslt64_inv[i]  = rshf_rslt[XLEN-1-i];
        end


        for(genvar i=0;i<32;i++)begin : GEN_RSHF_DATA32_INV
            assign  rshf_rslt32_inv[i]  = rshf_rslt[32-1-i];
        end
    endgenerate
    //for word shift left, shift amount should add 32
    assign rshf_amt = {
        (issue_op_w_i & is_inv_shf | (~issue_op_w_i) & issue_operand1_i[5]), issue_operand1_i[4:0]
    };
    assign rshf_data_inv_fin = {1'b0, rshf_data_inv};  //left shift
    //right shift(A and L)
    assign rshf_data_no_inv_fin = {XLEN + 1{issue_op_w_i & is_logic_shf}} &
        {33'h0, issue_operand0_i[0+:32]} | {XLEN + 1{issue_op_w_i & ~is_logic_shf}} &
        {{33{issue_operand0_i[31]}}, issue_operand0_i[0+:32]} |
        {XLEN + 1{~issue_op_w_i & is_logic_shf}} & {1'b0, issue_operand0_i} |
        {XLEN + 1{~issue_op_w_i & ~is_logic_shf}} & {issue_operand0_i[63], issue_operand0_i};
    assign rshf_data = is_inv_shf ? rshf_data_inv_fin : rshf_data_no_inv_fin;
    assign rshf_rslt = $signed(rshf_data) >>> rshf_amt;
    assign shf_rslt = {XLEN{issue_op_w_i & is_inv_shf}} &
        {{32{rshf_rslt32_inv[31]}}, rshf_rslt32_inv[0+:32]} |  //W shift
        {XLEN{issue_op_w_i & ~is_inv_shf}} & {{32{rshf_rslt[31]}}, rshf_rslt[0+:32]} |
        {XLEN{~issue_op_w_i & is_inv_shf}} & rshf_rslt64_inv |
        {XLEN{~issue_op_w_i & ~is_inv_shf}} & rshf_rslt[XLEN-1:0];


    // Logic Operation
    logic is_or, is_and, is_xor;

    logic [XLEN-1:0] result_xor;
    logic [XLEN-1:0] result_and;
    logic [XLEN-1:0] result_or;
    logic [XLEN-1:0] logic_rslt;

    assign is_or = issue_opcode_i == ALU_OR;
    assign is_and = issue_opcode_i == ALU_AND;
    assign is_xor = issue_opcode_i == ALU_XOR;

    assign result_xor = issue_operand0_i ^ issue_operand1_i;
    assign result_and = issue_operand0_i & issue_operand1_i;
    assign result_or = issue_operand0_i | issue_operand1_i;

    assign logic_rslt = (result_xor & {XLEN{is_xor}}) | (result_or & {XLEN{is_or}}) |
        (result_and & {XLEN{is_and}});


    // output
    logic is_add_type, is_shf_type, is_logic_type;
    assign is_logic_type = issue_opcode_i == ALU_AND | issue_opcode_i == ALU_OR |
        issue_opcode_i == ALU_XOR;
    assign is_shf_type = is_logic_shf | issue_opcode_i == ALU_SRA | issue_opcode_i == ALU_SRAW;
    assign is_add_type = ~(is_logic_type | is_shf_type);

    assign wb_data_o = is_add_type ?
        add_rslt : ({XLEN{is_logic_type}} & logic_rslt | {XLEN{is_shf_type}} & shf_rslt);


endmodule : rvh_l1d_alu
