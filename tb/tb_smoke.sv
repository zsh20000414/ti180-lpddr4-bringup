// tb_smoke.sv — the ten-second proof that the harness runs.
//
// Drives one single-beat write and one single-beat read against stub_dut and
// prints PASS or FAIL. Deliberately dependency-free: plain Verilog tasks, no
// UVM, no cocotb, nothing to install beyond iverilog or verilator.
//
// Expected output:
//   [smoke] wrote 0xdeadbeefcafebabe to 0x00000020
//   [smoke] read  0xdeadbeefcafebabe
//   [smoke] PASS

`timescale 1ns/1ps

module tb_smoke;

    localparam ADDR_W = 32;
    localparam DATA_W = 64;
    localparam ID_W   = 4;

    reg                 aclk = 1'b0;
    reg                 aresetn = 1'b0;

    reg  [ID_W-1:0]     awid = '0;
    reg  [ADDR_W-1:0]   awaddr = '0;
    reg  [7:0]          awlen = 8'd0;
    reg                 awvalid = 1'b0;
    wire                awready;

    reg  [DATA_W-1:0]   wdata = '0;
    reg  [DATA_W/8-1:0] wstrb = '0;
    reg                 wlast = 1'b0;
    reg                 wvalid = 1'b0;
    wire                wready;

    wire [ID_W-1:0]     bid;
    wire [1:0]          bresp;
    wire                bvalid;
    reg                 bready = 1'b0;

    reg  [ID_W-1:0]     arid = '0;
    reg  [ADDR_W-1:0]   araddr = '0;
    reg  [7:0]          arlen = 8'd0;
    reg                 arvalid = 1'b0;
    wire                arready;

    wire [ID_W-1:0]     rid;
    wire [DATA_W-1:0]   rdata;
    wire [1:0]          rresp;
    wire                rlast;
    wire                rvalid;
    reg                 rready = 1'b0;

    integer errors = 0;
    reg [DATA_W-1:0] captured;

    stub_dut #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .ID_W(ID_W)) dut (
        .aclk(aclk), .aresetn(aresetn),
        .awid(awid), .awaddr(awaddr), .awlen(awlen), .awvalid(awvalid), .awready(awready),
        .wdata(wdata), .wstrb(wstrb), .wlast(wlast), .wvalid(wvalid), .wready(wready),
        .bid(bid), .bresp(bresp), .bvalid(bvalid), .bready(bready),
        .arid(arid), .araddr(araddr), .arlen(arlen), .arvalid(arvalid), .arready(arready),
        .rid(rid), .rdata(rdata), .rresp(rresp), .rlast(rlast), .rvalid(rvalid), .rready(rready)
    );

    always #5 aclk = ~aclk;

    task write_word(input [ID_W-1:0] id, input [ADDR_W-1:0] addr, input [DATA_W-1:0] data);
        begin
            @(posedge aclk);
            awid    <= id;
            awaddr  <= addr;
            awlen   <= 8'd0;
            awvalid <= 1'b1;
            wdata   <= data;
            wstrb   <= {DATA_W/8{1'b1}};
            wlast   <= 1'b1;
            wvalid  <= 1'b1;
            bready  <= 1'b1;
            // wait for both address and data to be accepted
            fork
                begin : wait_aw
                    while (!(awvalid && awready)) @(posedge aclk);
                end
                begin : wait_w
                    while (!(wvalid && wready)) @(posedge aclk);
                end
            join
            @(posedge aclk);
            awvalid <= 1'b0;
            wvalid  <= 1'b0;
            wlast   <= 1'b0;
            while (!(bvalid && bready)) @(posedge aclk);
            @(posedge aclk);
            bready  <= 1'b0;
        end
    endtask

    task read_word(input [ID_W-1:0] id, input [ADDR_W-1:0] addr);
        begin
            @(posedge aclk);
            arid    <= id;
            araddr  <= addr;
            arlen   <= 8'd0;
            arvalid <= 1'b1;
            rready  <= 1'b1;
            while (!(arvalid && arready)) @(posedge aclk);
            @(posedge aclk);
            arvalid <= 1'b0;
            while (!rvalid) @(posedge aclk);
            captured = rdata;
            @(posedge aclk);
            rready  <= 1'b0;
        end
    endtask

    initial begin
        repeat (4) @(posedge aclk);
        aresetn <= 1'b1;
        repeat (2) @(posedge aclk);

        write_word(4'h1, 32'h0000_0020, 64'hdead_beef_cafe_babe);
        $display("[smoke] wrote %016h to %08h", 64'hdead_beef_cafe_babe, 32'h0000_0020);

        read_word(4'h1, 32'h0000_0020);
        $display("[smoke] read  %016h", captured);

        if (captured !== 64'hdead_beef_cafe_babe) begin
            errors = errors + 1;
            $display("[smoke] mismatch: expected %016h", 64'hdead_beef_cafe_babe);
        end

        // a second address, to prove the memory is addressed rather than wired through
        write_word(4'h2, 32'h0000_0040, 64'h0123_4567_89ab_cdef);
        read_word(4'h2, 32'h0000_0040);
        if (captured !== 64'h0123_4567_89ab_cdef) begin
            errors = errors + 1;
            $display("[smoke] mismatch at 0x40: got %016h", captured);
        end

        if (errors == 0) $display("[smoke] PASS");
        else             $display("[smoke] FAIL (%0d errors)", errors);

        $finish;
    end

    initial begin
        #20000;
        $display("[smoke] FAIL (timeout)");
        $finish;
    end

endmodule
