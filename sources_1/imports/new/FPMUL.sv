import st_pkg::*;

module FPMUL #(
    parameter IS_DOUBLE = 1,

    localparam DATA_W = IS_DOUBLE ? 64   : 32 ,
    localparam MANT_W = IS_DOUBLE ? 53   : 24 ,
    localparam EXP_W  = IS_DOUBLE ? 11   : 8  ,
    localparam BIAS   = IS_DOUBLE ? 1023 : 127,
    localparam LZC_W  = $clog2(MANT_W + 1)
)(
    input      operand_type      operand1_s0,
    input      operand_type      operand2_s0,
    input                        clk,
    input      round_mode_type   round_mode,
    input                        run,
    output reg                   val,
    output reg [DATA_W - 1:0]    result,
    output     fp_exception_type exceptions
);

round_mode_type       round_mode_s0a;
round_mode_type       round_mode_s0b;
round_mode_type       round_mode_s1;
round_mode_type       round_mode_s1a;
round_mode_type       round_mode_s2;
round_mode_type       round_mode_s3;

fp_exception_type     early_exceptions_s0;
fp_exception_type     early_exceptions_s0a;
fp_exception_type     early_exceptions_s0b;
fp_exception_type     early_exceptions_s1;
fp_exception_type     early_exceptions_s1a;
fp_exception_type     early_exceptions_s2;
fp_exception_type     exceptions_s2;
fp_exception_type     exceptions_s3;

wire [DATA_W - 1:0]   early_result_s0;
wire [DATA_W - 1:0]   early_result_raw_s0;
wire                  outward_s0;
wire                  early_result_mult_s0;

wire                  snan1_s0;
wire                  snan2_s0;
wire                  invalid_s0;
wire                  two_subnormal_s0;

wire [MANT_W - 1:0]   subnormal_mant_s0;
wire [LZC_W  - 1:0]   leading_zero_dn_s0;

wire                  sign_res_s0;
wire [EXP_W + 1:0]    exp_summ_s0;

wire [2*MANT_W - 1:0] mant_mult_s0b;

wire [2*MANT_W - 1:0] mant_transp_s1;
wire [EXP_W - 1:0]    dn_shift_s1;

wire                  adj_norm_s1;

wire [EXP_W - 1:0]    nf_shift_s1;

wire                  uflow_dn_s1;
wire                  lz_more_exp_s1;
wire                  nfn_case_s1;

wire                  subnorm_res_mult_s1;
wire [LZC_W : 0]      norm_shift_s1;

wire [2*MANT_W - 1:0] mant_dn_s1a;
wire [2*MANT_W - 1:0] mant_dn_raw_s1a;
wire                  mant_dn_lost_s1a;
wire [2*MANT_W - 1:0] mant_norm_s1a;
wire [2*MANT_W - 1:0] mant_nfn_s1a;
wire [2*MANT_W - 1:0] mant_to_round_s1a;

wire                  oflow_res_mult_s2;
wire                  norm_res_mult_s2;

wire                  adj_round_s2;
wire [EXP_W - 1:0]    exp_res_s2;

wire [MANT_W - 1:0]   mant_raw_s2;
wire                  mant_incr_s2;

wire                  exp_summ_uflow_s2;
wire                  exp_summ_oflow_s2;
wire                  round_inexact_s2;
wire [EXP_W + 1:0]    exp_before_round_s2;
wire                  tiny_before_round_s2;

wire [MANT_W - 1:0]   mant_round_s3;
wire                  subnormal_promoted_s3;
wire                  overflow_to_inf_s3;
wire [DATA_W - 1:0]   overflow_result_s3;

reg                   run_reg_s0a;
reg  [DATA_W - 1:0]   early_result_s0a;
reg  [EXP_W + 1:0]    exp_summ_s0a;
reg                   sign_res_s0a;
reg  [LZC_W - 1:0]    leading_zero_dn_s0a;
reg                   early_result_mult_s0a;

