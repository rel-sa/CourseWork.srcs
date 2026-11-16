package st_pkg;

    localparam IS_DOUBLE = 1;
    localparam DATA_W = IS_DOUBLE ? 64 : 32;
    localparam MANT_W = IS_DOUBLE ? 53 : 24;
    localparam EXP_W  = IS_DOUBLE ? 11 : 8 ;
    
    typedef struct packed {
        logic nan;
        logic inf;
        logic zero;
        logic subnormal;
    } op_status;
  
    typedef enum logic [1:0] {
        NRST = 2'b00,
        ZERO = 2'b01,
        INFP = 2'b10,
        INFN = 2'b11    
    } round_mode_type;
  
    typedef struct packed {
        op_status            flags;
        logic                sign;
        logic [EXP_W  - 1:0] exp;
        logic [MANT_W - 1:0] mant;
    } operand_type;
    
    typedef struct packed {
        logic nv; // invalid operation
        logic dz; // division by zero
        logic of; // overflow
        logic uf; // underflow
        logic nx; // inexact
    } fp_exception_type;
    
    typedef enum logic [1:0] {
        MUL = 2'b00,
        DIV = 2'b01,
        ADD = 2'b10,
        SUB = 2'b11    
    } operation_type;
    
endpackage
