import uvm_pkg::*;
import config_pkg::*;
`include "uvm_macros.svh"

module tbench_top #(parameter int CLK_PERIOD = 5);
    logic clk = 0;
    always 
    #(CLK_PERIOD) clk = ~clk;


    axi_lite_intf #(32, 32) vif (clk);
    axi_lite_slave #(32, 32) dut ( 
        .clk(clk), .reset(vif.reset),
        .aw_addr(vif.aw_addr), .aw_valid(vif.aw_valid), .aw_ready(vif.aw_ready),
        .w_data(vif.w_data), .w_strb(vif.w_strb), .w_valid(vif.w_valid), .w_ready(vif.w_ready),
        .b_resp(vif.b_resp), .b_valid(vif.b_valid), .b_ready(vif.b_ready),
        .ar_addr(vif.ar_addr), .ar_valid(vif.ar_valid), .ar_ready(vif.ar_ready),
        .r_data(vif.r_data), .r_resp(vif.r_resp), .r_valid(vif.r_valid), .r_ready(vif.r_ready),
        .pulse(vif.pulse) 
        );


    initial begin
        vif.reset = 1'b0;
        repeat (5) @(posedge clk);
        vif.reset = 1'b1;

    end


    initial begin
        uvm_config_db #(virtual axi_lite_intf)::set(null, "*", "vif", vif);
        run_test();
    end

    initial begin
        #20000000;  
        $display("TIMEOUT - forcing end");
        $finish;
    end
endmodule
