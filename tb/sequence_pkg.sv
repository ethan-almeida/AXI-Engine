`include "uvm_macros.svh"

package sequence_pkg;
    import uvm_pkg::*;
    import config_pkg::*;
    import transactions_pkg::*;


    // sequences for test_sanity
    class write_seq extends uvm_sequence #(write_trans);
        `uvm_object_utils(write_seq)
        logic [ADDR_WIDTH-1:0] start_addr = 0;
        function new(string name = "write_seq");
            super.new(name);
        endfunction
        virtual task body();
            logic [ADDR_WIDTH-1:0] addr = start_addr;
            repeat (WRITE_SEQ_TRANS) begin
                req = write_trans::type_id::create("req");
                start_item(req);
                req.addr = addr;
                req.data = $urandom();
                req.strb = 4'b1111;
                finish_item(req);
                addr = addr + 4;
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
                req = read_trans::type_id::create("req");
                start_item(req);
                req.addr = addr;
                finish_item(req);
                addr = addr + 4;
            end
        endtask
    endclass


    // sequences for test_multiple_writes
    class write_multiple_seq extends uvm_sequence #(write_trans);
        `uvm_object_utils(write_multiple_seq)

        int num_writes;
        bit [31:0] base_addr;

        function new(string name = "write_multiple_seq");
            super.new(name);
        endfunction

        virtual task body();
            write_trans wt;
            for (int i=0; i<num_writes; i++) begin
                wt = write_trans::type_id::create("wt");
                start_item(wt);

                wt.addr = base_addr + ($urandom_range(0, 15)*4); //can change if needed
                wt.data = $urandom();
                wt.strb = $urandom_range(0, 15);
                wt.resp = 2'b00;
                `uvm_info(get_type_name(), $sformatf("Write[%0d]: addr=0x%0h data=0x%0h strb=%b", i, wt.addr, wt.data, wt.strb), UVM_MEDIUM)
                finish_item(wt);
            end
        endtask
    endclass

    class read_multiple_seq extends uvm_sequence #(read_trans);
        `uvm_object_utils(read_multiple_seq)
        
        bit [ADDR_WIDTH-1:0] addr[];
        read_trans result[$];

        function new(string name = "read_multiple_seq");
            super.new(name);
        endfunction

        virtual task body();
            result.delete();
            for (int i=0; i<addr.size(); i++) begin
                req = read_trans::type_id::create("req");
                start_item(req);
                req.addr = addr[i];
                finish_item(req);
                result.push_back(req);
                 `uvm_info(get_type_name(), $sformatf("Read[%0d]: addr=0x%0h data=0x%0h resp=%b", i, req.addr, req.data, req.resp), UVM_MEDIUM)
            end    
        endtask
    endclass

endpackage