module fifo2#(
    parameter DWIDTH = 32,
    parameter ADEPTH =  7)(
    input  wire                  CLK,
    input  wire                  RST,
   
    input  wire                  WR_EN,
    input  wire [(DWIDTH - 1):0] DIN,
    output wire                  FULL,
    
    input  wire                  RD_EN,
    output wire [(DWIDTH - 1):0] DOUT,
    output wire                  EMPTY
    );

    reg [ADEPTH:0] wr_ptr, rd_ptr=7'b0;
    wire wrap_around, comp;

    assign wrap_around = wr_ptr[ADEPTH] ^ rd_ptr[ADEPTH];
    assign comp  = (wr_ptr[(ADEPTH - 1):0] == rd_ptr[(ADEPTH - 1):0]) ? 1'h1 : 1'h0;
    assign FULL = comp & wrap_around;
    assign EMPTY = (wr_ptr == rd_ptr) ? 1'h1 : 1'h0;
    
    sram2#(
        .DWIDTH(DWIDTH),
        .AWIDTH(ADEPTH)) 
    ramdut2(
    /*================ Port A ================*/
        .CLKA  (CLK),
        .ENA   (WR_EN & (~FULL)),
        .WEA   (WR_EN),
        .ADDRA (wr_ptr[(ADEPTH - 1):0]),
        .DINA  (DIN),
    /*================ Port B ================*/
        .CLKB  (CLK),
        .ENB   (RD_EN & (~EMPTY)),
        .ADDRB (rd_ptr[(ADEPTH - 1):0]),
        .DOUTB (DOUT)
    );

    always @(posedge CLK or negedge RST) begin
        if (~RST) wr_ptr <= 0;//{(ADEPTH + 1){1'h0}};
        else      wr_ptr <= (WR_EN & (~FULL)) ? (wr_ptr + 1'h1) : wr_ptr;
    end
    always @(posedge CLK or negedge RST) begin
        if (~RST) rd_ptr <= 0;//{(ADEPTH + 1){1'h0}};
        else      rd_ptr <= (RD_EN & (~EMPTY)) ? (rd_ptr + 1'h1) : rd_ptr;
    end

endmodule



    

//module sram2#(
//    parameter DWIDTH = 32,
//    parameter AWIDTH =  7)(
//    /*================ Port A ================*/
//    input  wire CLKA,
//    input  wire ENA,
//    input  wire WEA,
//    input  wire [(AWIDTH - 1):0] ADDRA,
//    input  wire [(DWIDTH - 1):0] DINA,
//    /*================ Port B ================*/
//    input  wire CLKB,
//    input  wire ENB,
//    input  wire [(AWIDTH - 1):0] ADDRB,
//    output wire [(DWIDTH - 1):0] DOUTB
//    );

//    reg     [(DWIDTH - 1):0] memory[((1 << AWIDTH) - 1):0];
//    reg     [(DWIDTH - 1):0] b_reg;
//    integer                  i;

//    assign DOUTB = b_reg;

//    initial begin
//        for(i = 0;i < (1 << AWIDTH); i = i + 1)
//            memory[i] <= {DWIDTH{1'h0}};
//        b_reg <= {DWIDTH{1'h0}};
//    end

//    always @(posedge CLKA) begin
//        if (ENA) begin
//            if (WEA) memory[ADDRA] <= DINA;
//        end
//    end

//    always @(posedge CLKB) begin
//        if (ENB) b_reg <= memory[ADDRB];
//    end

//endmodule