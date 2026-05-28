import uvm_pkg::*;
import environment_pkg::*;
import sequence_pkg::*;
import config_pkg::*;

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


/*
 tests for basic functionality
- single write, then reads from said address

*/
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


/*
    tests for multiple writes
    - writes to multiple addresses and then read them back in different order

*/
class test_multiple_writes extends uvm_test;
    `uvm_component_utils(test_multiple_writes)

    environment env;
    write_multiple_seq w_seq;
    read_multiple_seq r_seq;

    function new(string name = "test_multiple_writes", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        env = environment::type_id::create("env", this);
        w_seq = write_multiple_seq::type_id::create("w_seq");
        r_seq = read_multiple_seq::type_id::create("r_seq");
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        w_seq.num_writes = MULTIPLE_WRITE_TRANS;
        w_seq.base_addr  = MULTIPLE_WRITE_BASE_ADDR;
        w_seq.start(env.w_seqr);
        
        r_seq.addr = new[MULTIPLE_WRITE_TRANS];
        foreach (r_seq.addr[i]) r_seq.addr[i] = $urandom_range(0, 15) * 4; //can change if needed
        r_seq.start(env.r_seqr);
        
        repeat(100) @(posedge env.w_mon.monitor.clk);
        phase.drop_objection(this);
    endtask
endclass