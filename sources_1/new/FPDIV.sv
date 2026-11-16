import st_pkg::*;

module FPDIV #(
    parameter IS_DOUBLE = 1,
 
    localparam DATA_W  = IS_DOUBLE ? 64   : 32 ,
    localparam MANT_W  = IS_DOUBLE ? 53   : 24 ,
    localparam EXP_W   = IS_DOUBLE ? 11   : 8  ,
    localparam BIAS    = IS_DOUBLE ? 1023 : 127,
    localparam FRAC_W  = IS_DOUBLE ? 55   : 26 ,
    localparam QUOT_W  = MANT_W + FRAC_W,
    localparam LZC_W   = $clog2(MANT_W + 1),
    localparam ROUND_W = 2*MANT_W,
    localparam ALIGN_W = ROUND_W - FRAC_W - 1
)(
    input      operand_type      operand1_s0,
    input      operand_type      operand2_s0,
    input                        clk,
    input      round_mode_type   round_mode,
    input                        run,
    input                        rst,
    output reg                   val,
    output reg                   busy,
    output reg [DATA_W - 1:0]    result,
    output     fp_exception_type exceptions
);

round_mode_type    round_mode_s1;
round_mode_type    round_mode_s2;
round_mode_type    round_mode_s2a;
round_mode_type    round_mode_s2b;
round_mode_type    round_mode_s3;

fp_exception_type  exceptions_s0;
fp_exception_type  exceptions_s1;
fp_exception_type  exceptions_s2;
fp_exception_type  exceptions_s2a;
fp_exception_type  exceptions_s2b;
fp_exception_type  exceptions_s3;
fp_exception_type  ready_exceptions_s3;

wire                sign_res_s0;
wire [EXP_W  + 1:0] exp_sub_s0;
wire [DATA_W - 1:0] early_result_s0;
wire                early_result_mx_s0;
wire [LZC_W  - 1:0] leading_zero_dn_op1_s0;
wire [LZC_W  - 1:0] leading_zero_dn_op2_s0;

wire [MANT_W - 1:0] mant1_prepared_s1;
wire [MANT_W - 1:0] mant2_prepared_s1;
wire [EXP_W  + 1:0] exp_prepared_s1;
wire                integer_run_s1;
wire                integer_valid_s1;
wire [QUOT_W - 1:0] divided_mant_s1;
wire                div_by_zero_s1;
wire [MANT_W - 1:0] remainder_s1;

wire                finish_s1_start_s2;
wire                is_norm_s2;
wire [QUOT_W - 1:0] mant_norm_s2;
wire [EXP_W  + 1:0] exp_after_norm_s2;
wire                remainder_nonzero_s2;
wire                tiny_before_round_s2;
wire [ROUND_W -1:0] mant_aligned_s2;
wire [ROUND_W -1:0] mant_aligned_sticky_s2;
wire [EXP_W  + 1:0] dn_shift_s2;
wire [EXP_W  + 1:0] dn_lost_shift_s2;

wire [ROUND_W -1:0] mant_dn_raw_s2a;
wire                mant_dn_lost_s2a;
wire [ROUND_W -1:0] mant_to_round_s2a;

wire                round_inexact_s2b;
wire                adj_round_s2b;
wire [MANT_W - 1:0] mant_raw_s2b;
wire                mant_incr_s2b;

wire [MANT_W - 1:0] mant_round_s3;
wire [EXP_W  + 1:0] exp_after_round_s3;
wire                overflow_s3;
wire [EXP_W  - 1:0] exp_res_s3;
wire                overflow_to_inf_s3;
wire [DATA_W - 1:0] overflow_result_s3;
wire [DATA_W - 1:0] ready_result_s3;


reg  [MANT_W - 1:0] mant1_s1;
reg  [MANT_W - 1:0] mant2_s1;
reg                 run_reg_s1;
reg                 sign_res_s1;
reg  [EXP_W  + 1:0] exp_sub_s1;
reg  [DATA_W - 1:0] early_result_s1;
reg                 early_result_mx_s1;
reg  [LZC_W  - 1:0] leading_zero_dn_op1_s1;
reg  [LZC_W  - 1:0] leading_zero_dn_op2_s1;

