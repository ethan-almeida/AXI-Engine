`include "uvm_macros.svh"

package environment_pkg;
    import uvm_pkg::*;
    import sequencers_pkg::*;
    import config_pkg::*;
    import transactions_pkg::*;
    import reference_model_pkg::*;

    // WRITE COMPONENTS
    class write_driver extends uvm_driver #(write_trans);
        `uvm_component_utils(write_driver)

        virtual axi_lite_intf.driver driver;
        uvm_analysis_port #(write_trans) analysis_port;

        function new(string name, uvm_component parent);
            super.new(name,parent);
            $display("driver started");
        endfunction

        function void build_phase(uvm_phase phase);
            virtual axi_lite_intf tmp_vif;
            analysis_port = new("analysis_port", this);
            super.build_phase(phase);
            if (!uvm_config_db #(virtual axi_lite_intf)::get(this, "", "vif", tmp_vif))
                `uvm_fatal("NOVIF", "No vif found in config_db")
            driver = tmp_vif;
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
                @(posedge driver.clk);
                driver.aw_valid <= 1'b0;
                // w channel
                @(posedge driver.clk);
                driver.w_data  <= trans.data;
                driver.w_strb  <= trans.strb;
                driver.w_valid <= 1'b1;
                while (!driver.w_ready) @(posedge driver.clk);
                @(posedge driver.clk);
                driver.w_valid <= 1'b0;
                
                // b channel
                @(posedge driver.clk);
                driver.b_ready <= 1'b1;
                while (!driver.b_valid) @(posedge driver.clk);
                trans.resp = driver.b_resp;
                @(posedge driver.clk);
                driver.b_ready <= 1'b0;

                `uvm_info(get_full_name(), $sformatf("Write Driver: addr=0x%0h data=0x%0h strb=%b resp=%b", trans.addr, trans.data, trans.strb, trans.resp), UVM_LOW);
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
            virtual axi_lite_intf tmp_vif;
            analysis_port = new("analysis_port", this);
            super.build_phase(phase);
            if (!uvm_config_db #(virtual axi_lite_intf)::get(this, "", "vif", tmp_vif))
                `uvm_fatal("NOVIF", "no vif found in config_db")
            monitor = tmp_vif;
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
                `uvm_info(get_full_name(), $sformatf("Monitor-Write: addr=0x%0h, data=0x%0h, strb=%b, resp=%b", trans.addr, trans.data, trans.strb, trans.resp), UVM_LOW);
                analysis_port.write(trans);
            end
        endtask
    endclass

    // READ COMPONENTS
    class read_monitor extends uvm_monitor;
        `uvm_component_utils(read_monitor)

        virtual axi_lite_intf.monitor monitor;
        uvm_analysis_port #(read_trans) analysis_port;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            virtual axi_lite_intf tmp_vif;
            analysis_port = new("analysis_port", this);
            super.build_phase(phase);
            if (!uvm_config_db #(virtual axi_lite_intf)::get(this, "", "vif", tmp_vif))
                `uvm_fatal("NOVIF", "no vif found in config_db")
            monitor = tmp_vif;
        endfunction

        task run_phase(uvm_phase phase);
            forever begin
                read_trans trans = read_trans::type_id::create("trans", this);
                @(posedge monitor.clk);
                while (!(monitor.ar_valid && monitor.ar_ready)) @(posedge monitor.clk);
                trans.addr = monitor.ar_addr;
                @(posedge monitor.clk);
                while(!(monitor.r_valid && monitor.r_ready)) @(posedge monitor.clk);
                trans.data = monitor.r_data;
                trans.resp = monitor.r_resp;
                `uvm_info(get_full_name(), $sformatf("Monitor-Read: addr=0x%0h data=0x%0h resp=%b", trans.addr, trans.data, trans.resp), UVM_LOW);
                analysis_port.write(trans);
            end
        endtask
    endclass

    class read_driver extends uvm_driver #(read_trans);
        `uvm_component_utils(read_driver)

        virtual axi_lite_intf.driver driver;
        uvm_analysis_port #(read_trans) analysis_port;

        function new(string name, uvm_component parent);
            super.new(name,parent);
            $display("driver started");
        endfunction

        function void build_phase(uvm_phase phase);
            virtual axi_lite_intf tmp_vif;
            analysis_port = new("analysis_port", this);
            super.build_phase(phase);
            if (!uvm_config_db #(virtual axi_lite_intf)::get(this, "", "vif", tmp_vif))
                `uvm_fatal("NOVIF", "No vif found in config_db")
            driver = tmp_vif;
        endfunction

        task run_phase(uvm_phase phase);
            forever begin
                read_trans trans;
                seq_item_port.get_next_item(trans);
                
                // ar channel
                @(posedge driver.clk);
                driver.ar_addr <= trans.addr;
                driver.ar_valid <= 1'b1;
                while (!driver.ar_ready) @(posedge driver.clk);
                @(posedge driver.clk);   
                driver.ar_valid <= 1'b0;

                // r channel
                @(posedge driver.clk);
                driver.r_ready  <= 1'b1;
                while (!driver.r_valid) @(posedge driver.clk);
                trans.data = driver.r_data;
                trans.resp = driver.r_resp;
                @(posedge driver.clk);
                driver.r_ready <= 1'b0;

                `uvm_info(get_full_name(), $sformatf("Read Driver: addr=0x%0h data=0x%0h resp=%b", trans.addr, trans.data, trans.resp), UVM_LOW);
                analysis_port.write(trans);
                seq_item_port.item_done();
            end
        endtask
    endclass

    class scoreboard extends uvm_component;
        `uvm_component_utils(scoreboard)
        

        uvm_analysis_imp_w #(write_trans, scoreboard) write_imp;
        uvm_analysis_imp_r #(read_trans, scoreboard) read_imp;
        uvm_analysis_imp_expected #(read_trans, scoreboard) exp_imp;
        
        read_trans exp_queue[$];
        int write_pass_cnt = 0;
        int write_fail_cnt = 0;
        int read_match_cnt = 0;
        int read_mismatch_cnt = 0;
        
        // int match_cnt = 0;
        // int mismatch_cnt = 0;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            write_imp = new("write_imp", this);
            read_imp = new("read_imp", this);
            exp_imp = new("exp_imp", this);
        endfunction

        function void write_expected(read_trans t);
            exp_queue.push_back(t);
        endfunction

        function void write_w(write_trans t);
            if (t.resp == 2'b00) begin
                write_pass_cnt++;
                `uvm_info("Scoreboard", $sformatf("Write PASS: addr=0x%0h", t.addr), UVM_HIGH);
            end else begin
                write_fail_cnt++;
                `uvm_error("Scoreboard", $sformatf("Write FAIL: addr=0x%0h resp=%b", t.addr, t.resp));
            end
        endfunction

        function void write_r(read_trans t);
            if (exp_queue.size() == 0) begin
                `uvm_error("Scoreboard", "no expected data for comparing")
                return;
            end
            if (t.data == exp_queue[0].data && t.resp == exp_queue[0].resp) begin
                read_match_cnt++;
                `uvm_info("SCB", $sformatf("Read PASS: addr=0x%0h data=0x%0h", t.addr, t.data), UVM_HIGH)
            end
            else begin
                read_mismatch_cnt++;
                `uvm_error("SCB", $sformatf("Read FAIL: addr=0x%0h expected=0x%0h got=0x%0h resp=%b", t.addr, exp_queue[0].data, t.data, t.resp))
            end
            void'(exp_queue.pop_front());
        endfunction

        function void report_phase(uvm_phase phase);
            string msg;
            int total_writes = write_pass_cnt + write_fail_cnt;
            int total_reads = read_match_cnt + read_mismatch_cnt;
             msg = $sformatf("\nScoreboard Report\n  Writes : %0d (pass=%0d, fail=%0d)\n  Reads  : %0d (match=%0d, mismatch=%0d)\n==========================",
                    total_writes, write_pass_cnt, write_fail_cnt,
                    total_reads, read_match_cnt, read_mismatch_cnt);
            `uvm_info("SCB", msg, UVM_LOW)
        endfunction
    endclass

    class environment extends uvm_env;
        `uvm_component_utils(environment)

        write_sequencer w_seqr;
        read_sequencer r_seqr;
        write_driver w_drv;
        read_driver r_drv;
        write_monitor w_mon;
        read_monitor r_mon;
        scoreboard scb;
        reference_model ref_model;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            w_seqr = write_sequencer::type_id::create("w_seqr", this);
            w_drv  = write_driver::type_id::create("w_drv", this);
            w_mon  = write_monitor::type_id::create("w_mon", this);
            r_seqr = read_sequencer::type_id::create("r_seqr", this);
            r_drv  = read_driver::type_id::create("r_drv", this);
            r_mon  = read_monitor::type_id::create("r_mon", this);
            scb    = scoreboard::type_id::create("scb", this);
            ref_model = reference_model::type_id::create("ref_model", this); 
        endfunction

        function void connect_phase(uvm_phase phase);
            w_drv.seq_item_port.connect(w_seqr.seq_item_export);
            r_drv.seq_item_port.connect(r_seqr.seq_item_export);
            w_mon.analysis_port.connect(scb.write_imp);
            w_mon.analysis_port.connect(ref_model.write_imp);
            r_mon.analysis_port.connect(ref_model.read_imp);
            r_mon.analysis_port.connect(scb.read_imp);
            ref_model.expected_port.connect(scb.exp_imp);
        endfunction
    endclass

endpackage