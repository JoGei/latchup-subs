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

`define PIPELINED // current solution

`ifdef PIPELINED
module mul16_pipe_stage (
  input  logic        clk,
  input  logic        reset,
  input  logic        i_valid,
  input  logic [31:0] i_multiplicand,
  input  logic [15:0] i_multiplier,
  input  logic [31:0] i_acc,
  output logic        o_valid,
  output logic [31:0] o_multiplicand,
  output logic [15:0] o_multiplier,
  output logic [31:0] o_acc
);

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      o_valid        <= 1'b0;
      o_multiplicand <= 32'd0;
      o_multiplier   <= 16'd0;
      o_acc          <= 32'd0;
    end else begin
      o_valid <= i_valid;

      if (i_valid) begin
        o_acc          <= i_multiplier[0] ? (i_acc + i_multiplicand) : i_acc;
        o_multiplicand <= i_multiplicand << 1;
        o_multiplier   <= i_multiplier >> 1;
      end else begin
        o_multiplicand <= 32'd0;
        o_multiplier   <= 16'd0;
        o_acc          <= 32'd0;
      end
    end
  end

endmodule

module mul16_pipe (
  input  logic        clk,
  input  logic        reset,
  output logic        o_ready,
  input  logic        i_valid,
  input  logic [15:0] i_payload_a,
  input  logic [15:0] i_payload_b,
  output logic [31:0] o_payload,
  output logic        o_valid
);

  logic        valid_s        [0:15];
  logic [31:0] multiplicand_s [0:15];
  logic [15:0] multiplier_s   [0:15];
  logic [31:0] acc_s          [0:15];

  assign o_ready = 1'b1;

  assign valid_s[0]        = i_valid;
  assign multiplicand_s[0] = {16'd0, i_payload_a};
  assign multiplier_s[0]   = i_payload_b;
  assign acc_s[0]          = 32'd0;

  genvar g;
  generate
    for (g = 0; g < 16; g = g + 1) begin : GEN_MUL_STAGE
      mul16_pipe_stage u_stage (
          .clk(clk),
        , .reset(reset)
        , .i_valid(valid_s[g])
        , .i_multiplicand(multiplicand_s[g])
        , .i_multiplier(multiplier_s[g])
        , .i_acc(acc_s[g])
        , .o_valid(valid_s[g+1])
        , .o_multiplicand(multiplicand_s[g+1])
        , .o_multiplier(multiplier_s[g+1])
        , .o_acc(acc_s[g+1])
      );
    end
  endgenerate

  assign o_valid   = valid_s[16];
  assign o_payload = acc_s[16];

endmodule

`else // `ifdef PIPELINED -> i.e. not pipelined

module mul16_comb (
  input  logic [15:0] i_multiplicand,
  input  logic [15:0] i_multiplier,
  output logic [31:0] o_product
);
  always_comb begin
    o_product = i_multiplicand * i_multiplier; // native SV mul* allowed. Synths more efficiently. Todo: What is latchup synth using?
  end
endmodule

`endif // `ifdef PIPELINED

module Solution (
  input wire clk,
  input wire reset,
  output wire i_ready,
  input wire i_valid,
  input wire [16-1:0] i_payload_a,
  input wire [16-1:0] i_payload_b,
  output wire [32-1:0] o_payload,
  output wire o_valid
);

  // Define your design here
`ifdef PIPELINED
  mul16_pipe i_mul (
      .clk(clk)
    , .reset(reset)
    , .o_ready(i_ready)
    , .i_valid(i_valid)
    , .i_payload_a(i_payload_a)
    , .i_payload_b(i_payload_b)
    , .o_payload(o_payload)
    , .o_valid(o_valid)
  );
`else // `ifdef PIPELINED -> i.e. not pipelined
  mul16_comb i_mul (
    .i_multiplicand(i_payload_a),
    .i_multiplier(i_payload_b),
    .o_product(o_payload)
  );
  assign i_ready = !reset;
  assign o_valid = i_valid;

`endif // `ifdef PIPELINED

endmodule
