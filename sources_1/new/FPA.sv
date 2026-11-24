import st_pkg::*;

module FPA #(
    parameter IS_DOUBLE = 1,

    localparam DATA_W     = IS_DOUBLE ? 64   : 32 ,
    localparam MANT_W     = IS_DOUBLE ? 53   : 24 ,
    localparam EXP_W      = IS_DOUBLE ? 11   : 8  ,
    localparam BIAS       = IS_DOUBLE ? 1023 : 127,
    localparam MANT_EXT_W = MANT_W + 4,
    localparam LZC_W      = $clog2(MANT_EXT_W),
    localparam ROUND_W    = 2*MANT_W
)(
    input      operand_type      operand1_s0,
    input      operand_type      operand2_s0,
    input                        clk,
    input      round_mode_type   round_mode,
    input                        sub,
    input                        run,
    input                        rst,
    output reg                   val,
    output reg [DATA_W - 1:0]    result,
    output     fp_exception_type exceptions
);

operand_type            operand1_s1;
operand_type            operand2_s1;


round_mode_type         round_mode_s1;
round_mode_type         round_mode_s2;
round_mode_type         round_mode_s3;
round_mode_type         round_mode_s4;
round_mode_type         round_mode_s5;
round_mode_type         round_mode_s6;
round_mode_type         round_mode_s7;


fp_exception_type       exceptions_s0;
fp_exception_type       exceptions_s1;
fp_exception_type       exceptions_s2;
fp_exception_type       exceptions_s3;
fp_exception_type       exceptions_s4;
fp_exception_type       exceptions_s5;
fp_exception_type       exceptions_s6;
fp_exception_type       exceptions_s7;
fp_exception_type       wire_round_exceptions_s7;


wire [DATA_W     - 1:0] early_result_s0;
wire                    early_result_mx_s0;
wire                    s2_eff_sign_s0;
wire                    sub_mags_s0;
wire                    op1_ge_op2_s0;

wire [EXP_W      - 1:0] exp_big_s1;
wire [EXP_W      - 1:0] exp_small_s1;
wire [MANT_W     - 1:0] mant_big_s1;
wire [MANT_W     - 1:0] mant_small_s1;
wire                    sign_big_s1;

wire [EXP_W      - 1:0] lost_shift_s2;
wire [MANT_EXT_W - 1:0] mant_small_raw_s2;
wire                    mant_small_lost_s2;
wire [MANT_EXT_W - 1:0] mant_small_aligned_s2;

wire [MANT_EXT_W - 1:0] mant_small_addsub_s3;
wire [MANT_EXT_W - 1:0] mant_addsub_s3;

wire                    norm_right_s4;
wire                    zero_res_s4;
wire [LZC_W      - 1:0] leading_zero_s4;
wire [EXP_W      - 1:0] max_left_shift_s4;
wire [LZC_W      - 1:0] norm_left_shift_s4;

wire [MANT_EXT_W - 2:0] mant_norm_s5;
wire [EXP_W      - 1:0] exp_after_norm_s5;
wire                    tiny_before_round_s5;
wire [ROUND_W    - 1:0] mant_to_round_s5;

wire [MANT_W     - 1:0] mant_raw_s6;
wire                    mant_incr_s6;
wire                    adj_round_s6;
wire                    round_inexact_s6;

wire [MANT_W     - 1:0] mant_round_s7;
wire [EXP_W         :0] exp_after_round_s7;
wire                    overflow_s7;
wire                    overflow_to_inf_s7;
wire [DATA_W     - 1:0] overflow_result_s7;
wire [EXP_W      - 1:0] exp_res_s7;
wire [DATA_W     - 1:0] ready_result_s7;


reg  [DATA_W     - 1:0] early_result_s1;
reg                     early_result_mx_s1;
reg                     s2_eff_sign_s1;
reg                     sub_mags_s1;
reg                     op1_ge_op2_s1;
reg                     run_reg_s1;

reg  [EXP_W      - 1:0] exp_base_s2;
reg  [EXP_W      - 1:0] exp_diff_s2;
reg  [MANT_EXT_W - 1:0] mant_big_s2;
reg  [MANT_EXT_W - 1:0] mant_small_s2;
reg                     sign_big_s2;
reg                     sub_mags_s2;
reg  [DATA_W     - 1:0] early_result_s2;
reg                     early_result_mx_s2;
reg                     run_reg_s2;

reg  [DATA_W     - 1:0] early_result_s3;
reg                     early_result_mx_s3;
reg                     run_reg_s3;
reg  [EXP_W      - 1:0] exp_base_s3;
reg  [MANT_EXT_W - 1:0] mant_big_s3;
reg  [MANT_EXT_W - 1:0] mant_small_aligned_s3;
reg                     sign_big_s3;
reg                     sub_mags_s3;

