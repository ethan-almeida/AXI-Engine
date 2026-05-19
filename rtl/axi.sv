// axi-lite write states
typedef enum logic [2:0] {
    INITIAL_WRITE,
    SAVE_ADDR,
    SAVE_DATA,
    WRITE,
    RESP
} write_states;

// axi-lite read states
typedef enum logic [2:0] {
    INITIAL_READ,
    READ_ADDR,
    READ_DATA,
    READ_RESP
} read_states;

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
    // for b_resp -> 00: OKAY, 10: SLVERR, 11: DECERR, 01: EXOKAY 
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
 
write_states w_current_state, w_next_state;
logic [ADDR_WIDTH-1:0] addr_saved;
logic [DATA_WIDTH-1:0] data_saved;
logic [3:0] strb_saved;

read_states r_current_state,  r_next_state;
logic [ADDR_WIDTH-1:0] saved_araddr;

logic [DATA_WIDTH-1:0] mem [0:255];


// Write logic for AXI-Lite
always @ (posedge clk or negedge reset) begin
    if (!reset) begin
        w_current_state <= INITIAL_WRITE;
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
        w_current_state <= w_next_state;
        case (w_current_state)

            INITIAL_WRITE: begin
                aw_ready <= 1'b1;
                w_ready <= 1'b0;
                b_resp <= 2'b00;
                b_valid <= 1'b0;
                addr_saved <= {ADDR_WIDTH{1'b0}};
                data_saved <= {DATA_WIDTH{1'b0}};
                strb_saved <= 4'b0000;
                w_next_state <= SAVE_ADDR;
            end
            
            SAVE_ADDR: begin
                if (aw_valid && aw_ready) begin
                    addr_saved <= aw_addr;
                    aw_ready <= 1'b0;
                    w_ready <= 1'b1;
                    w_next_state <= SAVE_DATA;
                end
            end

            SAVE_DATA: begin
                if (w_valid && w_ready) begin
                    data_saved <= w_data;
                    strb_saved <= w_strb;
                    w_ready <= 1'b0;
                    w_next_state <= WRITE;
                end
            end

            WRITE: begin
                if (strb_saved[0]) mem[addr_saved[7:0]][0+:8]  <= data_saved[0+:8];
                if (strb_saved[1]) mem[addr_saved[7:0]][8+:8]  <= data_saved[8+:8];
                if (strb_saved[2]) mem[addr_saved[7:0]][16+:8] <= data_saved[16+:8];
                if (strb_saved[3]) mem[addr_saved[7:0]][24+:8] <= data_saved[24+:8];
                pulse <= (data_saved[0] == 1'b1) ? 1'b1 : 1'b0;
                b_resp <= 2'b00;
                b_valid <= 1'b1;
                w_next_state <= RESP;
            end

            RESP: begin
                pulse <= 1'b0; //should only last 1 clk cycle
                if (b_valid && b_ready) begin
                    b_valid <= 1'b0;
                    w_next_state <= INITIAL_WRITE;
                end
            end

            default: begin
                w_next_state <= INITIAL_WRITE;
            end
        endcase
    end
end


always @ (posedge clk or negedge reset) begin

    if (!reset) begin
        r_current_state <= INITIAL_READ;
        ar_ready <= 1'b0;
        r_valid <= 1'b0;
        r_resp <= 2'b00;
        r_data <= {DATA_WIDTH{1'b0}};
        saved_araddr <= {ADDR_WIDTH{1'b0}};
    end

    else begin
        r_current_state <= r_next_state;
        case (r_current_state)

            INITIAL_READ: begin
                ar_ready <= 1'b1;
                r_valid <= 1'b0;
                r_resp <= 2'b00;
                r_data <= {DATA_WIDTH{1'b0}};
                saved_araddr <= {ADDR_WIDTH{1'b0}};
                r_next_state <= READ_ADDR;
            end

            READ_ADDR: begin
                if (ar_valid && ar_ready) begin
                    saved_araddr <= ar_addr;
                    ar_ready <= 1'b1;
                    r_next_state <= READ_DATA;
                end
            end

            READ_DATA: begin
                r_data <= mem[saved_araddr[7:0]];
                r_resp <= 2'b00;
                r_valid <= 1'b1;
                r_next_state <= READ_RESP;
            end  

            READ_RESP: begin
                if (r_valid && r_ready) begin
                    r_valid <= 1'b0;
                    r_resp <= 2'b00;
                    r_next_state <= INITIAL_READ;
                end
            end

            default: begin
                r_next_state <= INITIAL_READ;
            end
        endcase
    end
end




endmodule



