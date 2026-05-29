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
                output ar_addr, ar_valid,
                input ar_ready, r_data, r_resp, r_valid,
                output r_ready,
                output reset
                );

modport monitor (input clk, aw_addr, aw_valid, aw_ready, 
                 input ar_addr, ar_ready, ar_valid, 
                 input w_data, w_strb, w_valid, w_ready, 
                 input b_resp, b_valid, b_ready, 
                 input r_data, r_resp, r_valid, r_ready, 
                 input reset, pulse
                );

/* Assertions */
b_valid_hold: assert property (@(posedge clk) disable iff (!reset)
    $rose(b_valid) |=> b_valid until b_ready);

r_valid_hold: assert property (@(posedge clk) disable iff (!reset)
    $rose(r_valid) |=> r_valid until r_ready);

b_resp_okay: assert property (@(posedge clk) disable iff (!reset)
    b_valid |-> b_resp == 2'b00);

r_resp_okay: assert property (@(posedge clk) disable iff (!reset)
    r_valid |-> r_resp == 2'b00);

aw_aligned: assert property (@(posedge clk) disable iff (!reset)
    aw_valid |-> aw_addr[1:0] == 2'b00);

ar_aligned: assert property (@(posedge clk) disable iff (!reset)
    ar_valid |-> ar_addr[1:0] == 2'b00);

aw_ready_within: assert property (@(posedge clk) disable iff (!reset)
    $rose(aw_valid) |-> ##[1:20] aw_ready);

w_ready_within: assert property (@(posedge clk) disable iff (!reset)
    $rose(w_valid) |-> ##[1:5000] w_ready);

ar_ready_within: assert property (@(posedge clk) disable iff (!reset)
    $rose(ar_valid) |-> ##[1:20] ar_ready);

b_handshake_complete: assert property (@(posedge clk) disable iff (!reset)
    $rose(b_valid) |-> ##[1:200] b_ready);

r_handshake_complete: assert property (@(posedge clk) disable iff (!reset)
    $rose(r_valid) |-> ##[1:200] r_ready);

w_strb_valid: assert property (@(posedge clk) disable iff (!reset)
    w_valid |-> !$isunknown(w_strb));

aw_addr_valid: assert property (@(posedge clk) disable iff (!reset)
    aw_valid |-> !$isunknown(aw_addr));

ar_addr_valid: assert property (@(posedge clk) disable iff (!reset)
    ar_valid |-> !$isunknown(ar_addr));




/* Cover Points */

// write addr
aw_addr_low:       cover property (@(posedge clk) disable iff (!reset) aw_valid && aw_addr[7:0] inside {[0:63]});
aw_addr_mid_low:   cover property (@(posedge clk) disable iff (!reset) aw_valid && aw_addr[7:0] inside {[64:127]});
aw_addr_mid_high:  cover property (@(posedge clk) disable iff (!reset) aw_valid && aw_addr[7:0] inside {[128:191]});
aw_addr_high:      cover property (@(posedge clk) disable iff (!reset) aw_valid && aw_addr[7:0] inside {[192:255]});

// write data
w_data_zero:       cover property (@(posedge clk) disable iff (!reset) w_valid && w_data == 32'h0);
w_data_allones:    cover property (@(posedge clk) disable iff (!reset) w_valid && w_data == 32'hFFFF_FFFF);
w_strb_all:        cover property (@(posedge clk) disable iff (!reset) w_valid && w_strb == 4'b1111);
w_strb_single:     cover property (@(posedge clk) disable iff (!reset) w_valid && ($onehot(w_strb) || w_strb == 4'b0000));

// write resp
b_resp_is_okay:    cover property (@(posedge clk) disable iff (!reset) b_valid && b_resp == 2'b00);
b_handshake:       cover property (@(posedge clk) disable iff (!reset) b_valid && b_ready);
b_valid_rose:      cover property (@(posedge clk) disable iff (!reset) $rose(b_valid));
b_okay_x_pulse:    cover property (@(posedge clk) disable iff (!reset) b_valid && b_resp == 2'b00 && pulse);

// read addr
ar_addr_low:       cover property (@(posedge clk) disable iff (!reset) ar_valid && ar_addr[7:0] inside {[0:63]});
ar_addr_mid_low:   cover property (@(posedge clk) disable iff (!reset) ar_valid && ar_addr[7:0] inside {[64:127]});
ar_addr_mid_high:  cover property (@(posedge clk) disable iff (!reset) ar_valid && ar_addr[7:0] inside {[128:191]});
ar_addr_high:      cover property (@(posedge clk) disable iff (!reset) ar_valid && ar_addr[7:0] inside {[192:255]});

// read data
r_data_zero:       cover property (@(posedge clk) disable iff (!reset) r_valid && r_data == 32'h0);
r_data_allones:    cover property (@(posedge clk) disable iff (!reset) r_valid && r_data == 32'hFFFF_FFFF);
r_handshake:       cover property (@(posedge clk) disable iff (!reset) r_valid && r_ready);
r_okay_x_zero:     cover property (@(posedge clk) disable iff (!reset) r_valid && r_resp == 2'b00 && r_data == 32'h0);


endinterface