`timescale 1ns / 1ps
// ============================================================
//  butterfly_unit.v  -- DIF butterfly, fully combinational
//
//  CED ADDITION: Added concurrent error detection (CED) signal.
//  Mathematical invariant exploited:
//    For every DIF butterfly:  u_out + v_out ≡ 2*u (mod Q)
//  A single modular adder and comparator check this at zero latency.
//  If the check fails, 'error' is asserted combinationally.
//
//  Barrett constants for Q=97, x_max=9216 (= 96*96):
//    s = 20,  k = floor(2^20 / 97) = 10810
//    q = (x * 10810) >> 20
//    r = x - q*97;  if r>=97: r-=97
//  Verified correct for all x in [0, 9216].
// ============================================================
module butterfly_unit #(
    parameter DATA_WIDTH = 7,
    parameter Q          = 97
)(
    input  wire [DATA_WIDTH-1:0] u,
    input  wire [DATA_WIDTH-1:0] v,
    input  wire [DATA_WIDTH-1:0] W,
    output wire [DATA_WIDTH-1:0] u_out,
    output wire [DATA_WIDTH-1:0] v_out,
    output wire                  error      // NEW: CED fault flag
);
    // ----------------------------------------------------------
    // u_out = (u + v) mod Q
    // ----------------------------------------------------------
    wire [DATA_WIDTH:0] sum;
    assign sum   = {1'b0, u} + {1'b0, v};
    assign u_out = (sum >= Q) ? (sum - Q) : sum[DATA_WIDTH-1:0];

    // ----------------------------------------------------------
    // diff = (u - v) mod Q
    // ----------------------------------------------------------
    wire [DATA_WIDTH:0] diff_raw;
    wire [DATA_WIDTH-1:0] diff;
    assign diff_raw = u + Q - v;
    assign diff     = (diff_raw >= Q) ? (diff_raw - Q) : diff_raw[DATA_WIDTH-1:0];

    // ----------------------------------------------------------
    // v_out = (W * diff) mod Q  using Barrett reduction
    // product max = 96 * 96 = 9216, fits in 14 bits
    // Barrett: k=10810, s=20
    //   q = (product * 10810) >> 20
    //   r = product - q*97;  if r>=97: r-=97
    // ----------------------------------------------------------
    wire [2*DATA_WIDTH:0] product;   // 15 bits, max 9216
    wire [34:0]           bk;        // product * 10810
    wire [DATA_WIDTH:0]   bq;        // quotient estimate
    wire [DATA_WIDTH:0]   br;        // remainder before final subtract
    assign product = W * diff;
    assign bk      = product * 15'd10810;
    assign bq      = bk[34:20];          // >> 20
    assign br      = product - bq * Q;
    assign v_out   = (br >= Q) ? (br - Q) : br[DATA_WIDTH-1:0];

    // ----------------------------------------------------------
    // CED: Verify u_out + v_out ≡ 2*u (mod Q)
    //
    // ced_sum  = (u_out + v_out) mod Q
    // ced_ref  = (2 * u) mod Q
    // error    = 1 if they differ (fault detected)
    // ----------------------------------------------------------
    wire [DATA_WIDTH:0] ced_sum_raw;
    wire [DATA_WIDTH-1:0] ced_sum;
    assign ced_sum_raw = {1'b0, u_out} + {1'b0, v_out};
    assign ced_sum     = (ced_sum_raw >= Q) ? (ced_sum_raw - Q) : ced_sum_raw[DATA_WIDTH-1:0];

    wire [DATA_WIDTH:0] ced_ref_raw;
    wire [DATA_WIDTH-1:0] ced_ref;
    assign ced_ref_raw = {1'b0, u} + {1'b0, u};   // 2*u
    assign ced_ref     = (ced_ref_raw >= Q) ? (ced_ref_raw - Q) : ced_ref_raw[DATA_WIDTH-1:0];

    assign error = (ced_sum !== ced_ref);

endmodule