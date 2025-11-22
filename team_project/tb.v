`timescale 1ns / 1ps

module tb ();

    parameter US = 1000,MS = 1000000;

    reg clk, rst, btn_l;
    reg dht11_sensor_reg, dht11_sensor_enable;
    reg [39:0] dht11_sensor_data;
    wire [15:0] humidity,temperature;
    wire [4:0] led;
    wire dht_io;

    integer i;

    assign dht_io = (dht11_sensor_enable) ? dht11_sensor_reg : 1'bz;

    dht11_top UUT(
    .clk(clk),
    .rst(rst),
    .btn_l(btn_l),
    .dht_io(dht_io),
    //.humidity(humidity),
    //.temperature(temperature),
    .led(led)
);

    always #5 clk =~clk;

    initial begin
        #0;
        clk =0;
        rst = 1;
        dht11_sensor_enable = 0;
        btn_l = 0;
        dht11_sensor_reg = 0;
        i=0;
        dht11_sensor_data = 40'b10101010_00001111_11000110_00000000_01111111;
        #10;
        rst = 0;
        #10;
        btn_l =1;
        #20000;
        #10; btn_l =0;
        #(19*MS);
        #(30*US);
        dht11_sensor_enable =1;
        #(80*US);
        dht11_sensor_reg = 1;
        #(80*US);

        for (i =0 ;i<40 ;i=i+1 ) begin
            dht11_sensor_reg = 0 ;
            #(50*US);
            dht11_sensor_reg = 1;
            if (dht11_sensor_data[39-i]) begin
                #(70*US);
            end else begin
                #(28*US);
            end
        end
        dht11_sensor_reg = 0;
        #(50*US);
                dht11_sensor_enable =0;

        dht11_sensor_data = 0;
        
        #1000;
        $stop;

    end


endmodule

