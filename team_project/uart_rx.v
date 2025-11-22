`timescale 1ns / 1ps

module uart_rx (
    input        clk,
    input        rst,
    input        rx,
    input        b_tick,
    output [7:0] rx_data,
    output       rx_done
);

    localparam [1:0] IDLE = 2'h0, START = 2'h1, DATA = 2'h2, STOP = 2'h3;
    reg [1:0] cur_state, next_state;
    //bit count
    reg [2:0] bit_cnt, bit_cnt_next;
    //tick_count
    reg [4:0] b_tick_cnt, b_tick_cnt_next;
    reg rx_done_reg, rx_done_next;
    //rx_internal buffer
    reg [7:0] rx_buf_reg, rx_buf_next;

    assign rx_data = rx_buf_reg;
    assign rx_done = rx_done_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            cur_state   <= IDLE;
            bit_cnt     <= 0;
            b_tick_cnt  <= 0;
            rx_done_reg <= 0;
            rx_buf_reg  <= 0;
        end else begin
            cur_state   <= next_state;
            bit_cnt     <= bit_cnt_next;
            b_tick_cnt  <= b_tick_cnt_next;
            rx_done_reg <= rx_done_next;
            rx_buf_reg  <= rx_buf_next;
        end
    end

    always @(*) begin
        next_state      = cur_state;
        bit_cnt_next    = bit_cnt;
        b_tick_cnt_next = b_tick_cnt;
        rx_done_next    = rx_done_reg;
        rx_buf_next     = rx_buf_reg;
        case (cur_state)
            IDLE: begin
                // bit_cnt_next = 0;
                // b_tick_cnt_next = 0;
                rx_done_next = 1'b0;
                if (b_tick) begin
                    if (rx == 0) begin
                        next_state = START;
                        b_tick_cnt_next = 0;
                    end
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt == 23) begin
                        next_state = DATA;
                        bit_cnt_next = 0;
                        b_tick_cnt_next = 0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick == 1) begin
                    if (b_tick_cnt == 0) begin
                        rx_buf_next[7] = rx;
                    end
                    if (b_tick_cnt == 15) begin
                        if (bit_cnt == 7) begin
                            next_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt + 1;
                            b_tick_cnt_next = 0;
                            rx_buf_next = rx_buf_reg >> 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick == 1) begin
                    rx_done_next = 1'b1;
                    next_state   = IDLE;
                end
            end
        endcase
    end
endmodule


