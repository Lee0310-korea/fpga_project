module dht11_top (
    input         clk,
    input         rst,
    input         btn_l,
    input         start,
    inout         dht_io,
    output [7:0] humidity_inc,
    output [7:0] humidity_dec,
    output [7:0] temperature_inc,
    output [7:0] temperature_dec,
    output [ 4:0] led,
    output start_send_32bit
);
    wire w_tick;

    dht11_control_unit U_dht11_cntl (
        .clk        (clk),
        .rst        (rst),
        .i_start    (btn_l||start),
        .i_tick     (w_tick),
        .o_valid    (led[4]),
        .humidity_inc(humidity_inc),
        .humidity_dec(humidity_dec),
        .temperature_inc(temperature_inc),
        .temperature_dec(temperature_dec),
        .led        (led[3:0]),
        .start_send_32bit(start_send_32bit),
        .dht_io     (dht_io)
    );

    tick_1us U_tick (
        .clk (clk),
        .rst (rst),
        .tick(w_tick)
    );

    
    
endmodule



module dht11_control_unit (
    input         clk,
    input         rst,
    input         i_start,
    input         i_tick,       // 1us ?��?�� tick ?��?��
    output        o_valid,
    output [7:0] humidity_inc,
    output [7:0] humidity_dec,
    output [7:0] temperature_inc,
    output [7:0] temperature_dec,
    output [3:0] led,
    output start_send_32bit,
    inout         dht_io
);

    // FSM ?��?�� ?��?��
    parameter [3:0] IDLE = 4'h0, START = 4'h1, WAIT = 4'h2, SYNC_L = 4'h3;
    parameter [3:0] SYNC_H = 4'h4, DATA_SYNC = 4'h5, DATA_DETECT = 4'h6;
    parameter [3:0] DATA_DECISION = 4'h7, STOP = 4'h8;

    wire [7:0]check_sum;
    reg [3:0] state_reg, state_next;
    reg [39:0] dht11_data_reg, dht11_data_next;
    reg [$clog2(19000)-1:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [5:0] bit_cnt_reg, bit_cnt_next;
    reg dht_io_enable_reg, dht_io_enable_next;
    reg dht_out_reg, dht_out_next;
    reg r_send,r_send_next;
    reg r_vaild, r_vaild_next;
    
    assign humidity_inc= dht11_data_reg[39:32];
    assign humidity_dec= dht11_data_reg[31:24];
    assign temperature_inc =  dht11_data_reg[23:16];
    assign temperature_dec = dht11_data_reg[15:8];
    assign check_sum = dht11_data_reg[7:0];
    assign dht_io = (dht_io_enable_reg) ? dht_out_reg : 1'bz;
    assign led = state_reg;
    assign o_valid = r_vaild;
    assign start_send_32bit = r_send;
    
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg         <= IDLE;
            dht11_data_reg    <= 40'h0000;
            b_tick_cnt_reg    <= 0;
            bit_cnt_reg       <= 0;
            dht_io_enable_reg <= 1'b1;
            dht_out_reg       <= 1'b1;
            r_vaild <= 0;
            r_send <=1'b0;
        end else begin
            state_reg         <= state_next;
            dht11_data_reg    <= dht11_data_next;
            b_tick_cnt_reg    <= b_tick_cnt_next;
            bit_cnt_reg       <= bit_cnt_next;
            dht_io_enable_reg <= dht_io_enable_next;
            dht_out_reg       <= dht_out_next;
            r_send <= r_send_next;
            r_vaild <= r_vaild_next;
        end
    end

    always @(*) begin
        state_next         = state_reg;
        dht11_data_next    = dht11_data_reg;
        b_tick_cnt_next    = b_tick_cnt_reg;
        bit_cnt_next       = bit_cnt_reg;
        dht_io_enable_next = dht_io_enable_reg;
        dht_out_next       = dht_out_reg;
        r_vaild_next = r_vaild;
        r_send_next = r_send;
        case (state_reg)
            IDLE: begin
                r_send_next = 1'b0;
                bit_cnt_next = 0;
                dht_out_next = 1'b1;
                if (i_start) begin
                    r_vaild_next = 1'b0;
                    dht_out_next = 1'b0;
                    state_next   = START;
                end
            end
            START: begin
                if (i_tick) begin
                    if (b_tick_cnt_reg == 19000) begin
                        dht_out_next = 1'b1;
                        b_tick_cnt_next = 0;
                        state_next = WAIT;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                if (i_tick) begin
                    if (b_tick_cnt_reg == 30) begin
                        b_tick_cnt_next = 0;
                        dht_io_enable_next = 0;  //fpga changed TX => RX
                        state_next = SYNC_L;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            SYNC_L: begin
                if (i_tick) begin
                    if (b_tick_cnt_reg > 30) begin
                        if (dht_io) begin
                            state_next = SYNC_H;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            SYNC_H: begin
                if (i_tick) begin
                    if (!dht_io) begin
                        state_next = DATA_SYNC;
                        bit_cnt_next = 0;
                    end
                end
            end
            DATA_SYNC: begin
                if (i_tick) begin
                    if (dht_io) begin
                        state_next = DATA_DETECT;
                        bit_cnt_next = bit_cnt_reg + 1;
                    end
                end
            end
            DATA_DETECT: begin
                if (i_tick) begin
                    if (!dht_io) begin
                        state_next = DATA_DECISION;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA_DECISION: begin
                if (b_tick_cnt_reg > 40) begin
                    dht11_data_next[40-bit_cnt_reg] = 1'b1;
                end else begin
                    dht11_data_next[40-bit_cnt_reg] = 1'b0;
                end
                b_tick_cnt_next = 0;
                if (bit_cnt_reg > 39) begin
                    state_next = STOP;
                end else begin
                    state_next = DATA_SYNC;

                end
            end
            STOP: begin
                if (i_tick) begin
                    if (b_tick_cnt_reg > 50) begin
                        dht_io_enable_next = 1;
                        r_send_next = 1'b1;
                        state_next = IDLE;
                        if (((dht11_data_reg[39:32] + dht11_data_reg[31:24] + dht11_data_reg[23:16] + dht11_data_reg[15:8]) & 8'hFF) == dht11_data_reg[7:0]) begin
                                r_vaild_next = 1'b1;
                        end  else begin
                                r_vaild_next = 1'b0;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule


module tick_1us (
    input  clk,
    input  rst,  // 리셋
    output tick  // 1us ?��?�� 출력
);

    parameter F_COUNT = 100_000_000 / 1000000;


    reg [$clog2(F_COUNT)-1:0] cnt;
    reg r_tick;

    assign tick = r_tick;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            r_tick <= 0;
        end else begin
            if (cnt == F_COUNT - 1) begin
                cnt <= 0;
                r_tick <= 1'b1;  // 1us ?��?�� ?��?��
            end else begin
                cnt <= cnt + 1;
                r_tick <= 1'b0;
            end
        end
    end

endmodule

