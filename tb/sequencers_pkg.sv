`include "uvm_macros.svh"

package sequencers_pkg;
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