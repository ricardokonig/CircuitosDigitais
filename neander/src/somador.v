`timescale 1ns/1ns

module somador(
  input wire [7:0]x,
  input wire [7:0]y,
  output wire [7:0]s
);
  wire [7:0]carry;
  HA g_init(.s(s[0]),.x(x[0]), .y(y[0]), .carry(carry[0]));
  FA b_fa1(.s(s[1]),.carryout(carry[1]), .x(x[1]), .y(y[1]), .carryin(carry[0]));
  FA b_fa2(.s(s[2]),.carryout(carry[2]), .x(x[2]), .y(y[2]), .carryin(carry[1]));
  FA b_fa3(.s(s[3]),.carryout(carry[3]), .x(x[3]), .y(y[3]), .carryin(carry[2]));
  FA b_fa4(.s(s[4]),.carryout(carry[4]), .x(x[4]), .y(y[4]), .carryin(carry[3]));
  FA b_fa5(.s(s[5]),.carryout(carry[5]), .x(x[5]), .y(y[5]), .carryin(carry[4]));
  FA b_fa6(.s(s[6]),.carryout(carry[6]), .x(x[6]), .y(y[6]), .carryin(carry[5]));
  FA b_fa7(.s(s[7]),.carryout(carry[7]), .x(x[7]), .y(y[7]), .carryin(carry[6]));
endmodule
