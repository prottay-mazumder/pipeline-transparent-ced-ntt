`timescale 1ns / 1ps
// ============================================================
//  tb_top_pipelined.v  --  Vivado testbench for top_pipelined
// ============================================================
module tb_top_pipelined;

    localparam DATA_WIDTH = 7;
    localparam Q          = 97;
    localparam N          = 32;
    localparam CLK_PERIOD = 10;

    // -------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------
    reg clk, rst_n, start;

    reg  [DATA_WIDTH-1:0] f [0:N-1];
    reg  [DATA_WIDTH-1:0] g [0:N-1];
    wire [DATA_WIDTH-1:0] C [0:N-1];
    wire done;

    integer fail_count;

    // -------------------------------------------------------
    // Module-level scratch arrays (no local decls in blocks)
    // -------------------------------------------------------
    integer sw_f   [0:N-1];
    integer sw_g   [0:N-1];
    integer ref_F  [0:N-1];
    integer ref_G  [0:N-1];
    integer ref_C  [0:N-1];
    integer ref_C1 [0:N-1];
    integer ref_C2 [0:N-1];
    integer tmp    [0:N-1];

    integer i, j, stage, half, tw_idx;
    integer u, v, w, seed, rev, x, bit, timeout;

    // -------------------------------------------------------
    // Clock
    // -------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------
    top_pipelined #(
        .DATA_WIDTH(DATA_WIDTH),
        .Q(Q),
        .N(N)
    ) dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .f0(f[0]),   .f1(f[1]),   .f2(f[2]),   .f3(f[3]),
        .f4(f[4]),   .f5(f[5]),   .f6(f[6]),   .f7(f[7]),
        .f8(f[8]),   .f9(f[9]),   .f10(f[10]), .f11(f[11]),
        .f12(f[12]), .f13(f[13]), .f14(f[14]), .f15(f[15]),
        .f16(f[16]), .f17(f[17]), .f18(f[18]), .f19(f[19]),
        .f20(f[20]), .f21(f[21]), .f22(f[22]), .f23(f[23]),
        .f24(f[24]), .f25(f[25]), .f26(f[26]), .f27(f[27]),
        .f28(f[28]), .f29(f[29]), .f30(f[30]), .f31(f[31]),
        .g0(g[0]),   .g1(g[1]),   .g2(g[2]),   .g3(g[3]),
        .g4(g[4]),   .g5(g[5]),   .g6(g[6]),   .g7(g[7]),
        .g8(g[8]),   .g9(g[9]),   .g10(g[10]), .g11(g[11]),
        .g12(g[12]), .g13(g[13]), .g14(g[14]), .g15(g[15]),
        .g16(g[16]), .g17(g[17]), .g18(g[18]), .g19(g[19]),
        .g20(g[20]), .g21(g[21]), .g22(g[22]), .g23(g[23]),
        .g24(g[24]), .g25(g[25]), .g26(g[26]), .g27(g[27]),
        .g28(g[28]), .g29(g[29]), .g30(g[30]), .g31(g[31]),
        .C0(C[0]),   .C1(C[1]),   .C2(C[2]),   .C3(C[3]),
        .C4(C[4]),   .C5(C[5]),   .C6(C[6]),   .C7(C[7]),
        .C8(C[8]),   .C9(C[9]),   .C10(C[10]), .C11(C[11]),
        .C12(C[12]), .C13(C[13]), .C14(C[14]), .C15(C[15]),
        .C16(C[16]), .C17(C[17]), .C18(C[18]), .C19(C[19]),
        .C20(C[20]), .C21(C[21]), .C22(C[22]), .C23(C[23]),
        .C24(C[24]), .C25(C[25]), .C26(C[26]), .C27(C[27]),
        .C28(C[28]), .C29(C[29]), .C30(C[30]), .C31(C[31]),
        .done(done)
    );

    // -------------------------------------------------------
    // Helper functions
    // -------------------------------------------------------
    function integer mod_mul;
        input integer a, b, m;
        reg [63:0] p;
        begin
            p = a * b;
            mod_mul = p % m;
        end
    endfunction

    function integer mod_add;
        input integer a, b, m;
        integer s;
        begin
            s = a + b;
            mod_add = (s >= m) ? s - m : s;
        end
    endfunction

    function integer mod_sub;
        input integer a, b, m;
        integer d;
        begin
            d = a - b;
            mod_sub = (d < 0) ? d + m : d;
        end
    endfunction

    function integer twiddle;
        input integer k;
        integer tw, ii;
        begin
            tw = 1;
            for (ii = 0; ii < k; ii = ii + 1)
                tw = mod_mul(tw, 19, Q);
            twiddle = tw;
        end
    endfunction

    // -------------------------------------------------------
    // sw_ntt_f: DIF NTT of sw_f[] -> ref_F[]
    // sw_ntt_g: DIF NTT of sw_g[] -> ref_G[]
    // (two copies to avoid passing arrays as task arguments)
    // -------------------------------------------------------
    task sw_ntt_f;
        begin
            for (i = 0; i < N; i = i + 1) tmp[i] = sw_f[i];

            for (stage = 0; stage < 5; stage = stage + 1) begin
                half = N >> (stage + 1);
                for (j = 0; j < N; j = j + 2*half) begin
                    for (i = 0; i < half; i = i + 1) begin
                        tw_idx = i * (1 << stage);
                        w = twiddle(tw_idx);
                        u = tmp[j + i];
                        v = tmp[j + i + half];
                        tmp[j + i]        = mod_add(u, v, Q);
                        tmp[j + i + half] = mod_mul(w, mod_sub(u, v, Q), Q);
                    end
                end
            end

            for (i = 0; i < N; i = i + 1) begin
                rev = 0; x = i;
                for (bit = 0; bit < 5; bit = bit + 1) begin
                    rev = (rev << 1) | (x & 1);
                    x   = x >> 1;
                end
                ref_F[rev] = tmp[i];
            end
        end
    endtask

    task sw_ntt_g;
        begin
            for (i = 0; i < N; i = i + 1) tmp[i] = sw_g[i];

            for (stage = 0; stage < 5; stage = stage + 1) begin
                half = N >> (stage + 1);
                for (j = 0; j < N; j = j + 2*half) begin
                    for (i = 0; i < half; i = i + 1) begin
                        tw_idx = i * (1 << stage);
                        w = twiddle(tw_idx);
                        u = tmp[j + i];
                        v = tmp[j + i + half];
                        tmp[j + i]        = mod_add(u, v, Q);
                        tmp[j + i + half] = mod_mul(w, mod_sub(u, v, Q), Q);
                    end
                end
            end

            for (i = 0; i < N; i = i + 1) begin
                rev = 0; x = i;
                for (bit = 0; bit < 5; bit = bit + 1) begin
                    rev = (rev << 1) | (x & 1);
                    x   = x >> 1;
                end
                ref_G[rev] = tmp[i];
            end
        end
    endtask

    task compute_reference;
        begin
            for (i = 0; i < N; i = i + 1) begin
                sw_f[i] = f[i];
                sw_g[i] = g[i];
            end
            sw_ntt_f;
            sw_ntt_g;
            for (i = 0; i < N; i = i + 1)
                ref_C[i] = mod_mul(ref_F[i], ref_G[i], Q);
        end
    endtask

    // -------------------------------------------------------
    // Control tasks
    // -------------------------------------------------------
    task apply_and_wait;
        begin
            @(posedge clk); #1;
            start = 1;
            @(posedge clk); #1;
            start = 0;
            timeout = 0;
            while (!done && timeout < 50) begin
                @(posedge clk); #1;
                timeout = timeout + 1;
            end
            if (!done) begin
                $error("TIMEOUT: done never asserted");
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_all_outputs;
        begin
            for (i = 0; i < N; i = i + 1) begin
                if (C[i] !== ref_C[i]) begin
                    $error("FAIL C[%0d]: got %0d, expected %0d", i, C[i], ref_C[i]);
                    fail_count = fail_count + 1;
                end
            end
        end
    endtask

    task zero_inputs;
        begin
            for (i = 0; i < N; i = i + 1) begin
                f[i] = 0;
                g[i] = 0;
            end
        end
    endtask

    // -------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------
    initial begin
        fail_count = 0;
        $display("=== NTT convolution testbench start ===");

        rst_n = 0; start = 0;
        zero_inputs;
        repeat(4) @(posedge clk);
        #1; rst_n = 1;
        @(posedge clk); #1;

        // TC1: All-zeros
        $display("TC1: all-zeros");
        zero_inputs;
        compute_reference;
        apply_and_wait;
        check_all_outputs;
        $display("TC1 done");

        // TC2: Unit impulse
        $display("TC2: unit impulse");
        zero_inputs;
        f[0] = 1; g[0] = 1;
        compute_reference;
        apply_and_wait;
        check_all_outputs;
        $display("TC2 done");

        // TC3: Ramp x all-ones
        $display("TC3: ramp x all-ones");
        for (i = 0; i < N; i = i + 1) begin
            f[i] = (i + 1) % Q;
            g[i] = 1;
        end
        compute_reference;
        apply_and_wait;
        check_all_outputs;
        $display("TC3 done");

        // TC4: Pseudo-random
        $display("TC4: pseudo-random inputs");
        seed = 32'hDEADBEEF;
        for (i = 0; i < N; i = i + 1) begin
            seed = seed ^ (seed << 13);
            seed = seed ^ (seed >> 17);
            seed = seed ^ (seed << 5);
            f[i] = ((seed >> 4) & 7'h7F) % Q;
            seed = seed ^ (seed << 13);
            seed = seed ^ (seed >> 17);
            seed = seed ^ (seed << 5);
            g[i] = ((seed >> 4) & 7'h7F) % Q;
        end
        compute_reference;
        apply_and_wait;
        check_all_outputs;
        $display("TC4 done");

        // TC5: Back-to-back
        $display("TC5: back-to-back starts");

        for (i = 0; i < N; i = i + 1) begin
            f[i] = (2*i + 3) % Q;
            g[i] = (3*i + 5) % Q;
        end
        compute_reference;
        for (i = 0; i < N; i = i + 1) ref_C1[i] = ref_C[i];

        @(posedge clk); #1; start = 1;
        @(posedge clk); #1; start = 0;

        for (i = 0; i < N; i = i + 1) begin
            f[i] = (5*i + 7) % Q;
            g[i] = (7*i + 11) % Q;
        end
        compute_reference;
        for (i = 0; i < N; i = i + 1) ref_C2[i] = ref_C[i];

        timeout = 0;
        while (!done && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        $display("TC5a: first result");
        for (i = 0; i < N; i = i + 1) begin
            if (C[i] !== ref_C1[i]) begin
                $error("FAIL TC5a C[%0d]: got %0d, expected %0d", i, C[i], ref_C1[i]);
                fail_count = fail_count + 1;
            end
        end

        @(posedge clk); #1; start = 1;
        @(posedge clk); #1; start = 0;
        timeout = 0;
        while (!done && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        $display("TC5b: second result");
        for (i = 0; i < N; i = i + 1) begin
            if (C[i] !== ref_C2[i]) begin
                $error("FAIL TC5b C[%0d]: got %0d, expected %0d", i, C[i], ref_C2[i]);
                fail_count = fail_count + 1;
            end
        end
        $display("TC5 done");

        // TC6: Max boundary
        $display("TC6: max inputs (all 96)");
        for (i = 0; i < N; i = i + 1) begin
            f[i] = Q - 1;
            g[i] = Q - 1;
        end
        compute_reference;
        apply_and_wait;
        check_all_outputs;
        $display("TC6 done");

        if (fail_count == 0)
            $display("=== ALL TESTS PASSED ===");
        else
            $error("=== %0d TEST(S) FAILED ===", fail_count);

        $finish;
    end

    initial begin
        #100000;
        $error("WATCHDOG: simulation exceeded time limit");
        $finish;
    end

    initial begin
        $dumpfile("tb_top_pipelined.vcd");
        $dumpvars(0, tb_top_pipelined);
    end

endmodule