`timescale 1ns / 1ps

module uart_top (
    input clk,
    input rst,
    input rx,
    input start_send,
    input [11:0] i_send_data,
    input [7:0] humidity_inc,
    input [7:0] humidity_dec,
    input [7:0] temperature_inc,
    input [7:0] temperature_dec,
    input sw,
    output uart_start,
    output dht_start,
    output tx
);
    wire w_b_tick;
    wire w_start;
    wire rx_done;
    wire [7:0] w_rx_data, w_rx_fifo_popdata, w_tx_fifo_popdata, w_send_data;
    wire w_rx_empty, w_tx_fifo_full, w_tx_fifo_empty;
    wire w_tx_busy;
    wire send_push;

    baud_tick_gen u_BAUD_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)
    );

    uart_tx u_uart_tx (
        .clk(clk),
        .rst(rst),
        .start_trigger(~w_tx_fifo_empty),
        .tx_data(w_tx_fifo_popdata),
        .b_tick(w_b_tick),
        .tx(tx),
        .tx_busy(w_tx_busy)
    );

    fifo u_tx_FIFO (
        .clk(clk),
        .rst(rst),
        .push_data(w_send_data),
        .push(send_push),
        .pop(~w_tx_busy),
        .pop_data(w_tx_fifo_popdata),
        .full(w_tx_fifo_full),
        .empty(w_tx_fifo_empty)
    );

    uart_rx u_uart_rx (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(rx_done)
    );

    fifo u_rx_FIFO (
        .clk(clk),
        .rst(rst),
        .push_data(w_rx_data),
        .push(rx_done),
        .pop(~w_tx_fifo_full),
        .pop_data(w_rx_fifo_popdata),
        .full(),
        .empty(w_rx_empty)
    );

    command_cu u_command_cu (
        .clk(clk),
        .rst(rst),
        .rx_trigger(~w_rx_empty),
        .rx_fifo_data(w_rx_fifo_popdata),
        .start_uart(uart_start),
        .start_dht(dht_start)
    );

    sender_uart u_sender_uart (
        .clk(clk),
        .rst(rst),
        .start_send(start_send),
        .i_send_data(i_send_data),
        .sw(sw),
        .humidity_inc(humidity_inc),
        .humidity_dec(humidity_dec),
        .temperature_inc(temperature_inc),
        .temperature_dec(temperature_dec),
        .full(w_tx_fifo_full),
        .push(send_push),
        .tx_done(tx_done),
        .send_data(w_send_data)
    );


endmodule



module baud_tick_gen (
    input  clk,
    input  rst,
    output b_tick
);
    //baudrate
    parameter BAUDRATE = 9600 * 16;
    //State
    localparam BAUD_COUNT = 100_000_000 / BAUDRATE;
    reg [$clog2(BAUD_COUNT)-1:0] counter_reg, counter_next;
    reg tick_reg, tick_next;
    //SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_reg <= 0;
        end else begin
            counter_reg <= counter_next;
            tick_reg <= tick_next;
        end
    end
    //next CL
    always @(*) begin
        counter_next = counter_reg;
        tick_next = tick_reg;
        if (counter_reg == BAUD_COUNT - 1) begin
            counter_next = 0;
            tick_next = 1'b1;
        end else begin
            counter_next = counter_reg + 1;
            tick_next = 1'b0;
        end
    end

    assign b_tick = tick_reg;

endmodule


module command_cu (
    input clk,
    input rst,
    input rx_trigger,
    input [7:0] rx_fifo_data,
    output start_uart,
    output start_dht
);
    reg start_reg;
    reg start;

    assign start_uart = start_reg;
    assign start_dht  = start;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            start_reg <= 1'b0;
            start <= 1'b0;
        end else begin
            start_reg <= 1'b0;
            start <= 1'b0;
            if (rx_trigger) begin
                if (rx_fifo_data == 8'h52) begin
                    start_reg <= 1'b1;
                end else if (rx_fifo_data == 8'h73) begin
                    start <= 1'b1;
                end
            end
        end
    end

endmodule