reg  [EXP_W      - 1:0] exp_base_s4;
reg  [MANT_EXT_W - 1:0] mant_addsub_s4;
reg                     sign_big_s4;
reg  [DATA_W     - 1:0] early_result_s4;
reg                     early_result_mx_s4;
reg                     run_reg_s4;

reg  [EXP_W      - 1:0] exp_base_s5;
reg  [MANT_EXT_W - 1:0] mant_addsub_s5;
reg  [LZC_W      - 1:0] norm_left_shift_s5;
reg                     norm_right_s5;
reg                     zero_res_s5;
reg                     sign_res_s5;
reg  [DATA_W     - 1:0] early_result_s5;
reg                     early_result_mx_s5;
reg                     run_reg_s5;

reg  [ROUND_W    - 1:0] mant_to_round_s6;
reg  [EXP_W      - 1:0] exp_after_norm_s6;
reg                     tiny_before_round_s6;
reg                     sign_res_s6;

reg  [DATA_W     - 1:0] early_result_s6;
reg                     early_result_mx_s6;
reg                     run_reg_s6;

reg  [MANT_W     - 1:0] mant_raw_s7;
reg                     mant_incr_s7;
reg                     adj_round_s7;
reg                     round_inexact_s7;

reg  [EXP_W      - 1:0] exp_after_norm_s7;
reg                     tiny_before_round_s7;
reg                     sign_res_s7;

reg  [DATA_W     - 1:0] early_result_s7;
reg                     early_result_mx_s7;
reg                     run_reg_s7;

// Стадия s0
always @(posedge clk)
if (rst)
    run_reg_s1 <= 1'b0;
else
    run_reg_s1 <= run ;

add_early_res #(
    .IS_DOUBLE(IS_DOUBLE)
) add_early_res (
    .operand1       (operand1_s0),
    .operand2       (operand2_s0),
    .sub            (sub),
    .round_mode     (round_mode),
    .early_result   (early_result_s0),
    .exceptions     (exceptions_s0),
    .early_result_mx(early_result_mx_s0)
);

assign s2_eff_sign_s0 = operand2_s0.sign ^ sub            ;
assign sub_mags_s0    = operand1_s0.sign ^ s2_eff_sign_s0 ;

assign op1_ge_op2_s0  = {operand1_s0.exp, operand1_s0.mant} >= 
                        {operand2_s0.exp, operand2_s0.mant}  ;

always @(posedge clk)
if (run & ~rst)
begin
    s2_eff_sign_s1     <= s2_eff_sign_s0     ;
    sub_mags_s1        <= sub_mags_s0        ;
    op1_ge_op2_s1      <= op1_ge_op2_s0      ;
    operand1_s1        <= operand1_s0        ;
    operand2_s1        <= operand2_s0        ;
    
    early_result_s1    <= early_result_s0    ;
    early_result_mx_s1 <= early_result_mx_s0 ;
    
    round_mode_s1      <= round_mode         ;
    exceptions_s1      <= exceptions_s0      ;
end

// Стадия s1
always @(posedge clk)
if (rst)
    run_reg_s2 <= 1'b0;
else
    run_reg_s2 <= run_reg_s1 ;

assign exp_big_s1    = op1_ge_op2_s1 ? operand1_s1.exp  :
                                       operand2_s1.exp  ;
                                    
assign exp_small_s1  = op1_ge_op2_s1 ? operand2_s1.exp  :
                                       operand1_s1.exp  ;

assign mant_big_s1   = op1_ge_op2_s1 ? operand1_s1.mant :
                                       operand2_s1.mant ;
                         
assign mant_small_s1 = op1_ge_op2_s1 ? operand2_s1.mant :
                                       operand1_s1.mant ;
                                       
assign sign_big_s1   = op1_ge_op2_s1 ? operand1_s1.sign :
                                       s2_eff_sign_s1   ;

always @(posedge clk)
if (run_reg_s1 & ~rst)
begin
    exp_base_s2        <=  exp_big_s1                   ;
    exp_diff_s2        <=  exp_big_s1 - exp_small_s1    ;
    mant_big_s2        <= {1'b0, mant_big_s1  , 3'b000} ;
    mant_small_s2      <= {1'b0, mant_small_s1, 3'b000} ;
    sign_big_s2        <= sign_big_s1                   ;
    sub_mags_s2        <= sub_mags_s1                   ;
    
    early_result_s2    <= early_result_s1               ;
    early_result_mx_s2 <= early_result_mx_s1            ;
    
    round_mode_s2      <= round_mode_s1                 ;
    exceptions_s2      <= exceptions_s1                 ;
end

// Стадия s2
always @(posedge clk)
if (rst)
    run_reg_s3 <= 1'b0;
else
    run_reg_s3 <= run_reg_s2 ;
    
