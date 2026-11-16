module integer_multiplier #(
    parameter IS_DOUBLE = 1,    

    localparam DATA_W      = IS_DOUBLE ? 53 : 24, // mantissa size
    localparam ARGS_AMOUNT = IS_DOUBLE ? 27 : 13, // args list's size
    localparam Y_EXT_SIZE  = IS_DOUBLE ? 55 : 27  // size of y_ext
)(
    input  [DATA_W - 1:0]   x,
    input  [DATA_W - 1:0]   y,
    input                   clk,
    output [2*DATA_W - 1:0] result
);

function  [2*DATA_W - 1:0] ps;
    input [2*DATA_W - 1:0] A, B, C;
    begin
        ps = A ^ B ^ C;
    end
endfunction

function  [2*DATA_W - 1:0] pc;
    input [2*DATA_W - 1:0] A, B, C;
    begin
        pc = ((A & B) | (A & C) | (B & C)) << 1;
    end
endfunction

wire [2*DATA_W - 1:0]   x_ext;
wire [2*DATA_W - 1:0]   minus_x;
wire [2*DATA_W - 1:0]   double_x;
wire [2*DATA_W - 1:0]   minus_double_x;
wire [Y_EXT_SIZE - 1:0] y_ext;

assign y_ext          = IS_DOUBLE ? {1'b0,  y, 1'b0} : 
                                    {2'b00, y, 1'b0} ;

