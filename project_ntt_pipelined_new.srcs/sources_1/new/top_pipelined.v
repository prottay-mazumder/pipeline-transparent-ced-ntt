`timescale 1ns / 1ps
module top_pipelined #(
    parameter DATA_WIDTH = 7,
    parameter Q          = 97,
    parameter N          = 32
)(
    input  wire clk, rst_n, start,
    input  wire [DATA_WIDTH-1:0] f0,f1,f2,f3,f4,f5,f6,f7,
    input  wire [DATA_WIDTH-1:0] f8,f9,f10,f11,f12,f13,f14,f15,
    input  wire [DATA_WIDTH-1:0] f16,f17,f18,f19,f20,f21,f22,f23,
    input  wire [DATA_WIDTH-1:0] f24,f25,f26,f27,f28,f29,f30,f31,
    input  wire [DATA_WIDTH-1:0] g0,g1,g2,g3,g4,g5,g6,g7,
    input  wire [DATA_WIDTH-1:0] g8,g9,g10,g11,g12,g13,g14,g15,
    input  wire [DATA_WIDTH-1:0] g16,g17,g18,g19,g20,g21,g22,g23,
    input  wire [DATA_WIDTH-1:0] g24,g25,g26,g27,g28,g29,g30,g31,
    output wire [DATA_WIDTH-1:0] C0,C1,C2,C3,C4,C5,C6,C7,
    output wire [DATA_WIDTH-1:0] C8,C9,C10,C11,C12,C13,C14,C15,
    output wire [DATA_WIDTH-1:0] C16,C17,C18,C19,C20,C21,C22,C23,
    output wire [DATA_WIDTH-1:0] C24,C25,C26,C27,C28,C29,C30,C31,
    output wire done
);
    wire [DATA_WIDTH-1:0] Af0,Af1,Af2,Af3,Af4,Af5,Af6,Af7;
    wire [DATA_WIDTH-1:0] Af8,Af9,Af10,Af11,Af12,Af13,Af14,Af15;
    wire [DATA_WIDTH-1:0] Af16,Af17,Af18,Af19,Af20,Af21,Af22,Af23;
    wire [DATA_WIDTH-1:0] Af24,Af25,Af26,Af27,Af28,Af29,Af30,Af31;
    wire done_f;
    wire [DATA_WIDTH-1:0] Ag0,Ag1,Ag2,Ag3,Ag4,Ag5,Ag6,Ag7;
    wire [DATA_WIDTH-1:0] Ag8,Ag9,Ag10,Ag11,Ag12,Ag13,Ag14,Ag15;
    wire [DATA_WIDTH-1:0] Ag16,Ag17,Ag18,Ag19,Ag20,Ag21,Ag22,Ag23;
    wire [DATA_WIDTH-1:0] Ag24,Ag25,Ag26,Ag27,Ag28,Ag29,Ag30,Ag31;
    wire done_g;

    ntt_pipelined #(.DATA_WIDTH(DATA_WIDTH),.Q(Q),.N(N)) ntt_f (
        .clk(clk),.rst_n(rst_n),.start(start),
        .a0(f0),.a1(f1),.a2(f2),.a3(f3),
        .a4(f4),.a5(f5),.a6(f6),.a7(f7),
        .a8(f8),.a9(f9),.a10(f10),.a11(f11),
        .a12(f12),.a13(f13),.a14(f14),.a15(f15),
        .a16(f16),.a17(f17),.a18(f18),.a19(f19),
        .a20(f20),.a21(f21),.a22(f22),.a23(f23),
        .a24(f24),.a25(f25),.a26(f26),.a27(f27),
        .a28(f28),.a29(f29),.a30(f30),.a31(f31),
        .F0(Af0),.F1(Af1),.F2(Af2),.F3(Af3),
        .F4(Af4),.F5(Af5),.F6(Af6),.F7(Af7),
        .F8(Af8),.F9(Af9),.F10(Af10),.F11(Af11),
        .F12(Af12),.F13(Af13),.F14(Af14),.F15(Af15),
        .F16(Af16),.F17(Af17),.F18(Af18),.F19(Af19),
        .F20(Af20),.F21(Af21),.F22(Af22),.F23(Af23),
        .F24(Af24),.F25(Af25),.F26(Af26),.F27(Af27),
        .F28(Af28),.F29(Af29),.F30(Af30),.F31(Af31),
        .done(done_f)
    );

    ntt_pipelined #(.DATA_WIDTH(DATA_WIDTH),.Q(Q),.N(N)) ntt_g (
        .clk(clk),.rst_n(rst_n),.start(start),
        .a0(g0),.a1(g1),.a2(g2),.a3(g3),
        .a4(g4),.a5(g5),.a6(g6),.a7(g7),
        .a8(g8),.a9(g9),.a10(g10),.a11(g11),
        .a12(g12),.a13(g13),.a14(g14),.a15(g15),
        .a16(g16),.a17(g17),.a18(g18),.a19(g19),
        .a20(g20),.a21(g21),.a22(g22),.a23(g23),
        .a24(g24),.a25(g25),.a26(g26),.a27(g27),
        .a28(g28),.a29(g29),.a30(g30),.a31(g31),
        .F0(Ag0),.F1(Ag1),.F2(Ag2),.F3(Ag3),
        .F4(Ag4),.F5(Ag5),.F6(Ag6),.F7(Ag7),
        .F8(Ag8),.F9(Ag9),.F10(Ag10),.F11(Ag11),
        .F12(Ag12),.F13(Ag13),.F14(Ag14),.F15(Ag15),
        .F16(Ag16),.F17(Ag17),.F18(Ag18),.F19(Ag19),
        .F20(Ag20),.F21(Ag21),.F22(Ag22),.F23(Ag23),
        .F24(Ag24),.F25(Ag25),.F26(Ag26),.F27(Ag27),
        .F28(Ag28),.F29(Ag29),.F30(Ag30),.F31(Ag31),
        .done(done_g)
    );

    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul0  (.A(Af0), .B(Ag0), .out(C0));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul1  (.A(Af1), .B(Ag1), .out(C1));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul2  (.A(Af2), .B(Ag2), .out(C2));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul3  (.A(Af3), .B(Ag3), .out(C3));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul4  (.A(Af4), .B(Ag4), .out(C4));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul5  (.A(Af5), .B(Ag5), .out(C5));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul6  (.A(Af6), .B(Ag6), .out(C6));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul7  (.A(Af7), .B(Ag7), .out(C7));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul8  (.A(Af8), .B(Ag8), .out(C8));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul9  (.A(Af9), .B(Ag9), .out(C9));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul10 (.A(Af10),.B(Ag10),.out(C10));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul11 (.A(Af11),.B(Ag11),.out(C11));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul12 (.A(Af12),.B(Ag12),.out(C12));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul13 (.A(Af13),.B(Ag13),.out(C13));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul14 (.A(Af14),.B(Ag14),.out(C14));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul15 (.A(Af15),.B(Ag15),.out(C15));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul16 (.A(Af16),.B(Ag16),.out(C16));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul17 (.A(Af17),.B(Ag17),.out(C17));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul18 (.A(Af18),.B(Ag18),.out(C18));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul19 (.A(Af19),.B(Ag19),.out(C19));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul20 (.A(Af20),.B(Ag20),.out(C20));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul21 (.A(Af21),.B(Ag21),.out(C21));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul22 (.A(Af22),.B(Ag22),.out(C22));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul23 (.A(Af23),.B(Ag23),.out(C23));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul24 (.A(Af24),.B(Ag24),.out(C24));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul25 (.A(Af25),.B(Ag25),.out(C25));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul26 (.A(Af26),.B(Ag26),.out(C26));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul27 (.A(Af27),.B(Ag27),.out(C27));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul28 (.A(Af28),.B(Ag28),.out(C28));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul29 (.A(Af29),.B(Ag29),.out(C29));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul30 (.A(Af30),.B(Ag30),.out(C30));
    multiplier_unit #(.DATA_WIDTH(DATA_WIDTH),.Q(Q)) mul31 (.A(Af31),.B(Ag31),.out(C31));

    assign done = done_f & done_g;
endmodule