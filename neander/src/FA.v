`timescale 1ns/1ns

module FA(
  input wire x,
  input wire y,
  input wire carryin,
  output wire s,
  output wire carryout
);

xor #1 fa_s(s, x, y, carryin);

wire w_xy;
wire w_cy;
wire w_xc;
and #1 fa_carryout_part1(w_xy,x,y);
and #1 fa_carryout_part2(w_cy,carryin,y);
and #1 fa_carryout_part3(w_xc,x,carryin);

or #1 fa_carryout(carryout, w_xc,w_xy,w_cy);

endmodule