reg  [EXP_W  + 1:0] exp_prepared_s2;
reg  [QUOT_W - 1:0] divided_mant_s2;
reg                 div_by_zero_s2;
reg  [MANT_W - 1:0] remainder_s2;
reg                 sign_res_s2;
reg  [DATA_W - 1:0] early_result_s2;
reg                 early_result_mx_s2;
reg                 run_reg_s2;

reg                 run_reg_s2a;
reg  [ROUND_W -1:0] mant_aligned_sticky_s2a;
reg  [EXP_W  + 1:0] dn_shift_s2a;
reg  [EXP_W  + 1:0] dn_lost_shift_s2a;
reg  [EXP_W  + 1:0] exp_after_norm_s2a;
reg                 tiny_before_round_s2a;
reg                 sign_res_s2a;
reg  [DATA_W - 1:0] early_result_s2a;
reg                 early_result_mx_s2a;

reg                 run_reg_s2b;
reg  [ROUND_W -1:0] mant_to_round_s2b;
reg                 tiny_before_round_s2b;
reg                 sign_res_s2b;
reg  [DATA_W - 1:0] early_result_s2b;
reg                 early_result_mx_s2b;
reg  [EXP_W  + 1:0] exp_after_norm_s2b;

reg                 run_reg_s3;
reg  [MANT_W - 1:0] mant_raw_s3;
reg                 adj_round_s3;
reg                 mant_incr_s3;
reg                 round_inexact_s3;
reg                 tiny_before_round_s3;
reg                 sign_res_s3;
reg  [DATA_W - 1:0] early_result_s3;
reg                 early_result_mx_s3;
reg  [EXP_W  + 1:0] exp_after_norm_s3;

always @(posedge clk)
if (rst)
    busy <= 1'b0;
else
    busy <= run & ~busy ? 1'b1 :
            run_reg_s3  ? 1'b0 :
                          busy ;

// Стадия s0

div_early_res #(
    .IS_DOUBLE(IS_DOUBLE)
) div_early_res (
    .operand1       (operand1_s0),
    .operand2       (operand2_s0), 
    .early_result   (early_result_s0),
    .exceptions     (exceptions_s0),
    .early_result_mx(early_result_mx_s0)
);

lz_count #(
    .IS_DOUBLE(IS_DOUBLE)
) lz_count_op1 (
    .subnormal_mant (operand1_s0.mant),
    .leading_zero_dn(leading_zero_dn_op1_s0)
);

lz_count #(
    .IS_DOUBLE(IS_DOUBLE)
) lz_count_op2 (
    .subnormal_mant (operand2_s0.mant),
    .leading_zero_dn(leading_zero_dn_op2_s0)
);

assign sign_res_s0 = operand1_s0.sign ^ operand2_s0.sign;
assign  exp_sub_s0 = operand1_s0.exp  -  operand2_s0.exp + BIAS;

always @(posedge clk)
if (run & ~busy & ~rst)
begin
    exceptions_s1          <= exceptions_s0;
    sign_res_s1            <= sign_res_s0;
    exp_sub_s1             <= exp_sub_s0;            
    early_result_s1        <= early_result_s0;       
    early_result_mx_s1     <= early_result_mx_s0;    
    leading_zero_dn_op1_s1 <= leading_zero_dn_op1_s0;
    leading_zero_dn_op2_s1 <= leading_zero_dn_op2_s0;
    round_mode_s1          <= round_mode;
    mant1_s1               <= operand1_s0.mant;
    mant2_s1               <= operand2_s0.mant;
end

// Стадия s1

assign mant1_prepared_s1 = mant1_s1 << leading_zero_dn_op1_s1;
assign mant2_prepared_s1 = mant2_s1 << leading_zero_dn_op2_s1;

assign exp_prepared_s1   = exp_sub_s1 - leading_zero_dn_op1_s1 + leading_zero_dn_op2_s1;

always @(posedge clk)
if (rst)
    run_reg_s1 <= 1'b0;
else
    run_reg_s1 <= run & ~busy;
    
assign integer_run_s1 = run_reg_s1 & ~early_result_mx_s1;

integer_divider #(
    .IS_DOUBLE(IS_DOUBLE)
) int_div (
    .mant1       (mant1_prepared_s1),
    .mant2       (mant2_prepared_s1),
    .clk         (clk),         
    .rst         (rst),         
    .run         (integer_run_s1),
    .val         (integer_valid_s1),         
    .divided_mant(divided_mant_s1),
    .remainder   (remainder_s1),   
    .div_by_zero (div_by_zero_s1)
);

