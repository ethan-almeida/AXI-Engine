/**

This version of the testbench works on EDA Playground.
Was tested with Cadence XCelium w/ UVM 1.2

It includes the normal sequencer approach since Verilator w/ UVM 1800-2017 does not support sequences and sequencers just yet.

*/


`include "uvm_macros.svh"
import uvm_pkg::*;
`uvm_analysis_imp_decl(_w)
`uvm_analysis_imp_decl(_r)
`uvm_analysis_imp_decl(_expected)


/* PARAMETERS */
package config_pkg;

    parameter int DATA_WIDTH = 32;
    parameter int ADDR_WIDTH = 32;
    parameter int WRITE_SEQ_TRANS = 1;
    parameter int READ_SEQ_TRANS = 1;
    parameter int INITIAL_RESET_CYCLES = 5;
    parameter int TEST_SANITY_WAIT_CYCLES = 100;

endpackage


/* TRANSACTIONS */
package transactions_pkg;
    import uvm_pkg::*;
    import config_pkg::*;


    class transaction_base extends uvm_sequence_item;
        `uvm_object_utils(transaction_base)
        logic [ADDR_WIDTH-1:0] addr;
        logic [1:0] resp;

        function new(string name = "transaction_base");
            super.new(name);
        endfunction

    endclass

    class write_trans extends transaction_base;
        `uvm_object_utils(write_trans)
        logic [DATA_WIDTH-1:0] data;
        logic [3:0] strb;


        function new(string name = "write_trans");
            super.new(name);
        endfunction
    endclass

    class read_trans extends transaction_base;
        `uvm_object_utils(read_trans)
        logic [DATA_WIDTH-1:0] data;
        
        function new(string name = "read_trans");
            super.new(name);
        endfunction

    endclass
endpackage




/* SEQUENCERS */

package sequencer_pkg;
    import uvm_pkg::*;
    import config_pkg::*;
    import transactions_pkg::*;

    class write_sequencer extends uvm_sequencer #(write_trans);
        `uvm_component_utils(write_sequencer)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

    endclass


    class read_sequencer extends uvm_sequencer #(read_trans);
        `uvm_component_utils(read_sequencer)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

    endclass
endpackage


/* SEQUENCES */

package sequence_pkg;
    import uvm_pkg::*;
    import config_pkg::*;
    import transactions_pkg::*;

    class write_seq extends uvm_sequence #(write_trans);
        `uvm_object_utils(write_seq)

        logic [ADDR_WIDTH-1:0] start_addr = 0; //start at addr 0 
        function new(string name = "write_seq");
            super.new(name);
        endfunction

        virtual task body();
            logic [ADDR_WIDTH-1:0] addr = start_addr;
            repeat (WRITE_SEQ_TRANS) begin
                write_trans trans = write_trans::type_id::create("trans");
                start_item(trans);
                trans.addr = addr;  
                trans.data = $urandom();
                trans.strb = 4'b1111;
                finish_item(trans);
                addr = addr + 4; // go to addr+4 after each write
            end
        endtask
    endclass

    class read_seq extends uvm_sequence #(read_trans);
        `uvm_object_utils(read_seq)

        logic [ADDR_WIDTH-1:0] start_addr;
        

        function new(string name = "read_seq");
            super.new(name);
            start_addr = 0;
        endfunction

        virtual task body();
            logic [ADDR_WIDTH-1:0] addr = start_addr;
            repeat (READ_SEQ_TRANS) begin
                read_trans trans = read_trans::type_id::create("trans");
                start_item(trans);
                trans.addr = addr;
                finish_item(trans);
                addr = addr + 4;
            end
        endtask
    endclass
endpackage



/* DRIVERS (read and write), MONITORS (read and write) */

package environment_pkg;
    import uvm_pkg::*;
    import sequencer_pkg::*;
    import config_pkg::*;
    import transactions_pkg::*;

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
            driver.aw_addr = '0;
            driver.aw_valid = 1'b0;
            driver.w_data   = '0;
            driver.w_strb   = '0;
            driver.w_valid  = 1'b0;
            driver.b_ready  = 1'b0;
    
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
                driver.b_ready <= 1'b1;
                while (!driver.b_valid) @(posedge driver.clk);
                trans.resp = driver.b_resp;
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
                `uvm_fatal("NOVIF", "No vif found in config_db")
            monitor = tmp_vif;  
        endfunction

        task run_phase(uvm_phase phase);
            forever begin
                write_trans trans = write_trans::type_id::create("trans", this);
                do @(posedge monitor.clk);
                while(!(monitor.aw_valid && monitor.aw_ready));
                trans.addr = monitor.aw_addr;

                do @(posedge monitor.clk);
                while (!(monitor.w_valid && monitor.w_ready));
                trans.data = monitor.w_data;
                trans.strb = monitor.w_strb;

                do @(posedge monitor.clk);
                while (!(monitor.b_valid && monitor.b_ready));
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
                `uvm_fatal("NOVIF", "No vif found in config_db")
            monitor = tmp_vif;  
        endfunction

        task run_phase(uvm_phase phase);
            forever begin
                read_trans trans = read_trans::type_id::create("trans", this);

                do @(posedge monitor.clk);
                while (!(monitor.ar_valid && monitor.ar_ready));
                trans.addr = monitor.ar_addr;

                do @(posedge monitor.clk);
                while(!(monitor.r_valid && monitor.r_ready));
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
            driver.ar_addr = '0;
            driver.ar_valid = 1'b0;
            driver.r_ready = 1'b0;
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
                driver.r_ready <= 1'b0;

                `uvm_info(get_full_name(), $sformatf("Read Driver: addr=0x%0h data=0x%0h resp=%b", trans.addr, trans.data, trans.resp), UVM_LOW);
                analysis_port.write(trans);
                seq_item_port.item_done();
            end
        endtask
    endclass

