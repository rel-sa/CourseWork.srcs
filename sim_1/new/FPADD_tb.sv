`timescale 1ns / 1ps
import st_pkg::*;


module FPADD_tb();
localparam IS_DOUBLE = st_pkg::IS_DOUBLE;
localparam DATA_W = IS_DOUBLE ? 64 : 32;
localparam MANT_W = IS_DOUBLE ? 53 : 24;
localparam EXP_W  = IS_DOUBLE ? 11 : 8;
localparam BIAS   = IS_DOUBLE ? 1023 : 127;
localparam LZC_W  = $clog2(MANT_W + 1);

wire  fp_exception_type exceptions;
reg  [EXP_W - 1:0]  exp_a, exp_b;
reg  [MANT_W - 2:0] mant_a, mant_b;
reg                 sign_a, sign_b;
reg  [DATA_W - 1:0] op_a;
reg  [DATA_W - 1:0] op_b;
reg  [DATA_W - 1:0] res_eth_initial;
reg  [DATA_W - 1:0] res_eth_s1;
reg  [DATA_W - 1:0] res_eth_s2;
reg  [DATA_W - 1:0] res_eth_s3;
reg  [DATA_W - 1:0] res_eth_s4;
reg  [DATA_W - 1:0] res_eth_s5;
reg  [DATA_W - 1:0] res_eth_s6;
reg  [DATA_W - 1:0] res_eth_s7;
reg  [DATA_W - 1:0] res_eth_final;
reg                 clk;
wire [DATA_W - 1:0] result;
wire                valid;
reg                 rst;
reg                 run;
wire                busy;
wire                ethalon_nan;
wire                result_qnan;
wire                unknown_bits;
wire                result_mismatch;


real real_a, real_b, ethalon;

initial clk = 0;
always #5 clk = ~clk;

top #(
    .ROUND_MODE(NRST),
    .OPERATION (ADD)
) dut (
    .clk       (clk),
    .rst       (rst),
    .op1       (op_a),
    .op2       (op_b),
    .valid     (valid),
    .result    (result),
    .exceptions(exceptions),
    .run       (run),
    .busy      (busy)
);

initial begin
    run = 1'b0;
    rst = 1'b1;
    repeat (3) @(negedge clk);
    rst = 1'b0;
end

assign ethalon_nan = (&res_eth_final[DATA_W - 2:MANT_W - 1]) &
                     (|res_eth_final[MANT_W - 2:0])          ;

assign result_qnan = (&result[DATA_W - 2:MANT_W - 1]) &
                       result[MANT_W - 2]            ;
                       
assign unknown_bits    = $isunknown({res_eth_final, result});

assign result_mismatch = ethalon_nan ? (result_qnan !== 1'b1) :
                                        (result !== res_eth_final) ;

always @(negedge clk)
if (~rst) begin
    run = 1;
    sign_a  = $random() % 2;
    sign_b  = $random() % 2;
    exp_a   = {$random(), $random()} % (1 << 11);
    //exp_b   = {$random(), $random()} % (1 << 11);
    exp_b   = BIAS - exp_a + ($random() % 5 - 2);
    mant_a  = {$random(), $random()} % (1 << 52);
    mant_b  = {$random(), $random()} % (1 << 52);

    //sign_a  = 1'b1;
    //sign_b  = 1'b0;
    //exp_a   = 'd1030;
    //exp_b   = 'd0;
    //mant_a  = 52'b1111111111111111111111111111111111111111111111111111;
    //mant_b  = 52'b1111111111111111111111111111111111111111111111111111;
    //op_a = 64'b0000000000001001111010010101110100000010100100111010000100000101;
    //op_b = 64'b1011111111110101100001011110000010011111000101111101011000111110;

    op_a    = {sign_a, exp_a, mant_a};
    op_b    = {sign_b, exp_b, mant_b};
    
    real_a  = $bitstoreal(op_a);
    real_b  = $bitstoreal(op_b);
    ethalon = real_a + real_b;
    
    res_eth_initial <= $realtobits(ethalon);
    res_eth_s1      <= res_eth_initial;
    res_eth_s2      <= res_eth_s1;
    res_eth_s3      <= res_eth_s2;
    res_eth_s4      <= res_eth_s3;
    res_eth_s5      <= res_eth_s4;
    res_eth_s6      <= res_eth_s5;
    res_eth_s7      <= res_eth_s6;
    res_eth_final   <= res_eth_s7;
    if (valid && (unknown_bits || result_mismatch))
    begin
        $display("Error");
        $display("%0tps, Ethalon = %b", $time, res_eth_final);
        $display("%0tps, Result  = %b", $time, result);
        $stop;
    end
end
endmodule