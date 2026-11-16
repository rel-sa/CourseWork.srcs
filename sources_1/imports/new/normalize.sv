module normalize #(
    parameter IS_DOUBLE = 1,

    localparam MANT_W = IS_DOUBLE ? 53 : 24,
    localparam LZC_W  = $clog2(MANT_W + 1)
)(
    input  [2*MANT_W - 1:0] mant_res,
    input  [LZC_W    - 1:0] leading_zero_dn,
    output [2*MANT_W - 1:0] mant_norm,
    output                  adj_norm
);

wire [2*MANT_W - 1:0] mant_transp;

genvar i;
generate
    for (i = 0; i < 2*MANT_W; i = i + 1) begin : gen_transp
        assign mant_transp[i] = mant_res[2*MANT_W - 1 - i];
    end
endgenerate

assign adj_norm  = mant_transp[leading_zero_dn];
assign mant_norm = (mant_res << !adj_norm) << leading_zero_dn;

endmodule