reg                   run_reg_s0b;
reg  [DATA_W - 1:0]   early_result_s0b;
reg                   early_result_mult_s0b;
reg  [LZC_W - 1:0]    leading_zero_dn_s0b;
reg                   sign_res_s0b;
reg  [EXP_W + 1:0]    exp_summ_s0b;

reg                   sign_res_s1;

reg  [DATA_W - 1:0]   early_result_s1;
reg                   early_result_mult_s1;

reg  [LZC_W - 1:0]    leading_zero_dn_s1;

reg  [EXP_W + 1:0]    exp_summ_s1;
reg  [2*MANT_W - 1:0] mant_mult_s1;
reg                   run_reg_s1;

reg                   run_reg_s1a;

reg  [2*MANT_W - 1:0] mant_mult_s1a;
reg  [LZC_W:0]        norm_shift_s1a;
reg  [EXP_W - 1:0]    dn_shift_s1a;
reg  [EXP_W - 1:0]    nf_shift_s1a;

reg                   adj_norm_s1a;
reg                   uflow_dn_s1a;
reg                   nfn_case_s1a;
reg                   subnorm_res_mult_s1a;

reg  [DATA_W - 1:0]   early_result_s1a;
reg                   early_result_mult_s1a;

reg  [LZC_W - 1:0]    leading_zero_dn_s1a;
reg                   sign_res_s1a;
reg  [EXP_W + 1:0]    exp_summ_s1a;

reg                   early_result_mult_s2;
reg  [DATA_W - 1:0]   early_result_s2;

reg                   subnorm_res_mult_s2;
reg                   sign_res_s2;

reg                   adj_norm_s2;

reg  [LZC_W - 1:0]    leading_zero_dn_s2;
reg  [EXP_W + 1:0]    exp_summ_s2;

reg  [2*MANT_W - 1:0] mant_to_round_s2;
reg                   run_reg_s2;

reg [MANT_W - 1:0]    mant_raw_s3;
reg                   mant_incr_s3;
reg                   adj_round_s3;

reg [EXP_W - 1:0]     exp_res_s3;
reg                   sign_res_s3;

reg                   oflow_res_mult_s3;
reg                   norm_res_mult_s3;
reg                   subnorm_res_mult_s3;

reg [DATA_W - 1:0]    early_result_s3;
reg                   early_result_mult_s3;

reg                   run_reg_s3;

// Переключение стадий
always @(posedge clk)
begin
    run_reg_s0a <= run; // run == run_s0
    run_reg_s0b <= run_reg_s0a;
    run_reg_s1  <= run_reg_s0b;
    run_reg_s1a <= run_reg_s1;
    run_reg_s2  <= run_reg_s1a;
    run_reg_s3  <= run_reg_s2;
    val         <= run_reg_s3;
end

// Стадия s0
early_res #(
    .IS_DOUBLE(IS_DOUBLE)
) early_res (
    .operand1    (operand1_s0),
    .operand2    (operand2_s0),
    .early_result(early_result_raw_s0)
);

lz_count #(
    .IS_DOUBLE(IS_DOUBLE)
) lz_count (
    .subnormal_mant (subnormal_mant_s0),
    .leading_zero_dn(leading_zero_dn_s0)
);

integer_multiplier #(
    .IS_DOUBLE(IS_DOUBLE)
) mant_mul (
    .x     (operand1_s0.mant),
    .y     (operand2_s0.mant),
    .result(mant_mult_s0b),
    .clk   (clk)
);

assign early_result_mult_s0 = operand1_s0.flags.nan       | operand2_s0.flags.nan      |
                              operand1_s0.flags.zero      | operand2_s0.flags.zero     |           
                              operand1_s0.flags.inf       | operand2_s0.flags.inf      |          
                              operand1_s0.flags.subnormal & operand2_s0.flags.subnormal;
                              
assign snan1_s0 = operand1_s0.flags.nan & ~operand1_s0.mant[MANT_W - 2];
assign snan2_s0 = operand2_s0.flags.nan & ~operand2_s0.mant[MANT_W - 2];

