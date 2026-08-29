`timescale 1ns/1ps
module two_flop_synchronizers#(
        parameter WIDTH = 5
        )(
        input clk,
        input rst,
        input [WIDTH-1:0]async_signal,
        output [WIDTH-1:0]data_out
        );

reg [WIDTH-1:0]sync_1 ;
reg [WIDTH-1:0]sync_2 ; 

always @(posedge clk or posedge rst) begin
    if(rst) begin
        sync_1 <= 0 ;
        sync_2 <= 0 ;
    end
    else begin
        sync_1 <= async_signal ;
        sync_2 <= sync_1 ;
    end
end

assign data_out = sync_2 ;

endmodule
