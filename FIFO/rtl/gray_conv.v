module gray_conv (
    input [5:0] bin_in,
    output [5:0] gray_out
);
    assign gray_out = bin_in ^ (bin_in >> 1);
endmodule