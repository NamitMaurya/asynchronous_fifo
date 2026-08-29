`timescale 1ns/1ps
module async_fifo#(
        parameter DEPTH = 8,
        parameter DATA_WIDTH = 8
        )(
        input clk_w,
        input clk_r,
        input rst,
        input rd_en,
        input wr_en,
        input [DATA_WIDTH-1:0]data_in,
        output reg [DATA_WIDTH-1:0] data_out,
        output reg full,
        output reg empty
        );

wire read ;
wire write ;
wire full_next ;
wire empty_next ;
localparam ADDR_WIDTH = $clog2(DEPTH) ;
wire [ADDR_WIDTH:0]wr_ptr_gray_next ;
wire [ADDR_WIDTH:0]rd_ptr_gray_next ;
reg [DATA_WIDTH-1:0]memory[0:DEPTH-1];
wire rst_w, rst_r ;
reg [ADDR_WIDTH:0]wr_ptr_bn ;
reg [ADDR_WIDTH:0]rd_ptr_bn ;
reg [ADDR_WIDTH:0]wr_ptr_gray ;
reg [ADDR_WIDTH:0]rd_ptr_gray ;
wire[ADDR_WIDTH:0]wr_ptr_next ;
wire [ADDR_WIDTH:0]rd_ptr_next ;
wire [ADDR_WIDTH:0]wr_ptr_sync ;
wire [ADDR_WIDTH:0]rd_ptr_sync ;

assign wr_ptr_gray_next = wr_ptr_next ^ (wr_ptr_next>>1) ;
assign rd_ptr_gray_next = rd_ptr_next ^ (rd_ptr_next>>1) ;

assign full_next = ({~rd_ptr_sync[ADDR_WIDTH:ADDR_WIDTH-1] , rd_ptr_sync[ADDR_WIDTH-2:0]} == wr_ptr_gray_next) ;
assign empty_next = (rd_ptr_gray_next == wr_ptr_sync) ;

assign wr_ptr_next = wr_ptr_bn + write ;
assign rd_ptr_next = rd_ptr_bn + read ;

assign write = (wr_en && !full) ;
assign read =  (rd_en && !empty) ;

reset_synchronizer uut_rst_rd(
        .clk(clk_r),
        .rst_in(rst),
        .rst_out(rst_r)
        );
        
reset_synchronizer uut_rst_wr(
        .clk(clk_w),
        .rst_in(rst),
        .rst_out(rst_w)
        );        
two_flop_synchronizers#(
        .WIDTH(ADDR_WIDTH +1 )
        )uut_wr_sync(
        .async_signal(wr_ptr_gray),
        .clk(clk_r),
        .rst(rst_r),
        .data_out(wr_ptr_sync)
        );
        
two_flop_synchronizers#(
        .WIDTH(ADDR_WIDTH + 1)
        )uut_rd_sync(
        .async_signal(rd_ptr_gray),
        .clk(clk_w),
        .rst(rst_w),
        .data_out(rd_ptr_sync)
        );
        
        
always @(posedge clk_w or posedge rst_w) begin
        if(rst_w) begin
            full <= 0 ;
            wr_ptr_bn <= 0 ;
            wr_ptr_gray <= 0 ;
       end
       else begin
            wr_ptr_bn <= wr_ptr_next ;
                    full <= full_next ;
            wr_ptr_gray <= wr_ptr_gray_next ;
            if(write) begin
                    memory[wr_ptr_bn[ADDR_WIDTH-1:0]] <= data_in ;
            end
       end
end

always @(posedge clk_r or posedge rst_r) begin
        if(rst_r) begin
                empty<= 1;
                rd_ptr_bn <= 0;
                data_out <= 0 ;
                rd_ptr_gray <= 0 ;
         end
         else begin
                empty <= empty_next ;
                rd_ptr_bn <= rd_ptr_next ;
                rd_ptr_gray <= rd_ptr_gray_next ;
                if(read) begin
                        data_out <= memory[rd_ptr_bn[ADDR_WIDTH-1:0]] ;
                end
         end
end
endmodule

            



