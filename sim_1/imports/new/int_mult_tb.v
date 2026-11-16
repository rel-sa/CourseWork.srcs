`timescale 1ns / 1ps

module int_mult_tb();
parameter IS_DOUBLE = 0;
localparam DATA_W = IS_DOUBLE ? 53 : 24;
parameter TEST_NUMBERS = 1;

reg signed [DATA_W - 1:0] x;
reg signed [DATA_W - 1:0] y;

wire signed [2*DATA_W - 1:0] result;

integer_multiplier #(
    .IS_DOUBLE(IS_DOUBLE)
) dut (
    .x(x),
    .y(y),
    .result(result)
);

wire [2 * DATA_W - 1:0] correct;
assign correct = x * y;

task random_test;
begin
    //x = $random;
    //y = $random;
    x = 24'b100000000000000000000000;
    y = 24'b100000000000000000000000;
    #10;
        
    if (result != correct) begin
        $display("Error at %0tns", $time);
        $stop;
    end
end
endtask

initial begin
    repeat(TEST_NUMBERS) random_test();
    $display("All tests passed");
    $finish;
end

endmodule
