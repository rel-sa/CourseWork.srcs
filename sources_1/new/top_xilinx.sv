module top_xilinx #(
    parameter USE_DSP = 1,

    localparam DATA_W = 64
)(
    input                    clk,
    input                    rst,
    input  [DATA_W - 1:0]    op1,
    input  [DATA_W - 1:0]    op2,
    input                    run,
    output                   busy,
    output                   valid,
    output [DATA_W - 1:0]    result
);

wire accept;
wire ip_run;

reg                      run_reg;
reg  [DATA_W - 1:0]      op1_reg;
reg  [DATA_W - 1:0]      op2_reg;

assign busy   = 1'b0;
assign accept = run & ~busy & ~rst;
assign ip_run = run_reg & ~rst;

always @(posedge clk)
if (rst)
begin
    op1_reg <= {DATA_W{1'b0}};
    op2_reg <= {DATA_W{1'b0}};
    run_reg <= 1'b0;
end else begin
    op1_reg <= accept ? op1     :
                        op1_reg ;
    op2_reg <= accept ? op2     :
                        op2_reg ;
    run_reg <= accept;
end

generate
if (USE_DSP) begin : DSP_GEN

    xilinx_fpmul64_DSP multiply (
        .aclk                (clk),
        .aresetn             (~rst),
        .s_axis_a_tvalid     (ip_run),
        .s_axis_a_tdata      (op1_reg),
        .s_axis_b_tvalid     (ip_run),
        .s_axis_b_tdata      (op2_reg),
        .m_axis_result_tvalid(valid),
        .m_axis_result_tdata (result)
    );

end else begin : NO_DSP_GEN

    xilinx_fpmul64_noDSP multiply (
        .aclk                (clk),
        .aresetn             (~rst),
        .s_axis_a_tvalid     (ip_run),
        .s_axis_a_tdata      (op1_reg),
        .s_axis_b_tvalid     (ip_run),
        .s_axis_b_tdata      (op2_reg),
        .m_axis_result_tvalid(valid),
        .m_axis_result_tdata (result)
    );

end
endgenerate

endmodule