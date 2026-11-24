module lz_count#(
    parameter IS_DOUBLE = 1,
    parameter MANT_W    = IS_DOUBLE ? 53 : 24,
    
    localparam LZC_W = $clog2(MANT_W + 1)
)(
    input  [MANT_W - 1:0] subnormal_mant,
    output [LZC_W - 1:0]  leading_zero_dn
);

wire [LZC_W - 1:0] lz_temp [0:MANT_W];

assign lz_temp[0] = MANT_W;

genvar i;
generate
    for (i = 0; i < MANT_W; i = i + 1) begin : gen_lzc
        assign lz_temp[i + 1] = lz_temp[i] != MANT_W           ? lz_temp[i] :
                                subnormal_mant[MANT_W - 1 - i] ? i          :
                                                                 MANT_W     ;
    end
endgenerate

assign leading_zero_dn = lz_temp[MANT_W];

endmodule
