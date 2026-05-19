`include "uvm_macros.svh"

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
