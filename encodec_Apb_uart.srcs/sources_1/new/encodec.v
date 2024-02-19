

module encodec(
    input clk,
               
    // Input from FIFO
    input f_empty,              
    input [47:0] i_Data_Frame,
    // Output for FIFO
    output o_read_en,   
    // Input from APB
    input [31:0] i_read_data,   
    input APB_ready, 
    //Output to APB        
    output [31:0] o_addr,       
    output [31:0] o_data,
    output [6:0] o_slave_sel,
    output write,
    output valid,
    
    // Encoded data
    output [47:0] fifo_data_frame,
    output fifo_w_en
    );
    
    reg r_valid;
    reg [7:0] length;
    reg r_write;
    reg [6:0] r_slave_sel;
    reg [31:0] r1_addr, r2_addr, r_data;
    reg [31:0] r_read_data;
    reg [47:0] r_data_frame;
    reg r_read_en = 0;
    reg [7:0] frame_count = 0;
    
    // Encoder registers
    reg [47:0] r_fifo_data_frame;
    reg r_fifo_w_en;
    
    reg r1_f_empty = 1, r2_f_empty = 1; 
    
    parameter IDLE = 4'b0000;
    parameter FIFO_READ = 4'b0001;
    parameter DATA_SAMPLE = 4'B0010;
    parameter DATA_DECODE = 4'b0011;
    parameter W_FIFO_READ = 4'b0100;
    parameter W_DATA_WRITE = 4'b0101;
    parameter W_ACK = 4'b0110;
    parameter R_FIFO_WRITE = 4'b0111;
    parameter R_ADDR = 4'b1000;
    parameter R_DATA_READ = 4'b1001;
    
    
    
    
    reg [4:0] state = 4'b0;
    
    
    always @(posedge clk)
    begin
        r1_f_empty <= f_empty;
        r2_f_empty <= r1_f_empty;
        case (state)
            IDLE:       begin // 0
                            length <= 0;
                            r_write <= 1'bx;
                            r_slave_sel <= 7'bx;
                            r1_addr <= 32'bx;
                            r2_addr <= 32'bx;
                            r_data <= 32'bx;
                            r_read_data <= 32'bx;
                            r_data_frame <= 48'bx;
                            r_read_en <= 0;
                            frame_count <= 8'b0;
                            r_valid <= 0;
                            r_fifo_w_en = 0;
                            r_fifo_data_frame = 48'bx;
                            
                            if(!r2_f_empty)
                            begin
                                state <= FIFO_READ;
                                r_read_en <= 1;
                            end
                            else
                                state <= IDLE;
                        end
                        
            FIFO_READ:      begin // 1
                            r_read_en <= 0;
                            r_valid <= 0;
                            r_fifo_w_en <= 0;
                            r_fifo_data_frame <= 48'bx;
                            state <= DATA_SAMPLE;
                        end
                    
            DATA_SAMPLE:    begin // 2
                                r_read_en <= 0;
                                r_valid <= 0;
                                r1_addr <= i_Data_Frame[31:0];
                                length <= i_Data_Frame[39:32];
                                r_slave_sel <= i_Data_Frame[46:40];
                                r_write <= i_Data_Frame[47];
                                state <= DATA_DECODE;
                            end
                            
                            
            DATA_DECODE:    begin // 3
                                if(r_write)
                                begin
                                    r_read_en <= 1;
                                    state <= W_FIFO_READ;
                                end
                                else
                                begin
                                    state <= R_FIFO_WRITE;
                                    r_read_en = 0;
                                end
                            end                
                            
            W_FIFO_READ:  begin // 4
                        r_read_en = 0;
                        state <= W_DATA_WRITE;
                    end                
                            
            W_DATA_WRITE:     begin //5
                                r_valid <= 1;
                                r2_addr <= r1_addr;
                                r_data <= i_Data_Frame[31:0];
                                r_read_en = 0;
                                r_valid <= 1;
                                state <= W_ACK;
                                frame_count <= frame_count + 1;
                            end
                            
            W_ACK:          begin //6
//                                r_read_en = 0;
                                if(APB_ready)
                                begin
                                    if(frame_count < length)
                                    begin
                                        r2_addr <= r1_addr;
                                        r1_addr <= r1_addr + 1;
                                        state <= W_FIFO_READ;
                                        r_read_en = 1;
                                        r_valid <= 0;
                                    end
                                    else
                                    begin
                                        frame_count <= 0;
                                        r1_addr <= r1_addr + 1;
    
                                        if(!r2_f_empty)
                                        begin
                                            state <= FIFO_READ;
                                            r_read_en <= 1;
                                            r_valid <= 0;
                                            r_data <= 32'bx;
                                            r2_addr <= 32'bx;
                                        end
                                        else
                                            state <= IDLE;
                                    end
                                end
                                else
                                    state <= W_ACK;
                            end
                            
            R_FIFO_WRITE:     begin // 7
                                r_fifo_w_en <= 1;
                                r_fifo_data_frame[31:0] <= r1_addr;
                                r_fifo_data_frame[39:32] <= length;
                                r_fifo_data_frame[46:40] <= r_slave_sel;
                                r_fifo_data_frame[47] <= 0;
                                state <= R_ADDR;
                            end
                            
                                         
            R_ADDR:      begin // 8
                                r_fifo_w_en <= 0;
                                r_fifo_data_frame <= 48'bx;
                                r_valid <= 1;
                                r2_addr <= r1_addr;
                                r_valid <= 1;
                                state <= R_DATA_READ;
                                frame_count <= frame_count + 1;                                
                            end
                            
            R_DATA_READ:          begin // 9
                                if(APB_ready)
                                begin
                                    if(frame_count < length)
                                    begin
                                        r1_addr <= r1_addr + 1;
                                        r_fifo_w_en = 1;
                                        r_fifo_data_frame[31:0] = i_read_data;
                                        r_fifo_data_frame[47:32] <= 16'h0000;
                                        state <= R_ADDR;
                                        r_valid <= 0;
                                        
                                    end
                                    else
                                    begin
                                        frame_count <= 0;
                                        r1_addr <= r1_addr + 1;
    
                                        if(!r2_f_empty)
                                        begin
                                            state <= FIFO_READ;
                                            r_read_en <= 1;
                                            r_valid <= 0;
                                            r_data <= 32'bx;
                                            r2_addr <= 32'bx;
                                        end
                                        else
                                            state <= IDLE;
                                    end
                                end
                                else
                                    state <= R_DATA_READ;
                            end
        endcase
    end
    
     
    assign o_read_en = r_read_en;
    assign o_slave_sel = r_slave_sel;
    assign o_data = r_data;
    assign o_addr = r2_addr;
    assign write = r_write;  
    assign valid = r_valid;
    assign fifo_data_frame = r_fifo_data_frame;
    assign fifo_w_en = r_fifo_w_en;
    
    
endmodule
