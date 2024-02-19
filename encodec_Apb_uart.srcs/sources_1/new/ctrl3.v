module ctrl3 (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  empty,
    input  wire [31:0]           data_read,  // 32-bit data read from FIFO
    input  wire                  donee,      // UART done signal
    output reg                  read,
    output reg [7:0]             tx_data,     // 8-bit data to be sent to UART TX
    output reg                      dv          // Data valid flag
);

    parameter IDLE_STATE = 2'b00;
    //parameter READ_STATE = 2'b01;
    parameter SEND_TO_UART_STATE = 2'b10;
    parameter DONE_STATE =2'b01;

    reg [2:0] state;
    reg [2:0] done_counter=0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE_STATE;
            done_counter <= 0;
            read <= 0;
            dv <= 0;
            tx_data <= 8'b0;
        end else begin
            case (state)
                IDLE_STATE: begin
                    read <= 0;
                    dv <= 0;
                    tx_data <= 8'b0;
                    if (!empty) begin
                        state <= SEND_TO_UART_STATE;
                        read <= 1;
                    end
                end
               
                SEND_TO_UART_STATE: begin
                    read <= 0;
                    if (done_counter==0)
                            begin
                                dv <= 1;
                                tx_data <= data_read[31:24];
                                state <=DONE_STATE;
                            end 
                       
                        
                            if (done_counter==1) begin
                                tx_data <= data_read[23:16];
                                dv <= 1;
                                state <=DONE_STATE;
                            end 
                      
                     
                            if (done_counter==2) begin
                                tx_data <= data_read[15:8];
                                dv <= 1;
                                state <=DONE_STATE;
                            end 
                        
                        
                            if (done_counter==3) begin
                                tx_data <= data_read[7:0];
                                dv <= 1;
                                state <=DONE_STATE;
                            end
                     if (donee) begin
                        done_counter <= done_counter + 1;
                    end
                    if (done_counter >= 4) begin
                        done_counter <= 0;
                        state <= IDLE_STATE;
                    end
                end
                DONE_STATE: begin
                            dv<=0; 
                            state <=SEND_TO_UART_STATE;
                         end     
            endcase
        end
    end
endmodule
