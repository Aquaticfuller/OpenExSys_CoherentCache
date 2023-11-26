package rrv64_core_func_pkg;
    import rrv64_core_param_pkg::*;
    import rrv64_core_typedef_pkg::*;

  function automatic void rrv64_get_fault_type (
    input rrv64_access_type_t access_type,
    output rrv64_excp_cause_t excp_cause
  );
    case (access_type)
      RRV64_ACCESS_FETCH: begin
        excp_cause = RRV64_EXCP_CAUSE_INST_PAGE_FAULT;
      end
      RRV64_ACCESS_LOAD: begin
        excp_cause = RRV64_EXCP_CAUSE_LOAD_PAGE_FAULT;
      end
      RRV64_ACCESS_STORE: begin
        excp_cause = RRV64_EXCP_CAUSE_STORE_PAGE_FAULT;
      end
      RRV64_ACCESS_AMO: begin
        excp_cause = RRV64_EXCP_CAUSE_STORE_PAGE_FAULT;
      end
      default: begin
        excp_cause = RRV64_EXCP_CAUSE_NONE;
      end
    endcase
  endfunction

  function automatic void rrv64_get_excp_perm_type (
    input rrv64_access_type_t access_type,
    output rrv64_excp_cause_t excp_cause
  );
    case (access_type)
      RRV64_ACCESS_FETCH: begin
        excp_cause = RRV64_EXCP_CAUSE_INST_ACCESS_FAULT;
      end
      RRV64_ACCESS_LOAD: begin
        excp_cause = RRV64_EXCP_CAUSE_LOAD_ACCESS_FAULT;
      end
      RRV64_ACCESS_STORE: begin
        excp_cause = RRV64_EXCP_CAUSE_STORE_ACCESS_FAULT;
      end
      RRV64_ACCESS_AMO: begin
        excp_cause = RRV64_EXCP_CAUSE_STORE_ACCESS_FAULT;
      end
      default: begin
        excp_cause = RRV64_EXCP_CAUSE_NONE;
      end
    endcase
  endfunction
  //
  //
  //
  function automatic void rrv64_func_break_inst_rvc (
    output  rrv64_rvc_opcode_t  rvc_opcode,
    output  logic [ 2:0]  rvc_funct3,
    output  logic [ 1:0]  rvc_funct2_hi, rvc_funct2_lo,
    output  logic         rvc_funct1,
    output  rrv64_reg_addr_t    rvc_rs1_addr, rvc_rs2_addr, rvc_rd_addr, rvc_rs1_prime_addr, rvc_rs2_prime_addr, rvc_rd_prime_addr,
    output  rrv64_data_t        rvc_nzuimm_9_2, rvc_uimm_7_3, rvc_uimm_8_4, rvc_uimm_6_2, rvc_nzimm_5_0, rvc_nzuimm_5_0, rvc_imm_11_1, rvc_imm_5_0, rvc_nzimm_9_4, rvc_nzimm_17_12, rvc_imm_8_1, rvc_uimm_8_3, rvc_uimm_9_4, rvc_uimm_7_2, rvc_uimm_8_3_c2, rvc_uimm_9_4_c2, rvc_uimm_7_2_c2,
    input   rrv64_instr_t        inst
  );
    rvc_opcode  = rrv64_rvc_opcode_t'(inst[1:0]);
    rvc_funct3  = inst[15:13];
    rvc_funct1  = inst[12];
    rvc_funct2_hi = inst[11:10];
    rvc_funct2_lo = inst[6:5];

    rvc_rs1_addr        = inst[11:7];
    rvc_rs2_addr        = inst[6:2];
    rvc_rd_addr         = inst[11:7];
    rvc_rs1_prime_addr  = 5'({2'b01, inst[9:7]});
    rvc_rs2_prime_addr  = 5'({2'b01, inst[4:2]});
    rvc_rd_prime_addr   = 5'({2'b01, inst[9:7]});

    rvc_nzuimm_9_2  = RRV64_XLEN'({ 64'b0, inst[10:7], inst[12:11], inst[5], inst[6], 2'b0});
    rvc_uimm_7_3    = RRV64_XLEN'({ 64'b0, inst[6:5], inst[12:10], 3'b0});
    rvc_uimm_8_4    = RRV64_XLEN'({ 64'b0, inst[10], inst[6:5], inst[12:11], 4'b0});
    rvc_uimm_6_2    = RRV64_XLEN'({ 64'b0, inst[5], inst[12:10], inst[6], 2'b0});
    rvc_nzimm_5_0   = RRV64_XLEN'({ {64{inst[12]}}, inst[12], inst[6:2]});
    rvc_nzuimm_5_0  = RRV64_XLEN'({ 64'b0, inst[12], inst[6:2]});
    rvc_imm_11_1    = RRV64_XLEN'({ {64{inst[12]}}, inst[12], inst[8], inst[10:9], inst[6], inst[7], inst[2], inst[11], inst[5:3], 1'b0});
    rvc_imm_5_0     = RRV64_XLEN'({ {64{inst[12]}}, inst[12], inst[6:2]});
    rvc_nzimm_9_4   = RRV64_XLEN'({ {64{inst[12]}}, inst[12], inst[4:3], inst[5], inst[2], inst[6], 4'b0});
    rvc_nzimm_17_12 = RRV64_XLEN'({ {64{inst[12]}}, inst[12], inst[6:2], 12'b0});
    rvc_imm_8_1     = RRV64_XLEN'({ {64{inst[12]}}, inst[12], inst[6:5], inst[2], inst[11:10], inst[4:3], 1'b0});
    rvc_uimm_8_3    = RRV64_XLEN'({ 64'b0, inst[4:2], inst[12], inst[6:5], 3'b0});
    rvc_uimm_9_4    = RRV64_XLEN'({ 64'b0, inst[5:2], inst[12], inst[6], 4'b0});
    rvc_uimm_7_2    = RRV64_XLEN'({ 64'b0, inst[3:2], inst[12], inst[6:4], 2'b0});
    rvc_uimm_8_3_c2 = RRV64_XLEN'({ 64'b0, inst[9:7], inst[12:10], 3'b0});
    rvc_uimm_9_4_c2 = RRV64_XLEN'({ 64'b0, inst[10:7], inst[12:11], 4'b0});
    rvc_uimm_7_2_c2 = RRV64_XLEN'({ 64'b0, inst[8:7], inst[12:9], 2'b0});
  endfunction


  function automatic void func_break_inst (
    output  rrv64_opcode_t      opcode,
    output  rrv64_reg_addr_t    rd_addr, rs1_addr, rs2_addr, rs3_addr,
    output  logic [ 1:0]  funct2,
    output  logic [ 2:0]  funct3,
    output  logic [ 4:0]  funct5,
    output  logic [ 5:0]  funct6,
    output  logic [ 6:0]  funct7,
    output  logic [11:0]  funct12,
    //output  logic [ 1:0]  fmt,
    output  rrv64_data_t        i_imm, s_imm, b_imm, u_imm, j_imm, z_imm,
    output  rrv64_frm_e         frm,
    input   rrv64_instr_t       inst
  );
    opcode    = rrv64_opcode_t'(inst[6:2]);
    rd_addr   = inst[11:7];
    rs1_addr  = inst[19:15];
    rs2_addr  = inst[24:20];
    rs3_addr  = inst[31:27];
    funct2    = inst[26:25];
    funct3    = inst[14:12];
    funct5    = inst[24:20];
    funct6    = inst[31:26];
    funct7    = inst[31:25];
    funct12   = inst[31:20];

    //fmt       = inst[26:25];

    i_imm = { {53{inst[31]}}, inst[30:20] };
    s_imm = { {53{inst[31]}}, inst[30:25], inst[11:7]};
    b_imm = { {52{inst[31]}}, inst[7], inst[30:25], inst[11:8]};
    u_imm = { {32{inst[31]}}, inst[31:12]};
    j_imm = { {44{inst[31]}}, inst[19:12], inst[20], inst[30:21]};
    z_imm = { 59'b0, inst[19:15] };

    frm = rrv64_frm_e'(inst[14:12]);
  endfunction

endpackage
