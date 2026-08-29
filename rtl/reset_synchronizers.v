`timescale 1ns/1ps
module reset_synchronizer (
    input  wire clk,
    input  wire rst_in,    
    output reg  rst_out    
);
    reg sync_1;

    always @(posedge clk or posedge rst_in) begin
        if (rst_in) begin
            sync_1  <= 1'b1;  
            rst_out <= 1'b1;
        end 
        else begin
            sync_1  <= 1'b0;  
            rst_out <= sync_1;
        end
    end
endmodule