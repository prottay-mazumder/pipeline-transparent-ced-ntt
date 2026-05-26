`timescale 1ns / 1ps
module multiplier_unit #(
    parameter DATA_WIDTH = 7,
    parameter Q          = 97
)(
    input  wire [DATA_WIDTH-1:0] A,
    input  wire [DATA_WIDTH-1:0] B,
    output wire [DATA_WIDTH-1:0] out
);
    wire [2*DATA_WIDTH-1:0] product; 
    wire [34:0]             bk;
    wire [DATA_WIDTH:0]     bq;
    wire [DATA_WIDTH:0]     br;

    assign product = A * B;
    assign bk      = product * 15'd10810;
    assign bq      = bk[34:20];
    assign br      = product - bq * Q;
    assign out     = (br >= Q) ? (br - Q) : br[DATA_WIDTH-1:0];

endmodule