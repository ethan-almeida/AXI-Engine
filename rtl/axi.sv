// main states
// typedef enum logic [1:0] { 
//     INITIAL_STATE,
//     WRITE_ADDR,
//     WRITE_RESP,
//     WRITE_DATA,
//     READ_DATA,
//     READ_ADDR
// } states;

// axi-lite write states
typedef enum logic [2:0] {
    INITIAL_WRITE,
    SAVE_ADDR,
    SAVE_DATA,
    WRITE,
    RESP
} write_states;

module axi_lite_slave #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32)
(

    input logic clk, reset,
    
    // write address channel's signals
    input logic [ADDR_WIDTH-1:0] aw_addr,
    input logic aw_valid, 
    output logic aw_ready,

    // write data channel's signals
    input logic [DATA_WIDTH-1:0] w_data, 
    input logic [3:0] w_strb,
    input logic w_valid,
    output logic w_ready,

    // write response channel's signals
    // for b_resp -> 00: OKAY, 10: SLVERR, 11: DECERR, 01: EXOKAY (not supported in AXI-Lite)
    output logic [1:0] b_resp,
    output logic b_valid,
    input logic b_ready,

    // read address channel's signals
    input logic [ADDR_WIDTH-1:0] ar_addr,
    input logic ar_valid,
    output logic ar_ready,

    // read data channel's signals
    output logic [DATA_WIDTH-1:0] r_data,
    output logic [1:0] r_resp,
    output logic r_valid,
    input logic r_ready,

    output reg pulse
);
 
write_states current_state, next_state;
logic [ADDR_WIDTH-1:0] addr_saved;
logic [DATA_WIDTH-1:0] data_saved;
logic [3:0] strb_saved;


// GOLDEN RULE

// if (valid && ready) begin
//     //transfer, data moves
// end else begin
//     // no transfer, keep current values

// end

// valid and ready are both independent


// Write logic for AXI-Lite
always @ (posedge clk or negedge reset) begin
    if (!reset) begin
        current_state <= INITIAL_WRITE;
        addr_saved <= {ADDR_WIDTH{1'b0}};
        data_saved <= {DATA_WIDTH{1'b0}};
        strb_saved <= 4'b0000;
        aw_ready <= 1'b0;
        w_ready <= 1'b0;
        b_resp <= 2'b00;
        b_valid <= 1'b0;
        pulse <= 1'b0;
    end 
    else begin
        current_state <= next_state;
        case (current_state)

            INITIAL_WRITE: begin
                aw_ready <= 1'b1;
                w_ready <= 1'b0;
                b_resp <= 2'b00;
                b_valid <= 1'b0;
                addr_saved <= {ADDR_WIDTH{1'b0}};
                data_saved <= {DATA_WIDTH{1'b0}};
                strb_saved <= 4'b0000;
                next_state <= SAVE_ADDR;
            end
            
            SAVE_ADDR: begin
                if (aw_valid && aw_ready) begin
                    addr_saved <= aw_addr;
                    aw_ready <= 1'b0;
                    w_ready <= 1'b1;
                    next_state <= SAVE_DATA;
                end
            end

            SAVE_DATA: begin
                if (w_valid && w_ready) begin
                    data_saved <= w_data;
                    strb_saved <= w_strb;
                    w_ready <= 1'b0;
                    next_state <= WRITE;
                end
            end

            WRITE: begin
                if (addr_saved == aw_addr && data_saved[0] == 1'b1) begin
                    pulse <= 1'b1;
                end 
                else begin
                    pulse <= 1'b0;
                end

                b_resp <= 2'b00;
                b_valid <= 1'b1;
                next_state <= RESP;

            end

            RESP: begin
                pulse <= 1'b0; //should only last 1 clk cycle
                if (b_valid && b_ready) begin
                    b_valid <= 1'b0;
                    next_state <= INITIAL_WRITE;
                end
            end

            default: begin
                next_state <= INITIAL_WRITE;
            end
        endcase
    end
end







endmodule



