`include "uvm_macros.svh"

package transactions_pkg;
    import uvm_pkg::*;
    import config_pkg::*;


    class transaction_base extends uvm_sequence_item;
        `uvm_object_utils(transaction_base)
        rand logic [ADDR_WIDTH-1:0] addr;
        logic [1:0] resp;
        constraint align_addr {addr[1:0] == 2'b00};

        function new(string name = "transaction_base");
            super.new(name);
        endfunction

    endclass

    class write_trans extends transaction_base;
        `uvm_object_utils(write_trans)
        rand logic [DATA_WIDTH-1:0] data;
        rand logic [3:0] strb;

        constraint valid_strb { strb inside {4'b0001, 4'b0011, 4'b0111, 4'b1111}};

        function new(string name = "write_trans");
            super.new(name);
        endfunction
    endclass

    class read_trans extends transaction_base;
        `uvm_object_utils(read_trans)
        rand logic [DATA_WIDTH-1:0] data;
        
        function new(string name = "read_trans");
            super.new(name);
        endfunction

    endclass
endpackage