assign finish_s1_start_s2 = (run_reg_s1 & early_result_mx_s1) | integer_valid_s1;

always @(posedge clk)
if (busy & finish_s1_start_s2 & ~rst)
begin
    exp_prepared_s2    <= exp_prepared_s1;
    divided_mant_s2    <= divided_mant_s1;  
    div_by_zero_s2     <= div_by_zero_s1;
    remainder_s2       <= remainder_s1;
    round_mode_s2      <= round_mode_s1;
    exceptions_s2      <= exceptions_s1;
    sign_res_s2        <= sign_res_s1;
    early_result_s2    <= early_result_s1;       
    early_result_mx_s2 <= early_result_mx_s1;
end
    
// Стадия s2

always @(posedge clk)
if (rst)
    run_reg_s2 <= 1'b0;
else
    run_reg_s2 <= busy & finish_s1_start_s2;
    
assign is_norm_s2 = divided_mant_s2[FRAC_W]; //если is_norm_s2 == 1, то мантисса нормализована

assign mant_norm_s2 = is_norm_s2 ? divided_mant_s2      :
                                   divided_mant_s2 << 1 ;

assign exp_after_norm_s2 = exp_prepared_s2 - (!is_norm_s2);

assign remainder_nonzero_s2 = |remainder_s2;

