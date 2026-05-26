`timescale 1ns / 1ps
// ============================================================
//  ntt_pipelined.v  -- 5-stage fully pipelined DIF NTT
//
//  CED ADDITION: Each butterfly_unit now drives an 'error' wire.
//  Per-stage error flags (err_s0..err_s4) OR together all 16
//  butterfly error outputs in that stage. These are registered
//  in sync with the pipeline so they arrive at the output
//  alongside 'done'. A single output port 'error' is the OR of
//  all five stage error registers - asserted the same cycle as
//  'done' if any butterfly fault was detected during computation.
// ============================================================
module ntt_pipelined #(
    parameter DATA_WIDTH = 7,
    parameter Q          = 97,
    parameter N          = 32,
    parameter STAGES     = 5
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  start,

    input  wire [DATA_WIDTH-1:0] a0,  a1,  a2,  a3,
    input  wire [DATA_WIDTH-1:0] a4,  a5,  a6,  a7,
    input  wire [DATA_WIDTH-1:0] a8,  a9,  a10, a11,
    input  wire [DATA_WIDTH-1:0] a12, a13, a14, a15,
    input  wire [DATA_WIDTH-1:0] a16, a17, a18, a19,
    input  wire [DATA_WIDTH-1:0] a20, a21, a22, a23,
    input  wire [DATA_WIDTH-1:0] a24, a25, a26, a27,
    input  wire [DATA_WIDTH-1:0] a28, a29, a30, a31,

    output reg  [DATA_WIDTH-1:0] F0,  F1,  F2,  F3,
    output reg  [DATA_WIDTH-1:0] F4,  F5,  F6,  F7,
    output reg  [DATA_WIDTH-1:0] F8,  F9,  F10, F11,
    output reg  [DATA_WIDTH-1:0] F12, F13, F14, F15,
    output reg  [DATA_WIDTH-1:0] F16, F17, F18, F19,
    output reg  [DATA_WIDTH-1:0] F20, F21, F22, F23,
    output reg  [DATA_WIDTH-1:0] F24, F25, F26, F27,
    output reg  [DATA_WIDTH-1:0] F28, F29, F30, F31,
    output reg                   done,
    output reg                   error   // NEW: CED fault flag (registered)
);

    // ----------------------------------------------------------
    // Twiddle constants (W[k] = 19^k mod 97)
    // ----------------------------------------------------------
    localparam TW0  =  1; localparam TW1  = 19; localparam TW2  = 70; localparam TW3  = 69;
    localparam TW4  = 50; localparam TW5  = 77; localparam TW6  =  8; localparam TW7  = 55;
    localparam TW8  = 75; localparam TW9  = 67; localparam TW10 = 12; localparam TW11 = 34;
    localparam TW12 = 64; localparam TW13 = 52; localparam TW14 = 18; localparam TW15 = 51;
    localparam TW16 = 96; localparam TW17 = 78; localparam TW18 = 27; localparam TW19 = 28;
    localparam TW20 = 47; localparam TW21 = 20; localparam TW22 = 89; localparam TW23 = 42;
    localparam TW24 = 22; localparam TW25 = 30; localparam TW26 = 85; localparam TW27 = 63;
    localparam TW28 = 33; localparam TW29 = 45; localparam TW30 = 79; localparam TW31 = 46;

    // ----------------------------------------------------------
    // Pipeline registers
    // ----------------------------------------------------------
    reg [DATA_WIDTH-1:0] r [0:31];
    reg [DATA_WIDTH-1:0] s0[0:31];
    reg [DATA_WIDTH-1:0] s1[0:31];
    reg [DATA_WIDTH-1:0] s2[0:31];
    reg [DATA_WIDTH-1:0] s3[0:31];
    reg [DATA_WIDTH-1:0] s4[0:31];

    // ----------------------------------------------------------
    // Butterfly output wires
    // ----------------------------------------------------------
    wire [DATA_WIDTH-1:0] b0u[0:15], b0v[0:15];
    wire [DATA_WIDTH-1:0] b1u[0:15], b1v[0:15];
    wire [DATA_WIDTH-1:0] b2u[0:15], b2v[0:15];
    wire [DATA_WIDTH-1:0] b3u[0:15], b3v[0:15];
    wire [DATA_WIDTH-1:0] b4u[0:15], b4v[0:15];

    // ----------------------------------------------------------
    // CED error wires - one per butterfly, per stage
    // ----------------------------------------------------------
    wire b0e[0:15];
    wire b1e[0:15];
    wire b2e[0:15];
    wire b3e[0:15];
    wire b4e[0:15];

    // Per-stage combinational OR of all butterfly errors
    wire err_s0_comb = b0e[0]|b0e[1]|b0e[2]|b0e[3]|b0e[4]|b0e[5]|b0e[6]|b0e[7]|
                       b0e[8]|b0e[9]|b0e[10]|b0e[11]|b0e[12]|b0e[13]|b0e[14]|b0e[15];
    wire err_s1_comb = b1e[0]|b1e[1]|b1e[2]|b1e[3]|b1e[4]|b1e[5]|b1e[6]|b1e[7]|
                       b1e[8]|b1e[9]|b1e[10]|b1e[11]|b1e[12]|b1e[13]|b1e[14]|b1e[15];
    wire err_s2_comb = b2e[0]|b2e[1]|b2e[2]|b2e[3]|b2e[4]|b2e[5]|b2e[6]|b2e[7]|
                       b2e[8]|b2e[9]|b2e[10]|b2e[11]|b2e[12]|b2e[13]|b2e[14]|b2e[15];
    wire err_s3_comb = b3e[0]|b3e[1]|b3e[2]|b3e[3]|b3e[4]|b3e[5]|b3e[6]|b3e[7]|
                       b3e[8]|b3e[9]|b3e[10]|b3e[11]|b3e[12]|b3e[13]|b3e[14]|b3e[15];
    wire err_s4_comb = b4e[0]|b4e[1]|b4e[2]|b4e[3]|b4e[4]|b4e[5]|b4e[6]|b4e[7]|
                       b4e[8]|b4e[9]|b4e[10]|b4e[11]|b4e[12]|b4e[13]|b4e[14]|b4e[15];

    // Pipeline-registered error accumulators
    // Each register sits at the same stage boundary as the data registers,
    // so all five reach the output latch simultaneously.
    reg err_r0, err_r1, err_r2, err_r3, err_r4;

    // ----------------------------------------------------------
    // Valid pipeline shift register (7-bit)
    // ----------------------------------------------------------
    reg [6:0] vp;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) vp <= 7'b0;
        else        vp <= {vp[5:0], start};

    // ----------------------------------------------------------
    // Input latch
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r[0]<=0;  r[1]<=0;  r[2]<=0;  r[3]<=0;
            r[4]<=0;  r[5]<=0;  r[6]<=0;  r[7]<=0;
            r[8]<=0;  r[9]<=0;  r[10]<=0; r[11]<=0;
            r[12]<=0; r[13]<=0; r[14]<=0; r[15]<=0;
            r[16]<=0; r[17]<=0; r[18]<=0; r[19]<=0;
            r[20]<=0; r[21]<=0; r[22]<=0; r[23]<=0;
            r[24]<=0; r[25]<=0; r[26]<=0; r[27]<=0;
            r[28]<=0; r[29]<=0; r[30]<=0; r[31]<=0;
        end else if (start) begin
            r[0]<=a0;   r[1]<=a1;   r[2]<=a2;   r[3]<=a3;
            r[4]<=a4;   r[5]<=a5;   r[6]<=a6;   r[7]<=a7;
            r[8]<=a8;   r[9]<=a9;   r[10]<=a10; r[11]<=a11;
            r[12]<=a12; r[13]<=a13; r[14]<=a14; r[15]<=a15;
            r[16]<=a16; r[17]<=a17; r[18]<=a18; r[19]<=a19;
            r[20]<=a20; r[21]<=a21; r[22]<=a22; r[23]<=a23;
            r[24]<=a24; r[25]<=a25; r[26]<=a26; r[27]<=a27;
            r[28]<=a28; r[29]<=a29; r[30]<=a30; r[31]<=a31;
        end
    end

    // ==========================================================
    // STAGE 0 butterflies - pairs (i, i+16), twiddle W[i]
    // ==========================================================
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b0  (.u(r[0]), .v(r[16]),.W(TW0), .u_out(b0u[0]), .v_out(b0v[0]), .error(b0e[0]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b1  (.u(r[1]), .v(r[17]),.W(TW1), .u_out(b0u[1]), .v_out(b0v[1]), .error(b0e[1]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b2  (.u(r[2]), .v(r[18]),.W(TW2), .u_out(b0u[2]), .v_out(b0v[2]), .error(b0e[2]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b3  (.u(r[3]), .v(r[19]),.W(TW3), .u_out(b0u[3]), .v_out(b0v[3]), .error(b0e[3]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b4  (.u(r[4]), .v(r[20]),.W(TW4), .u_out(b0u[4]), .v_out(b0v[4]), .error(b0e[4]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b5  (.u(r[5]), .v(r[21]),.W(TW5), .u_out(b0u[5]), .v_out(b0v[5]), .error(b0e[5]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b6  (.u(r[6]), .v(r[22]),.W(TW6), .u_out(b0u[6]), .v_out(b0v[6]), .error(b0e[6]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b7  (.u(r[7]), .v(r[23]),.W(TW7), .u_out(b0u[7]), .v_out(b0v[7]), .error(b0e[7]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b8  (.u(r[8]), .v(r[24]),.W(TW8), .u_out(b0u[8]), .v_out(b0v[8]), .error(b0e[8]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b9  (.u(r[9]), .v(r[25]),.W(TW9), .u_out(b0u[9]), .v_out(b0v[9]), .error(b0e[9]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b10 (.u(r[10]),.v(r[26]),.W(TW10),.u_out(b0u[10]),.v_out(b0v[10]),.error(b0e[10]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b11 (.u(r[11]),.v(r[27]),.W(TW11),.u_out(b0u[11]),.v_out(b0v[11]),.error(b0e[11]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b12 (.u(r[12]),.v(r[28]),.W(TW12),.u_out(b0u[12]),.v_out(b0v[12]),.error(b0e[12]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b13 (.u(r[13]),.v(r[29]),.W(TW13),.u_out(b0u[13]),.v_out(b0v[13]),.error(b0e[13]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b14 (.u(r[14]),.v(r[30]),.W(TW14),.u_out(b0u[14]),.v_out(b0v[14]),.error(b0e[14]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s0b15 (.u(r[15]),.v(r[31]),.W(TW15),.u_out(b0u[15]),.v_out(b0v[15]),.error(b0e[15]));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            err_r0 <= 1'b0;
            s0[0]<=0;  s0[1]<=0;  s0[2]<=0;  s0[3]<=0;
            s0[4]<=0;  s0[5]<=0;  s0[6]<=0;  s0[7]<=0;
            s0[8]<=0;  s0[9]<=0;  s0[10]<=0; s0[11]<=0;
            s0[12]<=0; s0[13]<=0; s0[14]<=0; s0[15]<=0;
            s0[16]<=0; s0[17]<=0; s0[18]<=0; s0[19]<=0;
            s0[20]<=0; s0[21]<=0; s0[22]<=0; s0[23]<=0;
            s0[24]<=0; s0[25]<=0; s0[26]<=0; s0[27]<=0;
            s0[28]<=0; s0[29]<=0; s0[30]<=0; s0[31]<=0;
        end else begin
            err_r0 <= err_s0_comb;
            s0[0] <=b0u[0];  s0[1] <=b0u[1];  s0[2] <=b0u[2];  s0[3] <=b0u[3];
            s0[4] <=b0u[4];  s0[5] <=b0u[5];  s0[6] <=b0u[6];  s0[7] <=b0u[7];
            s0[8] <=b0u[8];  s0[9] <=b0u[9];  s0[10]<=b0u[10]; s0[11]<=b0u[11];
            s0[12]<=b0u[12]; s0[13]<=b0u[13]; s0[14]<=b0u[14]; s0[15]<=b0u[15];
            s0[16]<=b0v[0];  s0[17]<=b0v[1];  s0[18]<=b0v[2];  s0[19]<=b0v[3];
            s0[20]<=b0v[4];  s0[21]<=b0v[5];  s0[22]<=b0v[6];  s0[23]<=b0v[7];
            s0[24]<=b0v[8];  s0[25]<=b0v[9];  s0[26]<=b0v[10]; s0[27]<=b0v[11];
            s0[28]<=b0v[12]; s0[29]<=b0v[13]; s0[30]<=b0v[14]; s0[31]<=b0v[15];
        end
    end

    // ==========================================================
    // STAGE 1 butterflies - pairs (i,i+8), twiddles W[0,2,4,6,8,10,12,14]
    // ==========================================================
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b0  (.u(s0[0]), .v(s0[8]), .W(TW0), .u_out(b1u[0]), .v_out(b1v[0]), .error(b1e[0]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b1  (.u(s0[1]), .v(s0[9]), .W(TW2), .u_out(b1u[1]), .v_out(b1v[1]), .error(b1e[1]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b2  (.u(s0[2]), .v(s0[10]),.W(TW4), .u_out(b1u[2]), .v_out(b1v[2]), .error(b1e[2]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b3  (.u(s0[3]), .v(s0[11]),.W(TW6), .u_out(b1u[3]), .v_out(b1v[3]), .error(b1e[3]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b4  (.u(s0[4]), .v(s0[12]),.W(TW8), .u_out(b1u[4]), .v_out(b1v[4]), .error(b1e[4]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b5  (.u(s0[5]), .v(s0[13]),.W(TW10),.u_out(b1u[5]), .v_out(b1v[5]), .error(b1e[5]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b6  (.u(s0[6]), .v(s0[14]),.W(TW12),.u_out(b1u[6]), .v_out(b1v[6]), .error(b1e[6]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b7  (.u(s0[7]), .v(s0[15]),.W(TW14),.u_out(b1u[7]), .v_out(b1v[7]), .error(b1e[7]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b8  (.u(s0[16]),.v(s0[24]),.W(TW0), .u_out(b1u[8]), .v_out(b1v[8]), .error(b1e[8]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b9  (.u(s0[17]),.v(s0[25]),.W(TW2), .u_out(b1u[9]), .v_out(b1v[9]), .error(b1e[9]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b10 (.u(s0[18]),.v(s0[26]),.W(TW4), .u_out(b1u[10]),.v_out(b1v[10]),.error(b1e[10]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b11 (.u(s0[19]),.v(s0[27]),.W(TW6), .u_out(b1u[11]),.v_out(b1v[11]),.error(b1e[11]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b12 (.u(s0[20]),.v(s0[28]),.W(TW8), .u_out(b1u[12]),.v_out(b1v[12]),.error(b1e[12]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b13 (.u(s0[21]),.v(s0[29]),.W(TW10),.u_out(b1u[13]),.v_out(b1v[13]),.error(b1e[13]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b14 (.u(s0[22]),.v(s0[30]),.W(TW12),.u_out(b1u[14]),.v_out(b1v[14]),.error(b1e[14]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s1b15 (.u(s0[23]),.v(s0[31]),.W(TW14),.u_out(b1u[15]),.v_out(b1v[15]),.error(b1e[15]));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            err_r1 <= 1'b0;
            s1[0]<=0;  s1[1]<=0;  s1[2]<=0;  s1[3]<=0;
            s1[4]<=0;  s1[5]<=0;  s1[6]<=0;  s1[7]<=0;
            s1[8]<=0;  s1[9]<=0;  s1[10]<=0; s1[11]<=0;
            s1[12]<=0; s1[13]<=0; s1[14]<=0; s1[15]<=0;
            s1[16]<=0; s1[17]<=0; s1[18]<=0; s1[19]<=0;
            s1[20]<=0; s1[21]<=0; s1[22]<=0; s1[23]<=0;
            s1[24]<=0; s1[25]<=0; s1[26]<=0; s1[27]<=0;
            s1[28]<=0; s1[29]<=0; s1[30]<=0; s1[31]<=0;
        end else begin
            err_r1 <= err_r0 | err_s1_comb;
            s1[0] <=b1u[0];  s1[8] <=b1v[0];
            s1[1] <=b1u[1];  s1[9] <=b1v[1];
            s1[2] <=b1u[2];  s1[10]<=b1v[2];
            s1[3] <=b1u[3];  s1[11]<=b1v[3];
            s1[4] <=b1u[4];  s1[12]<=b1v[4];
            s1[5] <=b1u[5];  s1[13]<=b1v[5];
            s1[6] <=b1u[6];  s1[14]<=b1v[6];
            s1[7] <=b1u[7];  s1[15]<=b1v[7];
            s1[16]<=b1u[8];  s1[24]<=b1v[8];
            s1[17]<=b1u[9];  s1[25]<=b1v[9];
            s1[18]<=b1u[10]; s1[26]<=b1v[10];
            s1[19]<=b1u[11]; s1[27]<=b1v[11];
            s1[20]<=b1u[12]; s1[28]<=b1v[12];
            s1[21]<=b1u[13]; s1[29]<=b1v[13];
            s1[22]<=b1u[14]; s1[30]<=b1v[14];
            s1[23]<=b1u[15]; s1[31]<=b1v[15];
        end
    end

    // ==========================================================
    // STAGE 2 butterflies - pairs (i,i+4), twiddles W[0,4,8,12]
    // ==========================================================
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b0  (.u(s1[0]), .v(s1[4]), .W(TW0), .u_out(b2u[0]), .v_out(b2v[0]), .error(b2e[0]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b1  (.u(s1[1]), .v(s1[5]), .W(TW4), .u_out(b2u[1]), .v_out(b2v[1]), .error(b2e[1]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b2  (.u(s1[2]), .v(s1[6]), .W(TW8), .u_out(b2u[2]), .v_out(b2v[2]), .error(b2e[2]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b3  (.u(s1[3]), .v(s1[7]), .W(TW12),.u_out(b2u[3]), .v_out(b2v[3]), .error(b2e[3]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b4  (.u(s1[8]), .v(s1[12]),.W(TW0), .u_out(b2u[4]), .v_out(b2v[4]), .error(b2e[4]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b5  (.u(s1[9]), .v(s1[13]),.W(TW4), .u_out(b2u[5]), .v_out(b2v[5]), .error(b2e[5]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b6  (.u(s1[10]),.v(s1[14]),.W(TW8), .u_out(b2u[6]), .v_out(b2v[6]), .error(b2e[6]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b7  (.u(s1[11]),.v(s1[15]),.W(TW12),.u_out(b2u[7]), .v_out(b2v[7]), .error(b2e[7]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b8  (.u(s1[16]),.v(s1[20]),.W(TW0), .u_out(b2u[8]), .v_out(b2v[8]), .error(b2e[8]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b9  (.u(s1[17]),.v(s1[21]),.W(TW4), .u_out(b2u[9]), .v_out(b2v[9]), .error(b2e[9]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b10 (.u(s1[18]),.v(s1[22]),.W(TW8), .u_out(b2u[10]),.v_out(b2v[10]),.error(b2e[10]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b11 (.u(s1[19]),.v(s1[23]),.W(TW12),.u_out(b2u[11]),.v_out(b2v[11]),.error(b2e[11]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b12 (.u(s1[24]),.v(s1[28]),.W(TW0), .u_out(b2u[12]),.v_out(b2v[12]),.error(b2e[12]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b13 (.u(s1[25]),.v(s1[29]),.W(TW4), .u_out(b2u[13]),.v_out(b2v[13]),.error(b2e[13]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b14 (.u(s1[26]),.v(s1[30]),.W(TW8), .u_out(b2u[14]),.v_out(b2v[14]),.error(b2e[14]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s2b15 (.u(s1[27]),.v(s1[31]),.W(TW12),.u_out(b2u[15]),.v_out(b2v[15]),.error(b2e[15]));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            err_r2 <= 1'b0;
            s2[0]<=0;  s2[1]<=0;  s2[2]<=0;  s2[3]<=0;
            s2[4]<=0;  s2[5]<=0;  s2[6]<=0;  s2[7]<=0;
            s2[8]<=0;  s2[9]<=0;  s2[10]<=0; s2[11]<=0;
            s2[12]<=0; s2[13]<=0; s2[14]<=0; s2[15]<=0;
            s2[16]<=0; s2[17]<=0; s2[18]<=0; s2[19]<=0;
            s2[20]<=0; s2[21]<=0; s2[22]<=0; s2[23]<=0;
            s2[24]<=0; s2[25]<=0; s2[26]<=0; s2[27]<=0;
            s2[28]<=0; s2[29]<=0; s2[30]<=0; s2[31]<=0;
        end else begin
            err_r2 <= err_r1 | err_s2_comb;
            s2[0] <=b2u[0];  s2[4] <=b2v[0];
            s2[1] <=b2u[1];  s2[5] <=b2v[1];
            s2[2] <=b2u[2];  s2[6] <=b2v[2];
            s2[3] <=b2u[3];  s2[7] <=b2v[3];
            s2[8] <=b2u[4];  s2[12]<=b2v[4];
            s2[9] <=b2u[5];  s2[13]<=b2v[5];
            s2[10]<=b2u[6];  s2[14]<=b2v[6];
            s2[11]<=b2u[7];  s2[15]<=b2v[7];
            s2[16]<=b2u[8];  s2[20]<=b2v[8];
            s2[17]<=b2u[9];  s2[21]<=b2v[9];
            s2[18]<=b2u[10]; s2[22]<=b2v[10];
            s2[19]<=b2u[11]; s2[23]<=b2v[11];
            s2[24]<=b2u[12]; s2[28]<=b2v[12];
            s2[25]<=b2u[13]; s2[29]<=b2v[13];
            s2[26]<=b2u[14]; s2[30]<=b2v[14];
            s2[27]<=b2u[15]; s2[31]<=b2v[15];
        end
    end

    // ==========================================================
    // STAGE 3 butterflies - pairs (i,i+2), twiddles W[0] and W[8]
    // ==========================================================
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b0  (.u(s2[0]), .v(s2[2]), .W(TW0), .u_out(b3u[0]), .v_out(b3v[0]), .error(b3e[0]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b1  (.u(s2[1]), .v(s2[3]), .W(TW8), .u_out(b3u[1]), .v_out(b3v[1]), .error(b3e[1]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b2  (.u(s2[4]), .v(s2[6]), .W(TW0), .u_out(b3u[2]), .v_out(b3v[2]), .error(b3e[2]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b3  (.u(s2[5]), .v(s2[7]), .W(TW8), .u_out(b3u[3]), .v_out(b3v[3]), .error(b3e[3]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b4  (.u(s2[8]), .v(s2[10]),.W(TW0), .u_out(b3u[4]), .v_out(b3v[4]), .error(b3e[4]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b5  (.u(s2[9]), .v(s2[11]),.W(TW8), .u_out(b3u[5]), .v_out(b3v[5]), .error(b3e[5]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b6  (.u(s2[12]),.v(s2[14]),.W(TW0), .u_out(b3u[6]), .v_out(b3v[6]), .error(b3e[6]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b7  (.u(s2[13]),.v(s2[15]),.W(TW8), .u_out(b3u[7]), .v_out(b3v[7]), .error(b3e[7]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b8  (.u(s2[16]),.v(s2[18]),.W(TW0), .u_out(b3u[8]), .v_out(b3v[8]), .error(b3e[8]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b9  (.u(s2[17]),.v(s2[19]),.W(TW8), .u_out(b3u[9]), .v_out(b3v[9]), .error(b3e[9]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b10 (.u(s2[20]),.v(s2[22]),.W(TW0), .u_out(b3u[10]),.v_out(b3v[10]),.error(b3e[10]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b11 (.u(s2[21]),.v(s2[23]),.W(TW8), .u_out(b3u[11]),.v_out(b3v[11]),.error(b3e[11]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b12 (.u(s2[24]),.v(s2[26]),.W(TW0), .u_out(b3u[12]),.v_out(b3v[12]),.error(b3e[12]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b13 (.u(s2[25]),.v(s2[27]),.W(TW8), .u_out(b3u[13]),.v_out(b3v[13]),.error(b3e[13]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b14 (.u(s2[28]),.v(s2[30]),.W(TW0), .u_out(b3u[14]),.v_out(b3v[14]),.error(b3e[14]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s3b15 (.u(s2[29]),.v(s2[31]),.W(TW8), .u_out(b3u[15]),.v_out(b3v[15]),.error(b3e[15]));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            err_r3 <= 1'b0;
            s3[0]<=0;  s3[1]<=0;  s3[2]<=0;  s3[3]<=0;
            s3[4]<=0;  s3[5]<=0;  s3[6]<=0;  s3[7]<=0;
            s3[8]<=0;  s3[9]<=0;  s3[10]<=0; s3[11]<=0;
            s3[12]<=0; s3[13]<=0; s3[14]<=0; s3[15]<=0;
            s3[16]<=0; s3[17]<=0; s3[18]<=0; s3[19]<=0;
            s3[20]<=0; s3[21]<=0; s3[22]<=0; s3[23]<=0;
            s3[24]<=0; s3[25]<=0; s3[26]<=0; s3[27]<=0;
            s3[28]<=0; s3[29]<=0; s3[30]<=0; s3[31]<=0;
        end else begin
            err_r3 <= err_r2 | err_s3_comb;
            s3[0] <=b3u[0];  s3[2] <=b3v[0];
            s3[1] <=b3u[1];  s3[3] <=b3v[1];
            s3[4] <=b3u[2];  s3[6] <=b3v[2];
            s3[5] <=b3u[3];  s3[7] <=b3v[3];
            s3[8] <=b3u[4];  s3[10]<=b3v[4];
            s3[9] <=b3u[5];  s3[11]<=b3v[5];
            s3[12]<=b3u[6];  s3[14]<=b3v[6];
            s3[13]<=b3u[7];  s3[15]<=b3v[7];
            s3[16]<=b3u[8];  s3[18]<=b3v[8];
            s3[17]<=b3u[9];  s3[19]<=b3v[9];
            s3[20]<=b3u[10]; s3[22]<=b3v[10];
            s3[21]<=b3u[11]; s3[23]<=b3v[11];
            s3[24]<=b3u[12]; s3[26]<=b3v[12];
            s3[25]<=b3u[13]; s3[27]<=b3v[13];
            s3[28]<=b3u[14]; s3[30]<=b3v[14];
            s3[29]<=b3u[15]; s3[31]<=b3v[15];
        end
    end

    // ==========================================================
    // STAGE 4 butterflies - pairs (i,i+1), twiddle W[0]=1
    // ==========================================================
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b0  (.u(s3[0]), .v(s3[1]), .W(TW0),.u_out(b4u[0]), .v_out(b4v[0]), .error(b4e[0]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b1  (.u(s3[2]), .v(s3[3]), .W(TW0),.u_out(b4u[1]), .v_out(b4v[1]), .error(b4e[1]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b2  (.u(s3[4]), .v(s3[5]), .W(TW0),.u_out(b4u[2]), .v_out(b4v[2]), .error(b4e[2]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b3  (.u(s3[6]), .v(s3[7]), .W(TW0),.u_out(b4u[3]), .v_out(b4v[3]), .error(b4e[3]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b4  (.u(s3[8]), .v(s3[9]), .W(TW0),.u_out(b4u[4]), .v_out(b4v[4]), .error(b4e[4]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b5  (.u(s3[10]),.v(s3[11]),.W(TW0),.u_out(b4u[5]), .v_out(b4v[5]), .error(b4e[5]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b6  (.u(s3[12]),.v(s3[13]),.W(TW0),.u_out(b4u[6]), .v_out(b4v[6]), .error(b4e[6]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b7  (.u(s3[14]),.v(s3[15]),.W(TW0),.u_out(b4u[7]), .v_out(b4v[7]), .error(b4e[7]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b8  (.u(s3[16]),.v(s3[17]),.W(TW0),.u_out(b4u[8]), .v_out(b4v[8]), .error(b4e[8]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b9  (.u(s3[18]),.v(s3[19]),.W(TW0),.u_out(b4u[9]), .v_out(b4v[9]), .error(b4e[9]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b10 (.u(s3[20]),.v(s3[21]),.W(TW0),.u_out(b4u[10]),.v_out(b4v[10]),.error(b4e[10]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b11 (.u(s3[22]),.v(s3[23]),.W(TW0),.u_out(b4u[11]),.v_out(b4v[11]),.error(b4e[11]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b12 (.u(s3[24]),.v(s3[25]),.W(TW0),.u_out(b4u[12]),.v_out(b4v[12]),.error(b4e[12]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b13 (.u(s3[26]),.v(s3[27]),.W(TW0),.u_out(b4u[13]),.v_out(b4v[13]),.error(b4e[13]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b14 (.u(s3[28]),.v(s3[29]),.W(TW0),.u_out(b4u[14]),.v_out(b4v[14]),.error(b4e[14]));
    butterfly_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) s4b15 (.u(s3[30]),.v(s3[31]),.W(TW0),.u_out(b4u[15]),.v_out(b4v[15]),.error(b4e[15]));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            err_r4 <= 1'b0;
            s4[0]<=0;  s4[1]<=0;  s4[2]<=0;  s4[3]<=0;
            s4[4]<=0;  s4[5]<=0;  s4[6]<=0;  s4[7]<=0;
            s4[8]<=0;  s4[9]<=0;  s4[10]<=0; s4[11]<=0;
            s4[12]<=0; s4[13]<=0; s4[14]<=0; s4[15]<=0;
            s4[16]<=0; s4[17]<=0; s4[18]<=0; s4[19]<=0;
            s4[20]<=0; s4[21]<=0; s4[22]<=0; s4[23]<=0;
            s4[24]<=0; s4[25]<=0; s4[26]<=0; s4[27]<=0;
            s4[28]<=0; s4[29]<=0; s4[30]<=0; s4[31]<=0;
        end else begin
            err_r4 <= err_r3 | err_s4_comb;
            s4[0] <=b4u[0];  s4[1] <=b4v[0];
            s4[2] <=b4u[1];  s4[3] <=b4v[1];
            s4[4] <=b4u[2];  s4[5] <=b4v[2];
            s4[6] <=b4u[3];  s4[7] <=b4v[3];
            s4[8] <=b4u[4];  s4[9] <=b4v[4];
            s4[10]<=b4u[5];  s4[11]<=b4v[5];
            s4[12]<=b4u[6];  s4[13]<=b4v[6];
            s4[14]<=b4u[7];  s4[15]<=b4v[7];
            s4[16]<=b4u[8];  s4[17]<=b4v[8];
            s4[18]<=b4u[9];  s4[19]<=b4v[9];
            s4[20]<=b4u[10]; s4[21]<=b4v[10];
            s4[22]<=b4u[11]; s4[23]<=b4v[11];
            s4[24]<=b4u[12]; s4[25]<=b4v[12];
            s4[26]<=b4u[13]; s4[27]<=b4v[13];
            s4[28]<=b4u[14]; s4[29]<=b4v[14];
            s4[30]<=b4u[15]; s4[31]<=b4v[15];
        end
    end

    // ==========================================================
    // OUTPUT LATCH - bit-reversal + done + error
    // ==========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done  <= 1'b0;
            error <= 1'b0;
            F0<=0;  F1<=0;  F2<=0;  F3<=0;  F4<=0;  F5<=0;  F6<=0;  F7<=0;
            F8<=0;  F9<=0;  F10<=0; F11<=0; F12<=0; F13<=0; F14<=0; F15<=0;
            F16<=0; F17<=0; F18<=0; F19<=0; F20<=0; F21<=0; F22<=0; F23<=0;
            F24<=0; F25<=0; F26<=0; F27<=0; F28<=0; F29<=0; F30<=0; F31<=0;
        end else begin
            done  <= vp[6];
            error <= err_r4;   // accumulated error from all 5 stages
            if (vp[6]) begin
                F0  <= s4[0];  F1  <= s4[16]; F2  <= s4[8];  F3  <= s4[24];
                F4  <= s4[4];  F5  <= s4[20]; F6  <= s4[12]; F7  <= s4[28];
                F8  <= s4[2];  F9  <= s4[18]; F10 <= s4[10]; F11 <= s4[26];
                F12 <= s4[6];  F13 <= s4[22]; F14 <= s4[14]; F15 <= s4[30];
                F16 <= s4[1];  F17 <= s4[17]; F18 <= s4[9];  F19 <= s4[25];
                F20 <= s4[5];  F21 <= s4[21]; F22 <= s4[13]; F23 <= s4[29];
                F24 <= s4[3];  F25 <= s4[19]; F26 <= s4[11]; F27 <= s4[27];
                F28 <= s4[7];  F29 <= s4[23]; F30 <= s4[15]; F31 <= s4[31];
            end
        end
    end

endmodule