assign invalid_s0 = snan1_s0 | snan2_s0 |
                    operand1_s0.flags.zero & operand2_s0.flags.inf |
                    operand2_s0.flags.zero & operand1_s0.flags.inf;

assign two_subnormal_s0 = operand1_s0.flags.subnormal & operand2_s0.flags.subnormal;

assign outward_s0 = (round_mode == INFP) & ~sign_res_s0 |
                    (round_mode == INFN) &  sign_res_s0;

assign early_result_s0 = two_subnormal_s0 ? {sign_res_s0, {EXP_W{1'b0}}, {MANT_W - 2{1'b0}}, outward_s0} :
                                           early_result_raw_s0;

assign early_exceptions_s0.nv = invalid_s0;
assign early_exceptions_s0.dz = 1'b0;
assign early_exceptions_s0.of = 1'b0;
assign early_exceptions_s0.uf = two_subnormal_s0;
assign early_exceptions_s0.nx = two_subnormal_s0;

assign subnormal_mant_s0 =  operand1_s0.flags.subnormal & ~operand2_s0.flags.subnormal ? operand1_s0.mant :
                           ~operand1_s0.flags.subnormal &  operand2_s0.flags.subnormal ? operand2_s0.mant :
                                                                                        {MANT_W{1'b1}}    ;
                                                               
assign sign_res_s0 = operand1_s0.sign ^ operand2_s0.sign;
assign exp_summ_s0 = operand1_s0.exp  + operand2_s0.exp  - BIAS;

// Регистры между стадиями s0 и s0a
always @(posedge clk)
if (run) begin
    early_exceptions_s0a  <= early_exceptions_s0;
    early_result_s0a      <= early_result_s0;
    early_result_mult_s0a <= early_result_mult_s0;
    round_mode_s0a        <= round_mode;
    leading_zero_dn_s0a   <= leading_zero_dn_s0;
    sign_res_s0a          <= sign_res_s0;
    exp_summ_s0a          <= exp_summ_s0;
end

// Регистры между стадиями s0a и s0b
always @(posedge clk)
if (run_reg_s0a) begin
    early_exceptions_s0b  <= early_exceptions_s0a;
    early_result_s0b      <= early_result_s0a;
    early_result_mult_s0b <= early_result_mult_s0a;
    round_mode_s0b        <= round_mode_s0a;
    leading_zero_dn_s0b   <= leading_zero_dn_s0a;
    sign_res_s0b          <= sign_res_s0a;
    exp_summ_s0b          <= exp_summ_s0a;
end

// Регистры между стадиями s0b и s1
always @(posedge clk)
if (run_reg_s0b) begin
    early_exceptions_s1   <= early_exceptions_s0b;
    early_result_s1      <= early_result_s0b;
    round_mode_s1        <= round_mode_s0b;
    early_result_mult_s1 <= early_result_mult_s0b;
    leading_zero_dn_s1   <= leading_zero_dn_s0b;
    sign_res_s1          <= sign_res_s0b;
    exp_summ_s1          <= exp_summ_s0b;
    mant_mult_s1         <= mant_mult_s0b;
end

// Стадия s1
genvar i;
generate
    for (i = 0; i < 2*MANT_W; i = i + 1) begin : gen_transp
        assign mant_transp_s1[i] = mant_mult_s1[2*MANT_W - 1 - i];
    end
endgenerate

assign adj_norm_s1   = mant_transp_s1[leading_zero_dn_s1];
assign norm_shift_s1 = {1'b0, leading_zero_dn_s1} + {{LZC_W{1'b0}}, !adj_norm_s1};

assign dn_shift_s1 = -(exp_summ_s1[EXP_W - 1:0]);

assign lz_more_exp_s1 = leading_zero_dn_s1 >= exp_summ_s1[EXP_W - 1:0];
assign uflow_dn_s1    = exp_summ_s1[EXP_W + 1] | (~|exp_summ_s1);
assign nfn_case_s1    = lz_more_exp_s1 & (|leading_zero_dn_s1);

