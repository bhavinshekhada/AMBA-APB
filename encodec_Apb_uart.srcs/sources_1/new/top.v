module top(
    input                clk,
    input [47:0]         wr_data,
    input                wr_en,
    input                preset_n,
    output               f_full,
    output [47:0]        fifo_data_frame,
    output               fifo_w_en,
    output               o_tx_active,
    output               o_tx_serial,    
    output               full
    ); 
    
    wire a;
    wire b;
    wire c;
    wire d;
    wire [31:0] a1;
    wire [31:0] a2;
    wire [31:0] a3;
    wire [31:0] a4;
    wire a5;
    wire a6;
    wire a7;
    wire [7:0] a8;
    wire a9;
    wire [31:0] b1;
    wire b2;
    wire b3;
    wire [31:0] b4;
    wire [31:0] b5;
    wire [6:0] b6;
    wire  b7;
    wire  b8;
    wire  b9;
    wire [47:0] c1;
    wire  c2;
    wire [31:0] c3;
    
    
  FIFO #(.data_width(48),. depth(128)) dutFIFO(
  
    .clk(clk),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .rd_en(c2),
    .rd_data(c1), 
    .f_empty(b9),
    .f_full(f_full)
    );  
    
    encodec encodec_dut (
    .clk(clk),
    .f_empty(b9),              
    .i_Data_Frame(c1),
    . o_read_en(c2),   
    . i_read_data(c3),   
    . APB_ready(b3), 
    . o_addr(b4),       
    . o_data(b5),
    . o_slave_sel(b6),
    . write(b7),
    . valid(b8),
    . fifo_data_frame(fifo_data_frame),
    . fifo_w_en(fifo_w_en)
    );
    
    
    apb_master apbmaster (
    . pclk(clk),       
    . valid(b8),      
    . ext_psel(b6),   
    . ext_write(b7),  
    . ext_addr(b4),   
    . pready(d),     
    . slv_prdata(a3), 
    . slv_pwdata(b5), 
    . psel(a),  
    . penable(b),    
    . pwrite(c),     
    . pwdataa(a2),    
    . prdata(c3),     
    . paddr(a1),      
    . master_ready(b3) 
    );
    
    apb_slave apbslave (
    .pclk(clk),     
    .preset_n(preset_n), 
    .psel(a),     
    .penable(b),  
    .pwrite(c),   
    .paddr(a1),    
    .pwdata(a2),   
    .pwdata_out(a4),
    .prdata_out(a3),
    .dv(a5),       
    .pready(d)    
      );
    
    fifo2 #(. DWIDTH(32),. ADEPTH(7))  fifo2dut(
    .CLK(clk), 
    .RST(preset_n), 
    .WR_EN(a5),
    .DIN(a4), 
    .FULL(full),
    .RD_EN(a6),
    .DOUT(b1),
    .EMPTY(b2)
    
    );
    
    ctrl3 ctrl3dut (
     .clk(clk),     
     .rst_n(preset_n),   
     .empty(b2),   
     .data_read(b1),
     .donee(a7),   
     .read(a6),     
     .tx_data(a8), 
     .dv(a9)    
    );
    
    uarttx #(. CLKS_PER_BIT(87)) uarttxdut (
    .i_Clock(clk),     
    .i_Tx_DV(a9),     
    .i_Tx_Byte(a8),   
    .o_Tx_Active(o_tx_active), 
    .o_Tx_Serial(o_tx_serial), 
    .o_Tx_Done(a7)
     );  
    
endmodule
