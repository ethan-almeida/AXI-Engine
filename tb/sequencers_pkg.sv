`include "uvm_macros.svh"

package sequencers_pkg;
    import uvm_pkg::*;
    import config_pkg::*;
    import transactions_pkg::*;

    `ifndef VERILATOR
    class write_sequencer extends uvm_sequencer #(write_trans);
    `else
    class write_sequencer extends uvm_sequencer #(write_trans, write_trans);
    `endif
        `uvm_component_utils(write_sequencer)

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

    endclass


    `ifndef VERILATOR
    class read_sequencer extends uvm_sequencer #(read_trans);
    `else
    class read_sequencer extends uvm_sequencer #(read_trans, read_trans);
    `endif
        `uvm_component_utils(read_sequencer)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

    endclass
endpackage