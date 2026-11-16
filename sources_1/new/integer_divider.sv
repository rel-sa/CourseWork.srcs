module integer_divider #(
    parameter IS_DOUBLE = 1,
    
    localparam FRAC_W  = IS_DOUBLE ? 55 : 26,
    localparam MANT_W  = IS_DOUBLE ? 53 : 24,
    localparam QUOT_W  = MANT_W + FRAC_W,
    localparam COUNT_W = $clog2(QUOT_W)
)(
    input      [MANT_W - 1:0] mant1,
    input      [MANT_W - 1:0] mant2,
    input                     clk,
    input                     rst,
    input                     run,
    output reg                val,
    output reg [QUOT_W - 1:0] divided_mant,
    output reg [MANT_W - 1:0] remainder,
    output reg                div_by_zero
);

wire                 subtract;
wire [MANT_W + 1:0]  partial_remainder_shift;
wire [MANT_W + 1:0]  partial_remainder_operand;
wire [MANT_W + 1:0]  divisor_operand;
wire [MANT_W + 1:0]  partial_remainder_next;
wire [QUOT_W - 1:0]  quotient_next;
                                          
reg                  busy;
reg  [QUOT_W - 1:0]  quotient_reg;
reg  [MANT_W + 1:0]  divisor_reg;
reg  [MANT_W + 1:0]  partial_remainder_reg;
reg  [COUNT_W - 1:0] count_reg;
reg                  finish_reg;
reg                  div_by_zero_reg;

// Выбор сложения или вычитания по знаку предыдущего остатка: (< 0) => +, (>= 0) => -
assign subtract = ~partial_remainder_reg[MANT_W + 1] & ~finish_reg;

assign partial_remainder_shift   = {partial_remainder_reg[MANT_W : 0], quotient_reg[QUOT_W - 1]};
assign partial_remainder_operand = finish_reg ? partial_remainder_reg   : 
                                                partial_remainder_shift ;

assign divisor_operand = finish_reg & ~partial_remainder_reg[MANT_W + 1] ? {(MANT_W + 2){1'b0}}                    :
                                                                            divisor_reg ^ {(MANT_W + 2){subtract}} ;
                                                                            
assign partial_remainder_next = partial_remainder_operand + divisor_operand + {{(MANT_W + 1){1'b0}}, subtract};

assign quotient_next = {quotient_reg[QUOT_W - 2:0], ~partial_remainder_next[MANT_W + 1]};

always @(posedge clk)
if (rst)
    val <= 1'b0;
else
    val <= finish_reg ? 1'b1 :
                        1'b0 ;
                        
always @(posedge clk)
if (rst)
    div_by_zero_reg <= 1'b0;
else
    div_by_zero_reg <= ~busy & run ? ~|mant2         :
                                     div_by_zero_reg ;
                                     
always @(posedge clk)
if (rst)
    div_by_zero <= 1'b0;
else
    div_by_zero <= finish_reg ? div_by_zero_reg :
                                div_by_zero     ;
                                
always @(posedge clk)
if (rst)
    divided_mant <= {QUOT_W{1'b0}};
else
    divided_mant <= finish_reg & div_by_zero_reg ? {QUOT_W{1'b1}} :
                    finish_reg                   ?  quotient_reg  :
                                                    divided_mant  ;
                                       
always @(posedge clk)
if (rst)
    count_reg <= {COUNT_W{1'b0}};
else
    count_reg <= ~busy &  run                           ? QUOT_W - 1'b1    :
                  busy & ~finish_reg & (count_reg != 0) ? count_reg - 1'b1 :
                                                          count_reg        ;
                                  
always @(posedge clk)
if (rst)
    remainder <= {MANT_W{1'b0}};
else
    remainder <= finish_reg & div_by_zero_reg ? {MANT_W{1'b0}}                       :
                 finish_reg                   ? partial_remainder_next[MANT_W - 1:0] :
                                                remainder                            ;

always @(posedge clk)
if (rst)
    busy <= 1'b0;
else
    busy <= ~busy & run ? 1'b1 :
             finish_reg ? 1'b0 :
                          busy ;

always @(posedge clk)
if (rst)
    finish_reg <= 1'b0;
else
    finish_reg <= ~busy & run | finish_reg ? 1'b0       :
                   busy & (count_reg == 0) ? 1'b1       :
                                             finish_reg ;

always @(posedge clk)
if (rst)
    quotient_reg <= {QUOT_W{1'b0}};
else
    quotient_reg <= ~busy &  run        ? {mant1, {FRAC_W{1'b0}}} :
                     busy & ~finish_reg ?  quotient_next          :
                                           quotient_reg           ;

always @(posedge clk)
if (rst)
    divisor_reg <= {(MANT_W + 2){1'b0}};
else
    divisor_reg <= ~busy & run ? {2'b00, mant2} :
                                  divisor_reg   ;

always @(posedge clk)
if (rst)
    partial_remainder_reg <= {(MANT_W + 2){1'b0}};
else
    partial_remainder_reg <= ~busy &  run        ? {(MANT_W + 2){1'b0}}    :
                              busy & ~finish_reg ?  partial_remainder_next :
                                                    partial_remainder_reg  ;

endmodule