module exp_corr #(
    parameter IS_DOUBLE = 1,
    
    localparam EXP_W  = IS_DOUBLE ? 11 : 8,
    localparam MANT_W = IS_DOUBLE ? 53 : 24,
    localparam MAX_EXP = (1 << EXP_W) - 1,
    localparam LZC_W  = $clog2(MANT_W + 1)
)(
    input  [EXP_W + 1:0] exp_summ,
    input                adj_round,
    input                adj_norm,
    input  [LZC_W - 1:0] leading_zero_dn,
    output [EXP_W - 1:0] exp_res,
    output               exp_summ_uflow,
    output               exp_summ_oflow
);

wire [EXP_W + 1:0] exp_res_ext;
assign exp_res_ext = exp_summ + adj_round + adj_norm - leading_zero_dn;

assign exp_summ_uflow =  exp_res_ext[EXP_W + 1] | (~|exp_res_ext);
assign exp_summ_oflow = ~exp_res_ext[EXP_W + 1] & (exp_res_ext >= MAX_EXP);

assign exp_res = exp_res_ext[EXP_W - 1:0];


endmodule