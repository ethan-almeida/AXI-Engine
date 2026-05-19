interface axi_lite_intf #(DATA_WIDTH = 32, ADDR_WIDTH = 32)
(
    input logic clk
);

logic [ADDR_WIDTH-1:0] aw_addr;
logic aw_valid, aw_ready;

logic [DATA_WIDTH-1:0] w_data;
logic [3:0] w_strb;
logic w_valid, w_ready;

logic [1:0] b_resp;
logic b_valid, b_ready;

logic [ADDR_WIDTH-1:0] r_data;
logic [1:0] r_resp;
logic r_valid;
logic r_ready;

logic [ADDR_WIDTH-1:0] ar_addr;
logic                  ar_valid;
logic                  ar_ready;

logic reset, pulse;

modport driver (input clk, output aw_addr, aw_valid, 
                input aw_ready,
                output w_data, w_strb, w_valid, 
                input w_ready,
                input b_resp, b_valid, 
                output b_ready,
                output reset
                );

modport monitor (input clk, aw_addr, aw_valid, aw_ready, 
                 input ar_addr, ar_ready, ar_valid, 
                 input w_data, w_strb, w_valid, w_ready, 
                 input b_resp, b_valid, b_ready, 
                 input r_data, r_resp, r_valid, r_ready, 
                 input reset, pulse
                );


endinterface