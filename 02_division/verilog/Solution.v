// Stream-based solution component
//
// Input stream interface:
//   i_ready (output): Assert when ready to accept input
//   i_valid (input): Asserted when input data is valid
//   i_payload_* (input): Input payload fields
//
// Output interface:
//   o_valid (output): Assert when output data is valid
//   o_payload* (output): Output payload fields
//
// Handshaking: Data transfers when both ready and valid are high

// In case anybody reads this. Well... I do not claim to be excellent at RTL. 
// I tend to work on tools that generate, synthesize, and/or analyze it most of the time.
// UNLINCENSED source code is here for ref.: https://github.com/JoGei/latchup-subs
// Driven by intuition, brute force, and lack of research into problems and literature. ¯\_(ツ)_/¯

///////////////////////////////////////////////////////////////////////////////////////////////////
// some sub modules...
module div_32bit (
  input  logic [31:0] i_dividend,
  input  logic [31:0] i_divisor,
  output logic [31:0] o_quotient,
  output logic [31:0] o_remainder,
  output logic        o_divide_by_zero
);
  
  always_comb begin
    if (i_divisor == 32'b0) begin
      o_quotient = 32'hFFFFFFFF;
      o_remainder = 32'hFFFFFFFF;
      o_divide_by_zero = 1'b1;
    end else begin
      o_quotient  = i_dividend / i_divisor;
      o_remainder = i_dividend % i_divisor;
      o_divide_by_zero = 1'b0;
    end
  end

endmodule

module udiv32_comb (
  input  logic [31:0] i_dividend,
  input  logic [31:0] i_divisor,
  output logic [31:0] o_quotient,
  output logic [31:0] o_remainder,
  output logic        o_divide_by_zero
);

  logic [32:0] rem [0:32];
  logic [31:0] quot;

  always_comb begin
    o_divide_by_zero = (i_divisor == 32'd0);
    o_quotient       = 32'd0;
    o_remainder      = 32'd0;
    quot           = 32'd0;

    for (int i = 0; i <= 32; i = i + 1)
      rem[i] = 33'd0;

    if (o_divide_by_zero) begin
      o_quotient  = 32'hFFFF_FFFF;
      o_remainder = 32'hFFFF_FFFF;
    end else begin
      for (int i = 0; i < 32; i = i + 1) begin
        if ({rem[i][31:0], i_dividend[31-i]} >= {1'b0, i_divisor}) begin
          rem[i+1]     = {rem[i][31:0], i_dividend[31-i]} - {1'b0, i_divisor};
          quot[31-i]   = 1'b1;
        end else begin
          rem[i+1]     = {rem[i][31:0], i_dividend[31-i]};
          quot[31-i]   = 1'b0;
        end
      end

      o_quotient  = quot;
      o_remainder = rem[32][31:0];
    end
  end

endmodule
// end of some sub modules.
///////////////////////////////////////////////////////////////////////////////////////////////////
// some synth control, e.g., change the solution type ...
//`define NATIVE
// end of some synth control
///////////////////////////////////////////////////////////////////////////////////////////////////

module Solution (
  input wire clk,
  input wire reset,
  output wire i_ready,
  input wire i_valid,
  input wire [32-1:0] i_payload_dividend,
  input wire [32-1:0] i_payload_divisor,
  output wire [32-1:0] o_payload_1,
  output wire [32-1:0] o_payload_2,
  output wire o_valid
);

// Define your design here
  assign i_ready = !reset;
  assign o_valid = i_valid;

`ifdef NATIVE
  div_32bit i_div(
`else
  udiv32_comb i_div(
`endif
      .i_dividend(i_payload_dividend)
    , .i_divisor(i_payload_divisor)
    , .o_quotient(o_payload_1)
    , .o_remainder(o_payload_2)
    , .o_divide_by_zero()
  );

endmodule
