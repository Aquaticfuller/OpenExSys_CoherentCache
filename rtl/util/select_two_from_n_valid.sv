`ifndef __SELECT_TWO_FROM_N_VALID_SV__
`define __SELECT_TWO_FROM_N_VALID_SV__
module select_two_from_n_valid
#(
    parameter int unsigned SEL_WIDTH = 8,
    localparam int unsigned SEL_ID_WIDHT = SEL_WIDTH > 1 ? $clog2(SEL_WIDTH) : 1
)
(
    input  logic[SEL_WIDTH-1:0] sel_i,
    input  logic first_id_needed_vld_i,
    input  logic second_id_needed_vld_i,
    output logic first_id_vld_o,
    output logic second_id_vld_o,
    output logic[SEL_ID_WIDHT-1:0] first_id_o,
    output logic[SEL_ID_WIDHT-1:0] second_id_o
);
genvar i;

logic[SEL_WIDTH-1:0]    sel_rev;
logic                   first_id_vld_mid;
logic                   secondid_vld_mid;
logic[SEL_ID_WIDHT-1:0] first_id_mid;
logic[SEL_ID_WIDHT-1:0] second_id_mid, second_id_mid_comp;



generate
  for(i = 0; i < SEL_WIDTH; i++) begin: sel_rev_gen
    assign sel_rev[i] = sel_i[SEL_WIDTH-1-i];
  end
endgenerate

priority_encoder
#(
  .SEL_WIDTH    (SEL_WIDTH)
)
first_vld_sel_u
(
  .sel_i      (sel_i            ),
  .id_vld_o   (first_id_vld_mid ),
  .id_o       (first_id_mid     )
);

priority_encoder
#(
  .SEL_WIDTH    (SEL_WIDTH)
)
second_vld_sel_u
(
  .sel_i      (sel_rev          ),
  .id_vld_o   (secondid_vld_mid ),
  .id_o       (second_id_mid    )
);
assign second_id_mid_comp = SEL_ID_WIDHT'(SEL_WIDTH-1-second_id_mid);

assign first_id_vld_o = first_id_vld_mid & first_id_needed_vld_i;
assign second_id_vld_o = secondid_vld_mid & (~(first_id_mid == second_id_mid_comp) | ~first_id_needed_vld_i) & second_id_needed_vld_i;
assign first_id_o     = first_id_mid;
assign second_id_o    = second_id_mid_comp;

endmodule
`endif