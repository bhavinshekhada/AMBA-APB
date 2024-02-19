
module apb_slave(
    input                   pclk,
    input                   preset_n,      // Active low asynchronous reset
    input [6:0]             psel,          // Slave select
    input                   penable,       // Enable signal
    input                   pwrite,        // Write enable
    input wire[31:0]        paddr,         // Address
    input wire[31:0]        pwdata,        // Write data
    output wire [31:0]      pwdata_out,
    output wire [31:0]      prdata_out,
    output reg              dv,
    output reg              pready      // Ready output to the master
);
  reg [7:0] pready_counter = 8'b0; // Counter to track the number of times pready goes high in a transaction
  reg [1:0] s_state = 2'b00;     
  reg [31:0] data_latch;
  reg [31:0] temp;
  parameter IDLE  = 2'b00;
  parameter WRITE = 2'b01;
  parameter READ  = 2'b10;
  
  always @(posedge pclk or negedge preset_n) begin
    if (~preset_n) begin
      s_state <= IDLE;
      pready <= 1'b0;
    end else begin
      case (s_state)
        IDLE: begin
          dv <= 0;
          pready <= 0;
         // data_latch <= 0;
          if (penable && pwrite) begin
            s_state <= WRITE;
          end else if (penable && ~pwrite) begin
            s_state <= READ;
          end
        end

     

        WRITE: begin
            if ((psel[0]==1'b1) && (pready_counter == 0)) begin
                data_latch <= pwdata;  
                dv <= 1;
                pready <= 1'b1;
                s_state <= IDLE;
                pready_counter <= 1; // Increment pready_counter when pready goes high
            end else if (!psel || !penable || !pwrite) begin
                s_state <= IDLE;
                pready_counter <= 0; // Reset pready_counter if transaction aborted
            end else if (pready) begin
                pready_counter <= pready_counter + 1; // Increment pready_counter for each high pulse of pready
            end
        end

        READ: begin
         dv <= 1'b0;
          if (psel==7'bx1) begin
            temp <= data_latch;  
            pready <= 1'b1;
            s_state <= IDLE;
          end
        end

      endcase
    end
  end

  assign prdata_out = temp;
  assign pwdata_out = data_latch;
  
endmodule
