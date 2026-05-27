`include "uvm_macros.svh"
import uvm_pkg::*;

`uvm_analysis_imp_decl(_w)
`uvm_analysis_imp_decl(_r)
`uvm_analysis_imp_decl(_expected)

package config_pkg;

    parameter int DATA_WIDTH = 32;
    parameter int ADDR_WIDTH = 32;
    parameter int WRITE_SEQ_TRANS = 1;
    parameter int READ_SEQ_TRANS = 1;

endpackage