import st_pkg::*;

module add_early_res #(
    parameter IS_DOUBLE = 1,
    
    localparam DATA_W  = IS_DOUBLE ? 64 : 32,
    localparam MANT_W  = IS_DOUBLE ? 53 : 24,
    localparam EXP_W   = IS_DOUBLE ? 11 : 8
)(
    input  operand_type      operand1,
    input  operand_type      operand2,
    input                    sub,
    input  round_mode_type   round_mode,
    output [DATA_W - 1:0]    early_result,
    output fp_exception_type exceptions,
    output                   early_result_mx
);

operand_type operand2_eff;

wire s2_eff_sign;
wire res_sign;

wire snan_operand;
wire qnan_operand;
wire two_diff_infs;
wire two_same_infs;
wire inf_and_number; // включая ноль
wire number_and_inf; // включая ноль
wire two_zeros;
wire zero_and_number;
wire number_and_zero;

wire qnan_case;
wire s1_signed_inf;

wire zero_sign;


assign s2_eff_sign = operand2.sign ^ sub;
assign res_sign    = operand1.sign ^ s2_eff_sign;

assign operand2_eff.sign  = s2_eff_sign;

assign operand2_eff.flags = operand2.flags ;
assign operand2_eff.exp   = operand2.exp   ;
assign operand2_eff.mant  = operand2.mant  ;

assign snan_operand    =  operand1.flags.nan  & ~operand1.mant[MANT_W - 2] |
                          operand2.flags.nan  & ~operand2.mant[MANT_W - 2] ;
                       
assign qnan_operand    = ~snan_operand                                     &
                         (operand1.flags.nan  &  operand1.mant[MANT_W - 2] | 
                          operand2.flags.nan  &  operand2.mant[MANT_W - 2]);
                       
assign two_diff_infs   =  operand1.flags.inf  &  operand2.flags.inf        &
                         (operand1.sign       != operand2_eff.sign)        ;
                       
assign two_same_infs   =  operand1.flags.inf  &  operand2.flags.inf        &
                         (operand1.sign       == operand2_eff.sign)        ;
                       
assign inf_and_number  =  operand1.flags.inf  & ~operand2.flags.inf        &
                         ~operand2.flags.nan                               ;

assign number_and_inf  = ~operand1.flags.inf  &  ~operand2.flags.nanoperand2.flags.inf        ;

assign two_zeros       =  operand1.flags.zero &  operand2.flags.zero       ;

assign zero_and_number =  operand1.flags.zero                              & 
                         ~operand2.flags.zero & ~operand2.flags.inf        ;
                         
assign number_and_zero = ~operand1.flags.zero & ~operand1.flags.inf        &
                          operand2.flags.zero                              ;


assign qnan_case     = snan_operand  | qnan_operand   | two_diff_infs ;
assign s1_signed_inf = two_same_infs | inf_and_number                 ;


assign exceptions.nv = snan_operand  | two_diff_infs  ;

assign exceptions.dz = 1'b0 ;
assign exceptions.of = 1'b0 ;
assign exceptions.uf = 1'b0 ;
assign exceptions.nx = 1'b0 ;


assign early_result_mx = snan_operand  | qnan_operand    | two_diff_infs   | 
                         two_same_infs | inf_and_number  | number_and_inf  |
                         two_zeros     | zero_and_number | number_and_zero ;


assign zero_sign = operand1.sign == operand2_eff.sign ? operand1.sign      :
                                                        round_mode == INFN ;
                           
                           
assign early_result = {DATA_W{qnan_case      }} & {res_sign         , {EXP_W{1'b1}}, 1'b1, {(MANT_W - 2){1'b0}}} |
                      {DATA_W{s1_signed_inf  }} & {operand1.sign    , {EXP_W{1'b1}},       {(DATA_W - 1){1'b0}}} |
                      {DATA_W{number_and_inf }} & {operand2_eff.sign, {EXP_W{1'b1}},       {(DATA_W - 1){1'b0}}} |
                      {DATA_W{two_zeros      }} & {zero_sign        , {EXP_W{1'b0}},       {(DATA_W - 1){1'b0}}} |
                      {DATA_W{zero_and_number}} &  operand2_eff                                                  |
                      {DATA_W{number_and_zero}} &  operand1                                                      |
                                                  {DATA_W{1'b0}}                                                 ;

endmodule
