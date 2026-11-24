import st_pkg::*;

module top #(
    parameter IS_DOUBLE  = 1,
    parameter ROUND_MODE = NRST,
    parameter OPERATION  = SUB,

    localparam DATA_W = IS_DOUBLE ? 64   : 32 ,
    localparam MANT_W = IS_DOUBLE ? 53   : 24 ,
    localparam EXP_W  = IS_DOUBLE ? 11   : 8  ,
    localparam BIAS   = IS_DOUBLE ? 1023 : 127,
    localparam LZC_W  = $clog2(MANT_W + 1)
)(
    input                    clk,
    input                    rst,
    input  [DATA_W - 1:0]    op1,
    input  [DATA_W - 1:0]    op2,
    input                    run,
    output                   busy,
    output                   valid,
    output [DATA_W - 1:0]    result,
    output fp_exception_type exceptions
);

operand_type operand1;
operand_type operand2;

operand_type operand1_reg;
operand_type operand2_reg;

wire accept;

reg  run_reg;

assign accept = run & ~busy & ~rst;

op_an #(
    .IS_DOUBLE(IS_DOUBLE)
) op_an1 (
    .op     (op1),
    .operand(operand1)
);

op_an #(
    .IS_DOUBLE(IS_DOUBLE)
) op_an2 (
    .op     (op2),
    .operand(operand2)
);

always @(posedge clk) begin
    if (rst) begin
        operand1_reg <= '0;
        operand2_reg <= '0;
        run_reg      <= 1'b0;
    end else begin
        run_reg      <= accept ;
        operand1_reg <= accept ? operand1     :
                                 operand1_reg ;
        operand2_reg <= accept ? operand2     :
                                 operand2_reg ;
    end
end

generate
case (OPERATION)
    MUL: begin : FPMUL_GEN
    
        assign busy = 1'b0;
        
        FPMUL #(
            .IS_DOUBLE(IS_DOUBLE)
        ) multiply (
            .operand1_s0(operand1_reg),
            .operand2_s0(operand2_reg),
            .clk        (clk),
            .round_mode (ROUND_MODE),
            .run        (run_reg),
            .val        (valid),
            .result     (result),
            .exceptions (exceptions)
        );
    end
    
    DIV: begin : FPDIV_GEN
    
        wire   busy_div;
        
        assign busy = busy_div | run_reg;
        
        FPDIV #(
            .IS_DOUBLE(IS_DOUBLE)
        ) divide (
            .operand1_s0(operand1_reg),
            .operand2_s0(operand2_reg),
            .clk        (clk),
            .round_mode (ROUND_MODE),
            .run        (run_reg),
            .rst        (rst),
            .val        (valid),
            .busy       (busy_div),
            .result     (result),
            .exceptions (exceptions)
        );
    end
    
    ADD: begin: FPA_GEN
    
        assign busy = 1'b0; // тоже хочу сделать конвейерным, как FPMUL
        
        FPA #(
            .IS_DOUBLE(IS_DOUBLE)
        ) add (
            .operand1_s0(operand1_reg),
            .operand2_s0(operand2_reg),
            .clk        (clk),
            .round_mode (ROUND_MODE),
            .sub        (1'b0),
            .run        (run_reg),
            .rst        (rst),
            .val        (valid),
            .result     (result),
            .exceptions (exceptions) // это набросок, возможно интерфейс будет отличаться
        );
    end
    
    SUB: begin: FPS_GEN
    
        assign busy = 1'b0; // тоже хочу сделать конвейерным, как FPMUL
        
        FPA #(
            .IS_DOUBLE(IS_DOUBLE)
        ) subtract (
            .operand1_s0(operand1_reg),
            .operand2_s0(operand2_reg),
            .clk        (clk),
            .round_mode (ROUND_MODE),
            .sub        (1'b1),
            .run        (run_reg),
            .rst        (rst),
            .val        (valid),
            .result     (result),
            .exceptions (exceptions) // это набросок, возможно интерфейс будет отличаться
        );
    end
    
    default: begin : DEFAULT_GEN
        assign valid      = 1'b0;
        assign result     = '0;
        assign exceptions = '0;
        assign busy       = 1'b1;
    end
endcase
endgenerate

endmodule
