`timescale 1ns / 1ps
import st_pkg::*;

module FPMUL_compare_tb();
localparam DATA_W       = 64;
localparam EXP_W        = 11;
localparam MANT_W       = 53;
localparam BIAS         = 1023;
localparam TEST_NUMBERS = 100;
localparam MAX_WAIT     = 256;

reg                     clk;
reg                     rst;
reg                     run;
reg  [DATA_W - 1:0]     op_a;
reg  [DATA_W - 1:0]     op_b;

reg                     sign_a, sign_b;
reg  [EXP_W  - 1:0]     exp_a, exp_b;
reg  [MANT_W - 2:0]     mant_a, mant_b;

wire                    busy;
wire                    valid;
wire                    valid_xilinx;
wire                    ip_run;
wire [DATA_W - 1:0]     result;
wire [DATA_W - 1:0]     result_xilinx;
wire fp_exception_type  exceptions;
wire [DATA_W - 1:0]     ethalon;

integer passed;

initial clk = 1'b0;
always #5 clk = ~clk;

assign ip_run = run & ~rst;

top #(
    .ROUND_MODE(NRST),
    .OPERATION (MUL)
) dut (
    .clk       (clk),
    .rst       (rst),
    .op1       (op_a),
    .op2       (op_b),
    .run       (run),
    .busy      (busy),
    .valid     (valid),
    .result    (result),
    .exceptions(exceptions)
);

xilinx_fpmul64 reference_mul (
    .aclk                (clk),
    .aresetn             (~rst),
    .s_axis_a_tvalid     (ip_run),
    .s_axis_a_tdata      (op_a),
    .s_axis_b_tvalid     (ip_run),
    .s_axis_b_tdata      (op_b),
    .m_axis_result_tvalid(valid_xilinx),
    .m_axis_result_tdata (result_xilinx)
);

task compare_pair;
input [DATA_W - 1:0] operand_a;
input [DATA_W - 1:0] operand_b;
reg                  my_done;
reg                  xilinx_done;
reg [DATA_W - 1:0]   my_saved;
reg [DATA_W - 1:0]   xilinx_saved;
integer              wait_clocks;
begin
    @(negedge clk);
    op_a        = operand_a;
    op_b        = operand_b;
    run         = 1'b1;
    my_done     = 1'b0;
    xilinx_done = 1'b0;
    my_saved    = 'x;
    xilinx_saved = 'x;
    wait_clocks = 0;

    while ((!my_done || !xilinx_done) && (wait_clocks < MAX_WAIT))
    begin
        @(negedge clk);

        if ((valid === 1'b1) && !my_done)
        begin
            my_saved = result;
            my_done  = 1'b1;
        end

        if ((valid_xilinx === 1'b1) && !xilinx_done)
        begin
            xilinx_saved = result_xilinx;
            xilinx_done  = 1'b1;
        end

        run         = 1'b0;
        wait_clocks = wait_clocks + 1;
    end

    if (!my_done || !xilinx_done)
        $fatal(1, "Timeout: own_done=%b, xilinx_done=%b", my_done, xilinx_done);

    if ($isunknown(my_saved) || $isunknown(xilinx_saved) || (my_saved !== xilinx_saved))
    begin
        $display("A      = %h", operand_a);
        $display("B      = %h", operand_b);
        $display("Own    = %h", my_saved);
        $display("Xilinx = %h", xilinx_saved);
        $fatal(1, "Multiplication mismatch");
    end

    passed = passed + 1;
end
endtask

initial begin
    run    = 1'b0;
    rst    = 1'b1;
    op_a   = '0;
    op_b   = '0;
    passed = 0;

    repeat (4) @(negedge clk);
    rst = 1'b0;

    // У FPMUL нет собственного rst: пропускаем пустые такты,
    // чтобы очистить цепочку valid. Также выдерживаем паузу после ARESETn.
    repeat (12) @(negedge clk);

    compare_pair(64'h0008_0000_0000_0000, 64'h4008_0000_0000_0000);

    repeat (TEST_NUMBERS)
    begin
        sign_a = $urandom_range(1, 0);
        sign_b = $urandom_range(1, 0);
        exp_a  = $urandom_range(BIAS + 20, BIAS - 20);
        exp_b  = $urandom_range(BIAS + 20, BIAS - 20);
        mant_a = {$urandom(), $urandom()};
        mant_b = {$urandom(), $urandom()};

        compare_pair({sign_a, exp_a, mant_a}, {sign_b, exp_b, mant_b});
    end

    $display("PASS: %0d operand pairs matched", passed);
    $finish;
end
assign ethalon = 64'h0018000000000000;

endmodule
