module round #(
    parameter IS_DOUBLE = 1,

    localparam MANT_W = IS_DOUBLE ? 53 : 24
)(
    input  [2*MANT_W - 1:0] mant_norm,
    input  round_mode_type  round_mode,
    input                   sign,
    output                  adj_round,
    output [MANT_W - 1:0]   mant_raw,
    output                  mant_increment
);

wire [MANT_W - 1:0] res_mant_raw;
wire [MANT_W - 1:0] res_mant_tail;
wire                rbit;
wire                gbit;
wire                sbit;
wire                mant_incr;
wire                raw_mant_max;

assign res_mant_raw  = mant_norm[2*MANT_W - 1 : MANT_W];
assign res_mant_tail = mant_norm[MANT_W - 1 : 0];

assign rbit =  res_mant_raw[0];
assign gbit =  res_mant_tail[MANT_W - 1];
assign sbit = |res_mant_tail[MANT_W - 2:0];

assign raw_mant_max = &res_mant_raw;

assign mant_incr =                                 ~gbit & ~sbit  ? 1'b0  :
                    round_mode == ZERO                            ? 1'b0  :
                   (round_mode == INFP)         & ( gbit |  sbit) ? ~sign :
                   (round_mode == INFN)         & ( gbit |  sbit) ?  sign :
                   (round_mode == NRST)         &  ~gbit &  sbit  ? 1'b0  :
                   (round_mode == NRST)         &   gbit &  sbit  ? 1'b1  :
                   (round_mode == NRST) &  rbit &   gbit & ~sbit  ? 1'b1  :
                   (round_mode == NRST) & ~rbit &   gbit & ~sbit  ? 1'b0  :
                                                                    1'b0  ;
             
assign adj_round  = raw_mant_max & mant_incr;

assign mant_raw       = res_mant_raw;
assign mant_increment = mant_incr;

endmodule
