module op_an #(
    parameter IS_DOUBLE = 1,
    
    localparam DATA_W  = IS_DOUBLE ? 64 : 32,
    localparam MANT_W  = IS_DOUBLE ? 53 : 24,
    localparam EXP_W   = IS_DOUBLE ? 11 : 8
)(
    input  [DATA_W - 1:0] op,
    output operand_type   operand
);

wire [MANT_W - 2:0] mant_raw;
wire [EXP_W - 1:0]  exp_raw;
assign mant_raw = op[MANT_W - 2 : 0];
assign exp_raw  = op[DATA_W - 2: MANT_W - 1];

assign operand.flags.nan       = ( &exp_raw) & ( |mant_raw);
assign operand.flags.inf       = ( &exp_raw) & (~|mant_raw);
assign operand.flags.zero      = (~|exp_raw) & (~|mant_raw);
assign operand.flags.subnormal = (~|exp_raw) & ( |mant_raw);

assign operand.sign = op[DATA_W - 1];
assign operand.exp  = exp_raw + operand.flags.subnormal;
assign operand.mant = {|exp_raw, mant_raw};

endmodule
