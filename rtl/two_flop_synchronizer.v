module two_flop_synchronizers(
        input clk_A,
        input clk_B,
        input rst,
        input async_signal,
        output data_out
        );

reg sync_1 ;
reg sync_2 ; 

always @(posedge clk_B) begin
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