assign nf_shift_s1 = exp_summ_s1[EXP_W - 1:0];
                                        
assign subnorm_res_mult_s1 = uflow_dn_s1 | lz_more_exp_s1 ;

// Регистры между стадиями s1 и s1a
always @(posedge clk)
if (run_reg_s1) begin
    early_exceptions_s1a  <= early_exceptions_s1;
    mant_mult_s1a         <= mant_mult_s1;
    norm_shift_s1a        <= norm_shift_s1;
    dn_shift_s1a          <= dn_shift_s1;
    nf_shift_s1a          <= nf_shift_s1;

    adj_norm_s1a          <= adj_norm_s1;
    uflow_dn_s1a          <= uflow_dn_s1;
    nfn_case_s1a          <= nfn_case_s1;
    subnorm_res_mult_s1a  <= subnorm_res_mult_s1;

    early_result_s1a      <= early_result_s1;
    early_result_mult_s1a <= early_result_mult_s1;
    round_mode_s1a        <= round_mode_s1;

    leading_zero_dn_s1a   <= leading_zero_dn_s1;
    sign_res_s1a          <= sign_res_s1;
    exp_summ_s1a          <= exp_summ_s1;
end

// Стадия s1a
assign mant_norm_s1a = mant_mult_s1a << norm_shift_s1a;

