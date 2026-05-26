`include "uvm_macros.svh"

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