`timescale 1ns / 1ps
import st_pkg::*;

module FPDIV_tb();
localparam IS_DOUBLE = st_pkg::IS_DOUBLE;
localparam DATA_W = IS_DOUBLE ? 64 : 32;
localparam MANT_W = IS_DOUBLE ? 53 : 24;
localparam EXP_W  = IS_DOUBLE ? 11 : 8;
localparam BIAS   = IS_DOUBLE ? 1023 : 127;

wire  fp_exception_type exceptions;
reg  [EXP_W - 1:0]  exp_a, exp_b;
reg  [MANT_W - 2:0] mant_a, mant_b;
reg                 sign_a, sign_b;
reg  [DATA_W - 1:0] op_a;
reg  [DATA_W - 1:0] op_b;
reg  [DATA_W - 1:0] res_eth;
reg                 clk;
wire [DATA_W - 1:0] result;
wire                valid;
reg                 rst;
reg                 run;
wire                busy;
wire                result_qnan;
wire                ethalon_nan;
wire                result_matches;

real real_a, real_b, ethalon;

initial clk = 0;
always #5 clk = ~clk;

top #(
    .ROUND_MODE(NRST),
    .OPERATION (DIV)
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

assign result_qnan = (&result[ DATA_W - 2:MANT_W - 1]) &    result[MANT_W - 2];
assign ethalon_nan = (&res_eth[DATA_W - 2:MANT_W - 1]) & (|res_eth[MANT_W - 2:0]);

assign result_matches =  (result === res_eth)                             | 
                        ((result_qnan === 1'b1) & (ethalon_nan === 1'b1)) ;

always @(negedge clk)
if (rst)
    run = 1'b0;
else begin
    run = 1'b0;
    
    if (valid == 1'b1)
    begin
        if (~result_matches) begin
            $display("Error");
            $display("%0tps, Operand1 = %b", $time, op_a);
            $display("%0tps, Operand2 = %b", $time, op_b);
            $display("%0tps, Ethalon  = %b", $time, res_eth);
            $display("%0tps, Result   = %b", $time, result);
            $stop;
        end
    end
    
    if (~busy) begin
        sign_a  = $random() % 2;
        sign_b  = $random() % 2;
        exp_a   = {$random(), $random()} % (1 << 11);
        exp_b   = {$random(), $random()} % (1 << 11);
        //exp_b   = BIAS - exp_a + ($random() % 5 - 2);
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
        ethalon = real_a / real_b;
    
        res_eth = $realtobits(ethalon);
        
        run = 1'b1;
        
    end
end
endmodule