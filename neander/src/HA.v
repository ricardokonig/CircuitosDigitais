`timescale 1ns/1ns

module HA(
  input wire x,
  input wire y,
  output wire s,
  output wire carry
);

 xor #1 ha_sum(s, x, y);

 and #1 ha_carry(carry, x, y);


endmodule
