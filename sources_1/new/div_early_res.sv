import st_pkg::*;

module div_early_res #(
    parameter IS_DOUBLE = 1,
    
    localparam DATA_W  = IS_DOUBLE ? 64 : 32,
    localparam MANT_W  = IS_DOUBLE ? 53 : 24,
    localparam EXP_W   = IS_DOUBLE ? 11 : 8
)(
    input  operand_type      operand1,
    input  operand_type      operand2,
    output [DATA_W - 1:0]    early_result,
    output fp_exception_type exceptions,
    output                   early_result_mx
);

wire res_sign;

wire snan_operand;
wire qnan_operand;
wire zero_by_zero;
wire inf_by_inf;
wire number_by_zero;
wire zero_by_number;
wire number_by_inf; // включая ноль
wire inf_by_number; // включая ноль

wire qnan_case;
wire inf_case;
wire zero_case;

assign res_sign = operand1.sign ^ operand2.sign;


assign snan_operand   =  operand1.flags.nan  & ~operand1.mant[MANT_W - 2] | 
                         operand2.flags.nan  & ~operand2.mant[MANT_W - 2] ;
                       
assign qnan_operand   =  operand1.flags.nan  &  operand1.mant[MANT_W - 2] | 
                         operand2.flags.nan  &  operand2.mant[MANT_W - 2] ;
                       
assign zero_by_zero   =  operand1.flags.zero &  operand2.flags.zero       ;

assign  inf_by_inf    =  operand1.flags.inf  &  operand2.flags.inf        ;

assign number_by_zero = ~operand1.flags.inf  & ~operand1.flags.zero       &
                        ~operand1.flags.nan  &  operand2.flags.zero       ;
                         
assign zero_by_number =  operand1.flags.zero & ~operand2.flags.zero       &
                        ~operand2.flags.inf  & ~operand2.flags.nan        ;
                        
assign number_by_inf  = ~operand1.flags.inf  &  operand2.flags.inf        &
                        ~operand1.flags.nan                               ;

assign inf_by_number  =  operand1.flags.inf  & ~operand2.flags.inf        &
                        ~operand2.flags.nan                               ;
                        
                        
assign exceptions.nv = snan_operand | zero_by_zero | inf_by_inf;
assign exceptions.dz = number_by_zero;
assign exceptions.of = 1'b0;
assign exceptions.uf = 1'b0;
assign exceptions.nx = 1'b0;


assign qnan_case = snan_operand   | qnan_operand  | zero_by_zero | inf_by_inf ;
assign zero_case = zero_by_number | number_by_inf                             ;
assign inf_case  = number_by_zero | inf_by_number                             ;


assign early_result_mx = qnan_case | zero_case | inf_case ;
                           
                           
assign early_result = {DATA_W{qnan_case}} & {res_sign, {EXP_W{1'b1}}, 1'b1, {(MANT_W - 2){1'b0}}} |
                      {DATA_W{zero_case}} & {res_sign,                      {(DATA_W - 1){1'b0}}} |
                      {DATA_W{inf_case }} & {res_sign, {EXP_W{1'b1}},       {(MANT_W - 1){1'b0}}} ;

endmodule
