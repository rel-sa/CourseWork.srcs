import st_pkg::*;

module early_res #(
    parameter IS_DOUBLE = 1,
    
    localparam DATA_W  = IS_DOUBLE ? 64 : 32,
    localparam MANT_W  = IS_DOUBLE ? 53 : 24,
    localparam EXP_W   = IS_DOUBLE ? 11 : 8
)(
    input  operand_type   operand1,
    input  operand_type   operand2,
    output [DATA_W - 1:0] early_result
);

wire zero_and_inf  = operand1.flags.zero & operand2.flags.inf | operand2.flags.zero & operand1.flags.inf;
wire two_subnormal = operand1.flags.subnormal & operand2.flags.subnormal;
wire zero          = operand1.flags.zero | operand2.flags.zero | two_subnormal;
wire inf           = operand1.flags.inf  | operand2.flags.inf;

wire res_sign      = operand1.sign ^ operand2.sign;

assign early_result = operand1.flags.nan ? {operand1.sign,  operand1.exp, 1'b1,  operand1.mant[MANT_W - 3 : 0]} : 
                      operand2.flags.nan ? {operand2.sign,  operand2.exp, 1'b1,  operand2.mant[MANT_W - 3 : 0]} :
                      zero_and_inf       ? {1'b1,          {EXP_W{1'b1}}, 1'b1, {MANT_W-2{1'b0}}              } :
                      {DATA_W{zero}}     & {res_sign,      {EXP_W{1'b0}},       {MANT_W-1{1'b0}}              } |
                      {DATA_W{inf}}      & {res_sign,      {EXP_W{1'b1}},       {MANT_W-1{1'b0}}              } ;

endmodule