assign mant_aligned_s2        = {mant_norm_s2[FRAC_W : 0], {ALIGN_W{1'b0}}};
assign mant_aligned_sticky_s2 = {mant_aligned_s2[ROUND_W - 1:1], remainder_nonzero_s2};

assign tiny_before_round_s2 = ~early_result_mx_s2                                    & 
                              (exp_after_norm_s2[EXP_W + 1] | (~|exp_after_norm_s2)) ;
                      
assign dn_shift_s2 = tiny_before_round_s2 ? 1'b1 - exp_after_norm_s2 :
                                            {(EXP_W + 2){1'b0}}      ;

assign dn_lost_shift_s2 = dn_shift_s2 < ROUND_W ? ROUND_W - dn_shift_s2 :
                                                  {(EXP_W + 2){1'b0}}   ;

always @(posedge clk)
if (run_reg_s2 & ~rst)
begin
    mant_aligned_sticky_s2a <= mant_aligned_sticky_s2;
    dn_shift_s2a            <= dn_shift_s2;
    dn_lost_shift_s2a       <= dn_lost_shift_s2;
    exp_after_norm_s2a      <= early_result_mx_s2 ? {(EXP_W + 2){1'b0}} :
                                                     exp_after_norm_s2  ;
    tiny_before_round_s2a   <= tiny_before_round_s2;
    round_mode_s2a          <= round_mode_s2;
    sign_res_s2a            <= sign_res_s2;
    early_result_s2a        <= early_result_s2;
    early_result_mx_s2a     <= early_result_mx_s2;
    exceptions_s2a          <= exceptions_s2;
end

// Стадия s2a

always @(posedge clk)
if (rst)
    run_reg_s2a <= 1'b0;
else
    run_reg_s2a <= run_reg_s2;

assign mant_dn_raw_s2a = dn_shift_s2a < ROUND_W ? mant_aligned_sticky_s2a >> dn_shift_s2a :
                                                  {ROUND_W{1'b0}}                         ;

assign mant_dn_lost_s2a = dn_shift_s2a == 0      ? 1'b0                                            :
                          dn_shift_s2a < ROUND_W ? |(mant_aligned_sticky_s2a << dn_lost_shift_s2a) :
                                                    |mant_aligned_sticky_s2a                       ;

assign mant_to_round_s2a = early_result_mx_s2a ? {ROUND_W{1'b0}}                                                         :
                                                 {mant_dn_raw_s2a[ROUND_W - 1:1], mant_dn_raw_s2a[0] | mant_dn_lost_s2a} ;

always @(posedge clk)
if (run_reg_s2a & ~rst)
begin
    mant_to_round_s2b     <= mant_to_round_s2a;
    exp_after_norm_s2b    <= exp_after_norm_s2a;
    tiny_before_round_s2b <= tiny_before_round_s2a;
    round_mode_s2b        <= round_mode_s2a;
    sign_res_s2b          <= sign_res_s2a;
    early_result_s2b      <= early_result_s2a;
    early_result_mx_s2b   <= early_result_mx_s2a;
    exceptions_s2b        <= exceptions_s2a;
end

// Стадия s2b
always @(posedge clk)
if (rst)
    run_reg_s2b <= 1'b0;
else
    run_reg_s2b <= run_reg_s2a;

assign round_inexact_s2b = |mant_to_round_s2b[MANT_W - 1:0];

round #(
    .IS_DOUBLE(IS_DOUBLE)
) round (
    .mant_norm     (mant_to_round_s2b),
    .round_mode    (round_mode_s2b),
    .sign          (sign_res_s2b),
    .adj_round     (adj_round_s2b),
    .mant_raw      (mant_raw_s2b),
    .mant_increment(mant_incr_s2b)
);

always @(posedge clk)
if (run_reg_s2b & ~rst)
begin
    mant_raw_s3          <= mant_raw_s2b;
    mant_incr_s3         <= mant_incr_s2b;
    adj_round_s3         <= adj_round_s2b;
    round_inexact_s3     <= round_inexact_s2b;
    tiny_before_round_s3 <= tiny_before_round_s2b;
    round_mode_s3        <= round_mode_s2b;
    exceptions_s3        <= exceptions_s2b;
    sign_res_s3          <= sign_res_s2b;
    early_result_s3      <= early_result_s2b;       
    early_result_mx_s3   <= early_result_mx_s2b;
    exp_after_norm_s3    <= exp_after_norm_s2b;
end
    
// Стадия s3
always @(posedge clk)
if (rst)
    run_reg_s3 <= 1'b0;
else
    run_reg_s3 <= run_reg_s2b;

assign mant_round_s3 = adj_round_s3 ? {1'b1, {(MANT_W - 1){1'b0}}} :
                                      mant_raw_s3 + mant_incr_s3   ;

assign exp_after_round_s3 = exp_after_norm_s3 + adj_round_s3;

assign overflow_s3 = ~early_result_mx_s3                        & 
                     ~exp_after_round_s3[EXP_W + 1]             &
                     (exp_after_round_s3 >= ((1 << EXP_W) - 1)) ;
                     
assign overflow_to_inf_s3 = (round_mode_s3 == NRST)                |
                            (round_mode_s3 == INFP) & ~sign_res_s3 |
                            (round_mode_s3 == INFN) &  sign_res_s3 ;
                            
assign overflow_result_s3 = overflow_to_inf_s3 ? {sign_res_s3, {EXP_W{1'b1}},           {MANT_W - 1{1'b0}}} :
                                                 {sign_res_s3, {EXP_W - 1{1'b1}}, 1'b0, {MANT_W - 1{1'b1}}} ;

                   
assign exp_res_s3 = tiny_before_round_s3 ? {{(EXP_W - 1){1'b0}}, mant_round_s3[MANT_W - 1]} :
                                           exp_after_round_s3[EXP_W - 1:0]                  ;

assign ready_result_s3 = early_result_mx_s3 ? early_result_s3                                        :
                         overflow_s3        ? overflow_result_s3                                     :
                                              {sign_res_s3, exp_res_s3, mant_round_s3[MANT_W - 2:0]} ;

assign ready_exceptions_s3.nv = exceptions_s3.nv ;
assign ready_exceptions_s3.dz = exceptions_s3.dz ;
assign ready_exceptions_s3.of = early_result_mx_s3 ? exceptions_s3.of :
                                                     overflow_s3      ;
assign ready_exceptions_s3.nx = early_result_mx_s3 ? exceptions_s3.nx               :
                                                     overflow_s3 | round_inexact_s3 ;
assign ready_exceptions_s3.uf = early_result_mx_s3 ? exceptions_s3.uf                        :
                                                     round_inexact_s3 & tiny_before_round_s3 ;

always @(posedge clk)
if (rst)
begin
    result     <= {DATA_W{1'b0}};
    exceptions <= '0;
end else begin
    result     <= ready_result_s3;
    exceptions <= ready_exceptions_s3;
end

always @(posedge clk)
if (rst)
    val <= 1'b0;
else
    val <= run_reg_s3;

endmodule
