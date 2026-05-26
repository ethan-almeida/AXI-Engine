`include "uvm_macros.svh"

package generator_pkg;
    import uvm_pkg::*;
    import config_pkg::*;
    import transactions_pkg::*;

    class write_generator extends uvm_object;
        `uvm_object_utils(write_generator)

        mailbox #(write_trans) mbox;
        // int num_trans;

        function new(string name = "write_generator");
            super.new(name);
        endfunction

        virtual task run();
            logic [ADDR_WIDTH-1:0] addr = 0;
            repeat (WRITE_GEN_TRANS) begin
                write_trans trans = write_trans::type_id::create("trans");
                trans.addr = addr;
                trans.data = $urandom();
                trans.strb = 4'b1111;
                mbox.put(trans);
                addr = addr + 4;
            end
        endtask
    endclass


    class read_generator extends uvm_object;
        `uvm_object_utils(read_generator)

        mailbox #(read_trans) mbox;
        // int num_trans;

        function new(string name = "read_generator");
            super.new(name);
        endfunction

        virtual task run();
            logic [ADDR_WIDTH-1:0] addr = 0;
            repeat (READ_GEN_TRANS) begin
                read_trans trans = read_trans::type_id::create("trans");
                trans.addr = addr;
                mbox.put(trans);
                addr = addr + 4;
            end
        endtask
    endclass

endpackage