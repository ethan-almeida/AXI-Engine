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
