`timescale 1ns / 1ps

module tb_project_top;

    reg clk;
    reg rst;
    reg rx;
    reg Btn_L, Btn_R, Btn_U, Btn_D;
    reg [1:0] sel;

    wire tx;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

    project_top DUT (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .Btn_L(Btn_L),
        .Btn_R(Btn_R),
        .Btn_U(Btn_U),
        .Btn_D(Btn_D),
        .sel(sel),
        .tx(tx),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            rx <= 1'b0;
            #(104166);

            for (i = 0; i < 8; i = i + 1) begin
                rx <= data[i];
                #(104166);
            end

            rx <= 1'b1;
            #(104166);
        end
    endtask


    initial begin
        //  ʱ ȭ
        rx   = 1'b1;  // Idle     
        rst  = 1'b1;
        Btn_L = 0; Btn_R = 0; Btn_U = 0; Btn_D = 0;
        sel = 2'b00;
        #100;
        rst = 1'b0;
        #1000;
        send_uart_byte(8'h11);
         #200000;
        send_uart_byte(8'h11);
         #200000;send_uart_byte(8'h11);
         #200000;send_uart_byte(8'h11);
         #200000;send_uart_byte(8'h11);
         #200000;send_uart_byte(8'h11);
         #200000;send_uart_byte(8'h11);
         #200000;send_uart_byte(8'h11);
         #200000;send_uart_byte(8'h11);
         #200000;send_uart_byte(8'h11);
         #200000;send_uart_byte(8'h11);
         #200000;send_uart_byte(8'h11);
         #200000;send_uart_byte(8'h11);
         #200000;
            
        $stop;
    end

endmodule