endpackage



/* INTERFACE */

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

logic [DATA_WIDTH-1:0] r_data;
logic [1:0] r_resp;
logic r_valid;
logic r_ready;

logic [ADDR_WIDTH-1:0] ar_addr;
logic                  ar_valid;
logic                  ar_ready;

logic reset;
logic pulse;

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


endinterface



// IMPORTS FOR REFERENCE MODEL
import transactions_pkg::*;
import config_pkg::*;
import sequencer_pkg::*;
import uvm_pkg::*;


/* REFERENCE MODEL */

class reference_model extends uvm_component;
        `uvm_component_utils(reference_model)

        uvm_analysis_imp_w #(write_trans, reference_model) write_imp;
        uvm_analysis_imp_r #(read_trans, reference_model) read_imp;
        uvm_analysis_port #(read_trans) expected_port;

        logic [DATA_WIDTH-1:0] reference_mem [0:255];

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            write_imp = new("write_imp", this);
            read_imp  = new("read_imp", this);
            expected_port = new("expected_port", this);
        endfunction

        function void write_w(write_trans t);
            reference_mem[t.addr[7:0]] = t.data;
        endfunction

        function void write_r(read_trans t);
            read_trans expected; 
            expected = read_trans::type_id::create("expected", this); 
            expected.addr = t.addr;
            expected.data = reference_mem[t.addr[7:0]];
            expected.resp = 2'b00;
            expected_port.write(expected);
        endfunction
endclass


class scoreboard extends uvm_component;
        `uvm_component_utils(scoreboard)

        uvm_analysis_imp_w #(write_trans, scoreboard) write_imp;
        uvm_analysis_imp_r #(read_trans, scoreboard) read_imp;
        uvm_analysis_imp_expected #(read_trans, scoreboard) exp_imp;
        
        read_trans exp_queue[$];
        int write_cnt = 0;
        int read_cnt = 0;
        int match_cnt = 0;
        int mismatch_cnt = 0;

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
            write_cnt++;
            if (t.resp == 2'b00) begin
                match_cnt++;
                `uvm_info("Scoreboard", $sformatf("Write PASS: addr=0x%0h", t.addr), UVM_HIGH);
            end else begin
                mismatch_cnt++;
                `uvm_error("Scoreboard", $sformatf("Write FAIL: addr=0x%0h resp=%b", t.addr, t.resp));
            end
        endfunction

        function void write_r(read_trans t);
            read_cnt++;
            if (exp_queue.size() == 0) begin
                `uvm_error("Scoreboard", "no expected data for comparing")
                return;
            end

            if (t.data == exp_queue[0].data && t.resp == exp_queue[0].resp) begin
                match_cnt++;
                `uvm_info("SCB", $sformatf("Read PASS: addr=0x%0h data=0x%0h", t.addr, t.data), UVM_HIGH)
            end
            else begin
                mismatch_cnt++;
                `uvm_error("SCB", $sformatf("Read FAIL: addr=0x%0h expected=0x%0h got=0x%0h resp=%b", t.addr, exp_queue[0].data, t.data, t.resp))
            end
            void'(exp_queue.pop_front());
        endfunction

        function void report_phase(uvm_phase phase);
            string msg;
            msg = $sformatf("\nScoreboard Report\n  Writes    : %0d\n  Reads     : %0d\n  match_cnt   : %0d\n  Mismatch_cnt: %0d\n==========================",
                            write_cnt, read_cnt, match_cnt, mismatch_cnt);
            `uvm_info("SCB", msg, UVM_LOW)
        endfunction
endclass


// IMPORT FOR ENVIRONMENT CLASS
import environment_pkg::*;

/* ENVIRONMENT CLASS (not to be confused with the environment package) */
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



/* TESTS TO BE RUN */
import sequence_pkg::*;   
class my_test extends uvm_test;
    `uvm_component_utils(my_test)

    function new(string name = "my_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("MY_TEST", "if you see this, it works!!", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass



class test_sanity extends uvm_test;
    `uvm_component_utils(test_sanity)

    environment env;
    write_seq w_seq;
    read_seq r_seq;

    function new(string name = "test_sanity", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        env = environment::type_id::create("env", this);
        w_seq = write_seq::type_id::create("w_seq");
        r_seq = read_seq::type_id::create("r_seq");
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        w_seq.start(env.w_seqr);
        r_seq.start(env.r_seqr);
        repeat(TEST_SANITY_WAIT_CYCLES) @(posedge env.w_mon.monitor.clk);
        phase.drop_objection(this);
    endtask

endclass







/* TOP MODULE */
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
        repeat(INITIAL_RESET_CYCLES) @(posedge clk);
        vif.reset = 1'b1;
    end

    initial begin
        uvm_config_db #(virtual axi_lite_intf)::set(null, "*", "vif", vif);
        run_test();
    end
endmodule
