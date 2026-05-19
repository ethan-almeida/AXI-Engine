`include "uvm_macros.svh"

package environment_pkg;
    import uvm_pkg::*;
    import sequencers_pkg::*;
    import config_pkg::*;
    import transaction_pkg::*;

    // WRITE COMPONENTS

    class write_driver extends uvm_driver #(write_trans)
        `uvm_component_utils(write_driver)

        virtual axi_lite_intf.driver driver;
        uvm_analysis_port #(write_trans) analysis_port;

        function new(string name, uvm_component parent);
            super.new(name,parent);
            $display("driver started");
        endfunction

        function void build_phase(uvm_phase phase);
            analysis_port = new("analysis_port", this);
            super.build_phase(phase);
            assert(uvm_config_db #(config_dut)::get(this,"","dut_config",dut_config));
        endfunction

        task run_phase(uvm_phase phase);
            forever begin

                write_trans trans;
                seq_item_port.get_next_item(trans);
                
                // aw channel
                @(posedge driver.clk);
                driver.aw_addr <= trans.addr;
                driver.aw_valid <= 1'b1;
                while (!driver.aw_ready) @(posedge driver.clk);
                driver.aw_valid <= 1'b0;

                // w channel
                @(posedge driver.clk);
                driver.w_data  <= trans.data;
                driver.w_strb  <= trans.strb;
                driver.w_valid <= 1'b1;
                while (!driver.w_ready) @(posedge driver.clk);
                driver.w_valid <= 1'b0;

                // b channel
                driver.b_ready <= 1'b1;
                while (!driver.b_valid) @(posedge driver.clk);
                trans.resp = driver.b_resp;
                driver.b_ready <= 1'b0;
                `uvm_info(get_full_name(), $sformatf("Write: addr=0x%0h data=0x%0h strb=%b resp=%b", trans.addr, trans.data, trans.strb, trans.resp), UVM_LOW);
                analysis_port.write(trans);
                seq_item_port.item_done();
            end
        endtask
    endclass

    class write_monitor extends uvm_monitor;
        `uvm_component_utils(write_monitor)

        virtual axi_lite_intf.monitor monitor;
        uvm_analysis_port #(write_trans) analysis_port;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            analysis_port = new("analysis_port", this);
            super.build_phase(phase);
            if (!uvm_config_db #(virtual axi_lite_intf)::get(this, "", "vif", monitor))
                `uvm_fatal("NOVIF", "no vif found in config_db")
        endfunction

        task run_phase(uvm_phase phase);
            forever begin
                write_trans trans = write_trans::type_id::create("trans", this);
                @(posedge monitor.clk);
                while(!(monitor.aw_valid && monitor.aw_ready)) @(posedge monitor.clk);
                trans.addr = monitor.aw_addr;

                @(posedge monitor.clk);
                while (!(monitor.w_valid && monitor.w_ready)) @(posedge monitor.clk);
                trans.data = monitor.w_data;
                trans.strb = monitor.w_strb;

                @(posedge monitor.clk);
                while (!(monitor.b_valid && monitor.b_ready)) @(posedge monitor.clk);
                trans.resp = monitor.b_resp;

                `uvm_info(get_full_name(), $sformatf("Monitor: addr=0x%0h, data=0x%0h, strb=%b, resp=%b", trans.addr, trans.data, trans.strb, trans.resp), UVM_LOW);
                analysis_port.write(trans);
            end
        endtask
    endclass

    // READ COMPONENTS

    class read_monitor extends uvm_monitor;
    


    endclass




endpackage


