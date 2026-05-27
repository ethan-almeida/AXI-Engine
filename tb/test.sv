import uvm_pkg::*;
import environment_pkg::*;
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
        repeat(100) @(posedge env.w_mon.monitor.clk);
        phase.drop_objection(this);
    endtask

endclass