assign x_ext          = {{DATA_W{1'b0}}, x};
assign minus_x        = ~x_ext + 1'b1;
assign double_x       =  x_ext   << 1;
assign minus_double_x =  minus_x << 1;

wire [2*DATA_W - 1:0] shifted_args [0 : ARGS_AMOUNT - 1];

genvar i;
generate
    for (i = 0; i < 2*ARGS_AMOUNT; i = i + 2) begin: args_gen
        wire [2*DATA_W - 1:0] arg;
        assign arg = {2*DATA_W{y_ext[i+2 : i] == 3'b000}} & {2*DATA_W{1'b0}} |
                     {2*DATA_W{y_ext[i+2 : i] == 3'b001}} &  x_ext           |
                     {2*DATA_W{y_ext[i+2 : i] == 3'b010}} &  x_ext           |
                     {2*DATA_W{y_ext[i+2 : i] == 3'b011}} &  double_x        |
                     {2*DATA_W{y_ext[i+2 : i] == 3'b100}} &  minus_double_x  |
                     {2*DATA_W{y_ext[i+2 : i] == 3'b101}} &  minus_x         |
                     {2*DATA_W{y_ext[i+2 : i] == 3'b110}} &  minus_x         |
                     {2*DATA_W{y_ext[i+2 : i] == 3'b111}} & {2*DATA_W{1'b0}} ;
        assign shifted_args[i / 2] = arg << i;
    end
endgenerate

genvar j, k;
generate
    if (IS_DOUBLE) begin: double
        wire [2*DATA_W - 1:0] l0_ps [0:8];
        wire [2*DATA_W - 1:0] l0_pc [0:8];
        
        for (j = 0; j < 9; j = j + 1) begin: gen_l0
            assign l0_ps[j] = ps(shifted_args[3*j], shifted_args[3*j+1], shifted_args[3*j+2]);
            assign l0_pc[j] = pc(shifted_args[3*j], shifted_args[3*j+1], shifted_args[3*j+2]);
        end
        
        wire [2*DATA_W - 1:0] l1_ps [0:5];
        wire [2*DATA_W - 1:0] l1_pc [0:5];
        
        assign l1_ps[0] = ps(l0_ps[0], l0_pc[0], l0_ps[1]);
        assign l1_pc[0] = pc(l0_ps[0], l0_pc[0], l0_ps[1]);
        
        assign l1_ps[1] = ps(l0_pc[1], l0_ps[2], l0_pc[2]);
        assign l1_pc[1] = pc(l0_pc[1], l0_ps[2], l0_pc[2]);
        
        assign l1_ps[2] = ps(l0_ps[3], l0_pc[3], l0_ps[4]);
        assign l1_pc[2] = pc(l0_ps[3], l0_pc[3], l0_ps[4]);
        
        assign l1_ps[3] = ps(l0_pc[4], l0_ps[5], l0_pc[5]);
        assign l1_pc[3] = pc(l0_pc[4], l0_ps[5], l0_pc[5]);
        
        assign l1_ps[4] = ps(l0_ps[6], l0_pc[6], l0_ps[7]);
        assign l1_pc[4] = pc(l0_ps[6], l0_pc[6], l0_ps[7]);
        
        assign l1_ps[5] = ps(l0_pc[7], l0_ps[8], l0_pc[8]);
        assign l1_pc[5] = pc(l0_pc[7], l0_ps[8], l0_pc[8]);        
        
        wire [2*DATA_W - 1:0] l2_ps [0:3];
        wire [2*DATA_W - 1:0] l2_pc [0:3];
        
        reg  [2*DATA_W - 1:0] l2_ps_reg [0:3];
        reg  [2*DATA_W - 1:0] l2_pc_reg [0:3];
        
        assign l2_ps[0] = ps(l1_ps[0], l1_pc[0], l1_ps[1]);
        assign l2_pc[0] = pc(l1_ps[0], l1_pc[0], l1_ps[1]);
        
        assign l2_ps[1] = ps(l1_pc[1], l1_ps[2], l1_pc[2]);
        assign l2_pc[1] = pc(l1_pc[1], l1_ps[2], l1_pc[2]);
        
        assign l2_ps[2] = ps(l1_ps[3], l1_pc[3], l1_ps[4]);
        assign l2_pc[2] = pc(l1_ps[3], l1_pc[3], l1_ps[4]);
        
        assign l2_ps[3] = ps(l1_pc[4], l1_ps[5], l1_pc[5]);
        assign l2_pc[3] = pc(l1_pc[4], l1_ps[5], l1_pc[5]);
        
        for (k = 0; k < 4; k = k + 1) begin: l2_gen
            always @(posedge clk) begin
                l2_ps_reg[k] <= l2_ps[k];
                l2_pc_reg[k] <= l2_pc[k];
            end
        end
        
        wire [2*DATA_W - 1:0] l3_ps [0:2];
        wire [2*DATA_W - 1:0] l3_pc [0:2];
        
        assign l3_ps[0] = ps(l2_ps_reg[0], l2_pc_reg[0], l2_ps_reg[1]);
        assign l3_pc[0] = pc(l2_ps_reg[0], l2_pc_reg[0], l2_ps_reg[1]);
        
        assign l3_ps[1] = ps(l2_pc_reg[1], l2_ps_reg[2], l2_pc_reg[2]);
        assign l3_pc[1] = pc(l2_pc_reg[1], l2_ps_reg[2], l2_pc_reg[2]);
        
        assign l3_ps[2] = l2_ps_reg[3];
        assign l3_pc[2] = l2_pc_reg[3];
        
        wire [2*DATA_W - 1:0] l4_ps [0:1];
        wire [2*DATA_W - 1:0] l4_pc [0:1];
        
        assign l4_ps[0] = ps(l3_ps[0], l3_pc[0], l3_ps[1]);
        assign l4_pc[0] = pc(l3_ps[0], l3_pc[0], l3_ps[1]);
        
        assign l4_ps[1] = ps(l3_pc[1], l3_ps[2], l3_pc[2]);
        assign l4_pc[1] = pc(l3_pc[1], l3_ps[2], l3_pc[2]);
        
        wire [2*DATA_W - 1:0] l5_ps;
        wire [2*DATA_W - 1:0] l5_pc;
        wire [2*DATA_W - 1:0] l5_rem;
        
        assign l5_ps = ps(l4_ps[0], l4_pc[0], l4_ps[1]);
        assign l5_pc = pc(l4_ps[0], l4_pc[0], l4_ps[1]);
        assign l5_rem = l4_pc[1];
        
        wire [2*DATA_W - 1:0] l6_ps;
        wire [2*DATA_W - 1:0] l6_pc;
        
        reg  [2*DATA_W - 1:0] l6_ps_reg;
        reg  [2*DATA_W - 1:0] l6_pc_reg;
        
        assign l6_ps = ps(l5_ps, l5_pc, l5_rem);
        assign l6_pc = pc(l5_ps, l5_pc, l5_rem);
        
        always @(posedge clk) begin
            l6_ps_reg <= l6_ps;
            l6_pc_reg <= l6_pc;
        end
        
        assign result = l6_ps_reg + l6_pc_reg;
        
    end else begin: single
        wire [2*DATA_W - 1:0] l0_ps [0:3];
        wire [2*DATA_W - 1:0] l0_pc [0:3];
        
        for (j = 0; j < 4; j = j + 1) begin: gen_l0
            assign l0_ps[j] = ps(shifted_args[3*j], shifted_args[3*j+1], shifted_args[3*j+2]);
            assign l0_pc[j] = pc(shifted_args[3*j], shifted_args[3*j+1], shifted_args[3*j+2]);
        end
        
        wire [2*DATA_W - 1:0] l1_ps [0:2];
        wire [2*DATA_W - 1:0] l1_pc [0:2];
        
        assign l1_ps[0] = ps(l0_ps[0], l0_pc[0], l0_ps[1]);
        assign l1_pc[0] = pc(l0_ps[0], l0_pc[0], l0_ps[1]);
        
        assign l1_ps[1] = ps(l0_pc[1], l0_ps[2], l0_pc[2]);
        assign l1_pc[1] = pc(l0_pc[1], l0_ps[2], l0_pc[2]);
        
        assign l1_ps[2] = ps(l0_ps[3], l0_pc[3], shifted_args[12]);
        assign l1_pc[2] = pc(l0_ps[3], l0_pc[3], shifted_args[12]);
        
        wire [2*DATA_W - 1:0] l2_ps [0:1];
        wire [2*DATA_W - 1:0] l2_pc [0:1];
        
        reg  [2*DATA_W - 1:0] l2_ps_reg [0:1];
        reg  [2*DATA_W - 1:0] l2_pc_reg [0:1];
        
        assign l2_ps[0] = ps(l1_ps[0], l1_pc[0], l1_ps[1]);
        assign l2_pc[0] = pc(l1_ps[0], l1_pc[0], l1_ps[1]);
        
        assign l2_ps[1] = ps(l1_pc[1], l1_ps[2], l1_pc[2]);
        assign l2_pc[1] = pc(l1_pc[1], l1_ps[2], l1_pc[2]);
        
        for (k = 0; k < 2; k = k + 1) begin: l2_gen
            always @(posedge clk) begin
                l2_ps_reg[k] <= l2_ps[k];
                l2_pc_reg[k] <= l2_pc[k];
            end
        end
        
        wire [2*DATA_W - 1:0] l3_ps;
        wire [2*DATA_W - 1:0] l3_pc;
        wire [2*DATA_W - 1:0] l3_rem;
        
        assign l3_ps  = ps(l2_ps_reg[0], l2_pc_reg[0], l2_ps_reg[1]);
        assign l3_pc  = pc(l2_ps_reg[0], l2_pc_reg[0], l2_ps_reg[1]);
        assign l3_rem = l2_pc_reg[1];
        
        wire [2*DATA_W - 1:0] l4_ps;
        wire [2*DATA_W - 1:0] l4_pc;
        
        reg  [2*DATA_W - 1:0] l4_ps_reg;
        reg  [2*DATA_W - 1:0] l4_pc_reg;
        
        assign l4_ps = ps(l3_ps, l3_pc, l3_rem);
        assign l4_pc = pc(l3_ps, l3_pc, l3_rem);
        
        always @(posedge clk) begin
            l4_ps_reg <= l4_ps;
            l4_pc_reg <= l4_pc;
        end
        
        assign result = l4_ps_reg + l4_pc_reg;
    end
endgenerate

endmodule