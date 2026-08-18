module two_flop_synchronizers_tb ;

reg clk_A ;
reg clk_B ;
reg rst ;
wire data_out ;
reg async_signal ;

two_flop_synchronizers uut(
        .clk_A(clk_A),
        .clk_B(clk_B),
        .rst(rst),
        .async_signal(async_signal),
        .data_out(data_out)
        );

task verify_data(input val) ;
begin
    if(uut.sync_2!=val) begin
        $display("ERROR:INCORRECT OUTPUT") ;
    end
    else begin
        $display("PASS:EXPECTED OUTPUT") ;
    end
end
endtask

initial begin
    //CLOCK A IS 25 MHz
    clk_A = 0 ;
    forever #20 clk_A= ~clk_A ;
end

initial begin
    //CLOCK B ID 100 MHz
    clk_B = 0 ;
    forever #5 clk_B = ~clk_B ;
end

initial begin
    async_signal = 0;

    forever @(posedge clk_A) begin
        async_signal <= ~async_signal;
    end
end
        

initial begin
        rst=1 ;
        repeat(5) @(posedge clk_A) ;
        rst=0 ;
        
        repeat(2) @(posedge clk_B) ;
        
        verify_data(async_signal) ;
        
        @(posedge clk_A) ;
        
        verify_data(async_signal) ;
        
        @(posedge clk_A) ;
        
        verify_data(async_signal) ;
                
        rst = 1 ;
        
        $finish ;
end

endmodule