`include "uvm_macros.svh"

package reference_model_pkg;
    import uvm_pkg::*;
    // import sequencers_pkg::*;
    import config_pkg::*;
    import transactions_pkg::*;

    class reference_model extends uvm_component;
        `uvm_component_utils(reference_model)

        uvm_analysis_imp_w #(write_trans, reference_model) write_imp;
        uvm_analysis_imp_r #(read_trans, reference_model) read_imp;
        uvm_analysis_port #(read_trans) expected_port;

        logic [DATA_WIDTH-1:0] reference_mem [0:255];

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            write_imp = new("write_imp", this);
            read_imp  = new("read_imp", this);
            expected_port = new("expected_port", this);
        endfunction

        function void write_w(write_trans t);
            // reference_mem[t.addr[7:0]] = t.data;
            if (t.strb[0]) 
                reference_mem[t.addr[7:0]][0+:8]  = t.data[0+:8];
            if (t.strb[1]) 
                reference_mem[t.addr[7:0]][8+:8]  = t.data[8+:8];
            if (t.strb[2]) 
                reference_mem[t.addr[7:0]][16+:8] = t.data[16+:8];
            if (t.strb[3]) 
                reference_mem[t.addr[7:0]][24+:8] = t.data[24+:8];
        endfunction

        function void write_r(read_trans t);
            read_trans expected; 
            expected = read_trans::type_id::create("expected", this); 
            expected.addr = t.addr;
            expected.data = reference_mem[t.addr[7:0]];
            expected.resp = 2'b00;
            expected_port.write(expected);
        endfunction
    endclass

endpackage