assign mant_small_raw_s2     = exp_diff_s2 < MANT_EXT_W ? mant_small_s2 >> exp_diff_s2 :
                                                          {MANT_EXT_W{1'b0}}           ;
                                                      
assign lost_shift_s2         = exp_diff_s2 < MANT_EXT_W ? MANT_EXT_W - exp_diff_s2 :
                                                          {EXP_W{1'b0}}            ;
                                                      
assign mant_small_lost_s2    = exp_diff_s2 == 0         ? 1'b0                              :
                               exp_diff_s2 < MANT_EXT_W ? |(mant_small_s2 << lost_shift_s2) :
                                                          |mant_small_s2                    ;

assign mant_small_aligned_s2 = {mant_small_raw_s2[MANT_EXT_W - 1:1], 
                                mant_small_raw_s2[0] | mant_small_lost_s2};

always @(posedge clk)
if (run_reg_s2 & ~rst)
begin
    exp_base_s3           <= exp_base_s2           ;
    mant_big_s3           <= mant_big_s2           ;
    mant_small_aligned_s3 <= mant_small_aligned_s2 ;
    sign_big_s3           <= sign_big_s2           ;
    sub_mags_s3           <= sub_mags_s2           ;
    
    early_result_s3       <= early_result_s2       ;
    early_result_mx_s3    <= early_result_mx_s2    ;
    
    round_mode_s3         <= round_mode_s2         ;
    exceptions_s3         <= exceptions_s2         ;
end

// Стадия s3
always @(posedge clk)
if (rst)
    run_reg_s4 <= 1'b0;
else
    run_reg_s4 <= run_reg_s3 ;

assign mant_small_addsub_s3 = mant_small_aligned_s3 ^ {MANT_EXT_W{sub_mags_s3}};

assign mant_addsub_s3       = mant_big_s3 + mant_small_addsub_s3      + 
                              {{(MANT_EXT_W - 1){1'b0}}, sub_mags_s3} ;

always @(posedge clk)
if (run_reg_s3 & ~rst)
begin
    exp_base_s4        <= exp_base_s3        ;
    mant_addsub_s4     <= mant_addsub_s3     ;
    sign_big_s4        <= sign_big_s3        ;

    early_result_s4    <= early_result_s3    ;
    early_result_mx_s4 <= early_result_mx_s3 ;

    round_mode_s4      <= round_mode_s3      ;
    exceptions_s4      <= exceptions_s3      ;
end

// Стадия s4
always @(posedge clk)
if (rst)
    run_reg_s5 <= 1'b0;
else
    run_reg_s5 <= run_reg_s4 ;
    

assign norm_right_s4 =   mant_addsub_s4[MANT_EXT_W - 1];
assign zero_res_s4   = ~|mant_addsub_s4;


lz_count #(
    .IS_DOUBLE(IS_DOUBLE),
    .MANT_W   (MANT_EXT_W - 1)
) add_lz_count (
    .subnormal_mant (mant_addsub_s4[MANT_EXT_W - 2:0]),
    .leading_zero_dn(leading_zero_s4)
);

assign max_left_shift_s4  = exp_base_s4 == 0 ? {EXP_W{1'b0}}       :
                                                exp_base_s4 - 1'b1 ;

assign norm_left_shift_s4 = (norm_right_s4 | zero_res_s4)       ? {LZC_W{1'b0}}                  :
                            leading_zero_s4 > max_left_shift_s4 ? max_left_shift_s4[LZC_W - 1:0] :
                                                                  leading_zero_s4                ;

always @(posedge clk)
if (run_reg_s4 & ~rst)
begin
    exp_base_s5        <= exp_base_s4                           ;
    mant_addsub_s5     <= mant_addsub_s4                        ;
    norm_left_shift_s5 <= norm_left_shift_s4                    ;
    norm_right_s5      <= norm_right_s4                         ;
    zero_res_s5        <= zero_res_s4                           ;
    sign_res_s5        <= zero_res_s4 ? (round_mode_s4 == INFN) :
                                        sign_big_s4             ;

    early_result_s5    <= early_result_s4                       ;
    early_result_mx_s5 <= early_result_mx_s4                    ;

    round_mode_s5      <= round_mode_s4                         ;
    exceptions_s5      <= exceptions_s4                         ;
end

// Стадия s5
always @(posedge clk)
if (rst)
    run_reg_s6 <= 1'b0;
else
    run_reg_s6 <= run_reg_s5 ;

assign mant_norm_s5 = norm_right_s5 ? {mant_addsub_s5[MANT_EXT_W - 1:2], mant_addsub_s5[1] | mant_addsub_s5[0]} :
                                       mant_addsub_s5[MANT_EXT_W - 2:0] << norm_left_shift_s5                   ;
                                       
assign exp_after_norm_s5 = zero_res_s5   ? {EXP_W{1'b0}}                    :
                           norm_right_s5 ? exp_base_s5 + 1'b1               :
                                           exp_base_s5 - norm_left_shift_s5 ;

assign tiny_before_round_s5 = (exp_after_norm_s5 == 1'b1) & ~mant_norm_s5[MANT_EXT_W - 2];

assign mant_to_round_s5     = {mant_norm_s5, {(MANT_W - 3){1'b0}}};

always @(posedge clk)
if (run_reg_s5 & ~rst)
begin
    mant_to_round_s6      <= mant_to_round_s5     ;
    exp_after_norm_s6     <= exp_after_norm_s5    ;
    tiny_before_round_s6  <= tiny_before_round_s5 ;
    sign_res_s6           <= sign_res_s5          ;

    early_result_s6       <= early_result_s5      ;
    early_result_mx_s6    <= early_result_mx_s5   ;

    round_mode_s6         <= round_mode_s5        ;
    exceptions_s6         <= exceptions_s5        ;
end

// Стадия s6
always @(posedge clk)
if (rst)
    run_reg_s7 <= 1'b0;
else
    run_reg_s7 <= run_reg_s6 ;
    
assign round_inexact_s6 = |mant_to_round_s6[MANT_W - 1:0];

round #(
    .IS_DOUBLE(IS_DOUBLE)
) add_round (
    .mant_norm     (mant_to_round_s6),
    .round_mode    (round_mode_s6),
    .sign          (sign_res_s6),
    .adj_round     (adj_round_s6),
    .mant_raw      (mant_raw_s6),
    .mant_increment(mant_incr_s6)
);

always @(posedge clk)
if (run_reg_s6 & ~rst)
begin
    mant_raw_s7          <= mant_raw_s6          ;
    mant_incr_s7         <= mant_incr_s6         ;
    adj_round_s7         <= adj_round_s6         ;
    round_inexact_s7     <= round_inexact_s6     ;

    exp_after_norm_s7    <= exp_after_norm_s6    ;
    tiny_before_round_s7 <= tiny_before_round_s6 ;
    sign_res_s7          <= sign_res_s6          ;

    early_result_s7      <= early_result_s6      ;
    early_result_mx_s7   <= early_result_mx_s6   ;

    round_mode_s7        <= round_mode_s6        ;
    exceptions_s7        <= exceptions_s6        ;
end

// Стадия s7
always @(posedge clk)
if (rst)
    val <= 1'b0;
else
    val <= run_reg_s7 ;

assign mant_round_s7 = adj_round_s7 ? {1'b1, {(MANT_W - 1){1'b0}}} :
                                       mant_raw_s7 + mant_incr_s7  ;
                                       
assign exp_after_round_s7 = {1'b0, exp_after_norm_s7} + adj_round_s7 ;

assign overflow_s7 = ~early_result_mx_s7 & (exp_after_round_s7 >= {1'b0, {EXP_W{1'b1}}});

assign overflow_to_inf_s7 = (round_mode_s7 == NRST)                | 
                            (round_mode_s7 == INFP) & ~sign_res_s7 |
                            (round_mode_s7 == INFN) &  sign_res_s7 ;
                            
assign overflow_result_s7 = overflow_to_inf_s7 ? {sign_res_s7, {EXP_W      {1'b1}},       {(MANT_W - 1){1'b0}}} :
                                                 {sign_res_s7, {(EXP_W - 1){1'b1}}, 1'b0, {(MANT_W - 1){1'b1}}} ;
                                                 
assign exp_res_s7 = tiny_before_round_s7 ? {{(EXP_W - 1){1'b0}}, mant_round_s7[MANT_W - 1]} :
                                             exp_after_round_s7[EXP_W - 1:0]                ;
                                            
assign ready_result_s7 = early_result_mx_s7 ?  early_result_s7                                       :
                         overflow_s7        ?  overflow_result_s7                                    :
                                              {sign_res_s7, exp_res_s7, mant_round_s7[MANT_W - 2:0]} ;

assign wire_round_exceptions_s7.nv = 1'b0                           ;
assign wire_round_exceptions_s7.dz = 1'b0                           ;
assign wire_round_exceptions_s7.uf = 1'b0                           ;
assign wire_round_exceptions_s7.nx = overflow_s7 | round_inexact_s7 ;
assign wire_round_exceptions_s7.of = overflow_s7                    ;

always @(posedge clk)
if (rst) begin
    result     <= {DATA_W{1'b0}};
    exceptions <= '0;
end else if (run_reg_s7) begin
    result     <= ready_result_s7;
    exceptions <= early_result_mx_s7 ?            exceptions_s7 :
                                       wire_round_exceptions_s7 ;
end

endmodule
