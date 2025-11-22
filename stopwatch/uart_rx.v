`timescale 1ns / 1ps


module uart_rx (
    input        clk,
    input        rst,
    input        rx,
    input        b_tick,
    output [7:0] rx_data,
    output       rx_done
);

    localparam [1:0] IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] state, next;
    reg [4:0] b_tick_count_reg, b_tick_count_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg rx_done_reg, rx_done_next;
    reg [7:0] rx_buf_reg, rx_buf_next;

    assign rx_done = rx_done_reg;
    assign rx_data = rx_buf_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            b_tick_count_reg <= 0;
            bit_count_reg <= 0;
            rx_done_reg <= 0;
            rx_buf_reg <= 0;
        end else begin
            state <= next;
            b_tick_count_reg <= b_tick_count_next;
            bit_count_reg <= bit_count_next;
            rx_done_reg <= rx_done_next;
            rx_buf_reg <= rx_buf_next;
        end
    end

    always @(*) begin
        next = state;
        b_tick_count_next = b_tick_count_reg;
        bit_count_next = bit_count_reg;
        rx_done_next = rx_done_reg;
        rx_buf_next = rx_buf_reg;
        case (state)
            IDLE: begin
                rx_done_next = 1'b0;
                if (b_tick) begin
                    if (rx == 1'b0) begin
                        b_tick_count_next = 0;
                        bit_count_next = 0;
                        next = START;
                    end 
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_count_reg == 23) begin
                        b_tick_count_next = 0;
                        next = DATA;
                    end else begin
                        b_tick_count_next = b_tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_count_reg == 0) begin
                        rx_buf_next[7] = rx;
                    end
                    if (b_tick_count_reg == 15) begin
                        if (bit_count_reg == 7) begin
                            next = STOP;
                        end else begin
                            b_tick_count_next = 0;
                            bit_count_next = bit_count_reg + 1;
                            rx_buf_next = rx_buf_reg >> 1;
                        end
                    end else begin
                        b_tick_count_next = b_tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick) begin
                    rx_done_next = 1'b1;
                    next = IDLE;
                end
            end
            default: next = IDLE;
        endcase
    end


endmodule