assign mant_dn_raw_s1a = (dn_shift_s1a <= 2*MANT_W) ? mant_mult_s1a >> dn_shift_s1a : 
                                                  {2*MANT_W{1'b0}}              ;

assign mant_dn_lost_s1a = (dn_shift_s1a == 0)       ? 1'b0                                          :
                          (dn_shift_s1a < 2*MANT_W) ? |(mant_mult_s1a << (2*MANT_W - dn_shift_s1a)) :
                                                      |mant_mult_s1a                                ;

assign mant_dn_s1a = mant_dn_raw_s1a | {{2*MANT_W - 1{1'b0}}, mant_dn_lost_s1a};

assign mant_nfn_s1a = (nf_shift_s1a <= 2*MANT_W) ? mant_mult_s1a << nf_shift_s1a :
                                                   {2*MANT_W{1'b0}}              ;

assign mant_to_round_s1a =  nfn_case_s1a ? mant_nfn_s1a     :   
                            uflow_dn_s1a ? mant_dn_s1a      :
                           ~uflow_dn_s1a ? mant_norm_s1a    :
                                           {2*MANT_W{1'b0}} ;

// Регистры между стадиями s1a и s2
always @(posedge clk)
if (run_reg_s1a) begin
    early_exceptions_s2  <= early_exceptions_s1a;
    early_result_s2      <= early_result_s1a;
    subnorm_res_mult_s2  <= subnorm_res_mult_s1a;
    sign_res_s2          <= sign_res_s1a;
    adj_norm_s2          <= adj_norm_s1a;
    exp_summ_s2          <= exp_summ_s1a;
    leading_zero_dn_s2   <= leading_zero_dn_s1a;
    mant_to_round_s2     <= mant_to_round_s1a;
    round_mode_s2        <= round_mode_s1a;
    early_result_mult_s2 <= early_result_mult_s1a;
end

// Стадия s2
round #(
    .IS_DOUBLE(IS_DOUBLE)
) round (
    .mant_norm     (mant_to_round_s2),
    .round_mode    (round_mode_s2),
    .sign          (sign_res_s2),
    .adj_round     (adj_round_s2),
    .mant_raw      (mant_raw_s2),
    .mant_increment(mant_incr_s2)
);

exp_corr #(
    .IS_DOUBLE(IS_DOUBLE)
) exp_corr (
    .exp_summ       (exp_summ_s2),
    .adj_round      (adj_round_s2),
    .adj_norm       (adj_norm_s2),
    .leading_zero_dn(leading_zero_dn_s2),
    .exp_res        (exp_res_s2),
    .exp_summ_uflow (exp_summ_uflow_s2),
    .exp_summ_oflow (exp_summ_oflow_s2)
);

assign oflow_res_mult_s2 =  exp_summ_oflow_s2;
assign norm_res_mult_s2  = ~exp_summ_uflow_s2; // Проверяем экспоненту после всех поправок на нормализацию и округление.
                                               // Если она больше нуля, разрешаем вывод нормального результата.
                                               // Переполнение обрабатывается отдельно, с более высоким приоритетом.

assign round_inexact_s2 = |mant_to_round_s2[MANT_W - 1:0];

assign exp_before_round_s2 = exp_summ_s2 + adj_norm_s2 - leading_zero_dn_s2;
assign tiny_before_round_s2 = exp_before_round_s2[EXP_W + 1] | (~|exp_before_round_s2);

assign exceptions_s2.nv =  early_exceptions_s2.nv;
assign exceptions_s2.dz =  early_exceptions_s2.dz;
assign exceptions_s2.of = ~early_result_mult_s2 ? oflow_res_mult_s2                        : early_exceptions_s2.of;
assign exceptions_s2.uf = ~early_result_mult_s2 ? tiny_before_round_s2 & round_inexact_s2  : early_exceptions_s2.uf;
assign exceptions_s2.nx = ~early_result_mult_s2 ? round_inexact_s2     | oflow_res_mult_s2 : early_exceptions_s2.nx;

// Регистры между стадиями s2 и s3
always @(posedge clk)
if (run_reg_s2) begin
    exceptions_s3        <= exceptions_s2;
    round_mode_s3        <= round_mode_s2;
    mant_raw_s3          <= mant_raw_s2;
    mant_incr_s3         <= mant_incr_s2;
    adj_round_s3         <= adj_round_s2;

    exp_res_s3           <= exp_res_s2;
    sign_res_s3          <= sign_res_s2;

    oflow_res_mult_s3    <= oflow_res_mult_s2;
    norm_res_mult_s3     <= norm_res_mult_s2;
    subnorm_res_mult_s3  <= subnorm_res_mult_s2;

    early_result_s3      <= early_result_s2;
    early_result_mult_s3 <= early_result_mult_s2;
end

// Стадия s3
assign mant_round_s3 = adj_round_s3 ? {1'b1, {MANT_W - 1{1'b0}}} : 
                                      mant_raw_s3 + mant_incr_s3 ;
assign subnormal_promoted_s3 = subnorm_res_mult_s3 & ~norm_res_mult_s3 & mant_round_s3[MANT_W - 1];

assign overflow_to_inf_s3 = (round_mode_s3 == NRST) |
                            (round_mode_s3 == INFP) & ~sign_res_s3 |
                            (round_mode_s3 == INFN) &  sign_res_s3;

assign overflow_result_s3 = overflow_to_inf_s3 ? {sign_res_s3, {EXP_W{1'b1}},           {MANT_W - 1{1'b0}}} :
                                                 {sign_res_s3, {EXP_W - 1{1'b1}}, 1'b0, {MANT_W - 1{1'b1}}} ;

always @(posedge clk)
if (run_reg_s3) begin
    exceptions <= exceptions_s3;
    result     <=  early_result_mult_s3  ?  early_result_s3                                                        :
                   oflow_res_mult_s3     ?  overflow_result_s3                                                     :
                   norm_res_mult_s3      ? {sign_res_s3,  exp_res_s3,               mant_round_s3[MANT_W - 2 : 0]} :
                   subnormal_promoted_s3 ? {sign_res_s3, {{EXP_W - 1{1'b0}}, 1'b1}, mant_round_s3[MANT_W - 2 : 0]} :
                   subnorm_res_mult_s3   ? {sign_res_s3, {(EXP_W){1'b0}},           mant_round_s3[MANT_W - 2 : 0]} :
                                           {sign_res_s3, {(DATA_W - 1){1'b0}}}                                     ; 
end

endmodule