`timescale 1ns / 1ps

module fnd_selecter(
    input clk,
    input rst,
    input sw,
    input [3:0]fnd_com,
    input [3:0]fnd_com_32bit,
    input [7:0]fnd_data,
    input [7:0]fnd_data_32bit,
    output [3:0] o_fnd_com,
    output [7:0] o_fnd_data
    );
    
    reg [3:0] r_com,r_com_next;
    reg [7:0]r_data,r_data_next;
    
    assign o_fnd_data= r_data;
    assign o_fnd_com = r_com;
    
    always @ (posedge clk, posedge rst) begin
        if(rst)begin
            r_com <= 0;
            r_data <= 0; 
        end else begin
            r_com <= r_com_next;
            r_data <= r_data_next;
        end
    end
    
    always @ (*) begin
        r_data_next = r_data;
        r_com_next = r_com;
        case(sw)
            1'b0: begin
                r_com_next = fnd_com;
                r_data_next= fnd_data;
            end
            1'b1: begin
                r_com_next = fnd_com_32bit;
                r_data_next= fnd_data_32bit;
            end
        endcase
    end
    
    
    
endmodule
