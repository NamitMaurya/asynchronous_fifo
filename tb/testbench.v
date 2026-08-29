`timescale 1ns/1ps


module testbench ;

reg clk_w ;
reg clk_r ;
reg rst ;
reg rd_en ;
reg wr_en ;
reg [7:0]data_in ;
wire [7:0]data_out ;
wire full ;
wire empty ;

async_fifo#(
        .DEPTH(8),
        .DATA_WIDTH(8)
        )uut(
        .clk_w(clk_w),
        .clk_r(clk_r),
        .rst(rst),
        .rd_en(rd_en),
        .wr_en(wr_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
        ) ;
        
task write_fifo(input [7:0]data) ;
begin
    @(posedge clk_w) ;
    wr_en = 1 ;
    data_in = data ;
    @(posedge clk_w) ;
    wr_en = 0 ;
end
endtask

task read_fifo() ;
begin
    @(posedge clk_r) ;
    rd_en = 1 ;
    @(posedge clk_r) ;
    rd_en = 0 ;
    #1 ;
end
endtask

task verify_fifo(input [7:0]data) ;
begin
        if(data_out != data ) begin
                $display("ERROR: Not the expected value") ;
        end
        else begin
                $display("PASS: Expected value") ;
         end
end
endtask     
 
initial begin
        clk_w = 0;
        forever #5 clk_w = ~clk_w ;
 end 
 
initial begin
    clk_r = 0 ;
    forever #6.849315 clk_r = ~ clk_r ;
end


initial begin
        wr_en = 0;
        rd_en = 0 ;
        data_in = 0;
        rst = 1 ;
        
        repeat (5) @(posedge clk_r) ;
        
        rst = 0 ;
        
        repeat (2) @(posedge clk_r) ;
        //Write till full
        write_fifo(1) ;
        write_fifo(2) ;
        write_fifo(3) ;
        write_fifo(4) ;
        write_fifo(5) ;
        write_fifo(6) ;
        write_fifo(7) ;
        write_fifo(8) ;
        write_fifo(9) ;
        
        //Read and verify till empty
        read_fifo() ;
        verify_fifo(1) ;
        read_fifo() ;
        verify_fifo(2) ;
        read_fifo() ;
        verify_fifo(3) ;
        read_fifo() ;
        verify_fifo(4) ;
        read_fifo() ;
        verify_fifo(5) ;
        read_fifo() ;
        verify_fifo(6) ;
        read_fifo() ;
        verify_fifo(7) ;
        read_fifo() ;
        verify_fifo(8) ;
        read_fifo() ;
        
        //Wrap Around case
        write_fifo(1) ;
        write_fifo(2) ;
        write_fifo(3) ;
        write_fifo(4) ;
        write_fifo(5) ;
        read_fifo() ;
        verify_fifo(1) ;
        read_fifo() ;
        verify_fifo(2) ;
        write_fifo(6) ;
        write_fifo(7) ;
        write_fifo(8) ;
        write_fifo(9) ;
        write_fifo(10) ;
        
        //Since it is full, we try read+write ;
        read_fifo() ;
        write_fifo(11) ;
        
        //Empty the memory
        read_fifo() ;
        read_fifo() ;
        read_fifo() ;
        read_fifo() ;
        read_fifo() ;
        read_fifo() ;
        read_fifo() ;
        read_fifo() ;
        
        //Write while read when memory is empty 
        write_fifo(1) ;
        read_fifo() ;
        verify_fifo(10) ;

        @(posedge clk_r) ;
        rst = 1;
        
        
        $finish ;
end

initial begin
   //$monitor("t=%0t rst=%b rst_r=%b rst_w=%b wr_ptr_gray=%b rd_ptr_gray=%b wr_ptr_sync=%b rd_ptr_sync=%b full=%b empty=%b",
    //$time, rst, uut.rst_r, uut.rst_w, uut.wr_ptr_gray, uut.rd_ptr_gray, uut.wr_ptr_sync, uut.rd_ptr_sync, full, empty);
end
        
endmodule




