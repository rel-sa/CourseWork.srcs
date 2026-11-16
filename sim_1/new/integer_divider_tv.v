`timescale 1ns / 1ps

module integer_divider_tv();
parameter IS_DOUBLE = 1;
localparam DATA_W = IS_DOUBLE ? 53 : 24;
parameter TEST_NUMBERS = 5;
localparam FRAC_W = DATA_W + 2;
localparam QUOT_W = DATA_W + FRAC_W;

reg [DATA_W - 1:0] mant1;
reg [DATA_W - 1:0] mant2;

reg rst;
reg clk;
initial clk = 0;
always #5 clk = ~clk;

wire busy;
wire val;
wire div_by_zero;
wire [QUOT_W - 1 : 0] divided_mant;
wire [DATA_W - 1 : 0] remainder;

integer_divider #(
    .IS_DOUBLE(IS_DOUBLE)
) dut (
    .mant1(mant1),
    .mant2(mant2),
    .clk  (clk),
    .rst  (rst),
    .run  (1'b1),
    .val(val),
    .div_by_zero(div_by_zero),
    .divided_mant(divided_mant),
    .remainder(remainder)
);

wire [QUOT_W - 1:0] correct;
assign correct = mant2 == 0 ? {QUOT_W{1'b1}}                  :
                              {mant1, {FRAC_W{1'b0}}} / mant2 ;

task random_test;
begin
    rst = 1;
    repeat(3) @(negedge clk);
    rst = 0;
    
    mant1 = {$random(), $random()};
    mant2 = {$random(), $random()};
    //x = 53'd100;
    //y = 53'd2;
    wait(val == 1'b1);
    #1;
    
    if (divided_mant !== correct)
        $fatal(1, "Incorrect quotient");

    if (div_by_zero !== (mant2 == 0))
        $fatal(1, "Incorrect div_by_zero");
        
end
endtask

initial begin
    repeat(TEST_NUMBERS) 
    begin
        @(negedge clk);
        random_test();
    end
    $finish;
end

endmodule
