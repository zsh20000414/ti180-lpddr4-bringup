// stub_dut.sv — deliberately dumb AXI4 slave used by the smoke test.
//
// It is not a model of the LPDDR4 controller. It exists so the BFM and the
// scoreboard can be built and regression-tested without the board, and so that
// "the harness works" is a claim someone else can check in ten seconds.
//
// Honest limitation: ONE outstanding transaction. A second AW or AR while one
// is in flight is not accepted (ready stays low) — which is exactly why the
// scoreboard must treat depth>1 as a failing case until a real DUT arrives.
//
// 1 KiB of storage, 8-byte words, 64-bit data, up to 16-beat bursts.

module stub_dut #(
    parameter ADDR_W = 32,
    parameter DATA_W = 64,
    parameter ID_W   = 4
) (
    input  wire                 aclk,
    input  wire                 aresetn,

    input  wire [ID_W-1:0]      awid,
    input  wire [ADDR_W-1:0]    awaddr,
    input  wire [7:0]           awlen,
    input  wire                 awvalid,
    output wire                 awready,

    input  wire [DATA_W-1:0]    wdata,
    input  wire [DATA_W/8-1:0]  wstrb,
    input  wire                 wlast,
    input  wire                 wvalid,
    output wire                 wready,

    output wire [ID_W-1:0]      bid,
    output wire [1:0]           bresp,
    output wire                 bvalid,
    input  wire                 bready,

    input  wire [ID_W-1:0]      arid,
    input  wire [ADDR_W-1:0]    araddr,
    input  wire [7:0]           arlen,
    input  wire                 arvalid,
    output wire                 arready,

    output wire [ID_W-1:0]      rid,
    output wire [DATA_W-1:0]    rdata,
    output wire [1:0]           rresp,
    output wire                 rlast,
    output wire                 rvalid,
    input  wire                 rready
);

    localparam WORDS = 128;                     // 128 * 8 B = 1 KiB
    localparam WIN   = 7;                       // word-index width

    reg [DATA_W-1:0] mem [0:WORDS-1];

    // ------------------------------------------------------------- write FSM
    localparam W_IDLE = 2'd0, W_DATA = 2'd1, W_RESP = 2'd2;

    reg [1:0]        wstate;
    reg [ID_W-1:0]   wid_q;
    reg [WIN-1:0]    widx_q;
    reg [7:0]        wlen_q;
    reg [7:0]        wbeat_q;
    reg [ID_W-1:0]   bid_q;

    assign awready = (wstate == W_IDLE);
    assign wready  = (wstate == W_DATA);
    assign bid     = bid_q;
    assign bresp   = 2'b00;                     // OKAY
    assign bvalid  = (wstate == W_RESP);

    wire [WIN-1:0] widx_beat = widx_q + wbeat_q[WIN-1:0];
    wire           waccept   = (wstate == W_DATA) && wvalid && wready;

    always @(posedge aclk) begin
        if (!aresetn) begin
            wstate  <= W_IDLE;
            wbeat_q <= 8'd0;
            wid_q   <= {ID_W{1'b0}};
            bid_q   <= {ID_W{1'b0}};
            widx_q  <= {WIN{1'b0}};
            wlen_q  <= 8'd0;
        end else begin
            case (wstate)
                W_IDLE: begin
                    if (awvalid) begin
                        wid_q  <= awid;
                        widx_q <= awaddr[WIN+2:3];
                        wlen_q <= awlen;
                        wbeat_q <= 8'd0;
                        wstate <= W_DATA;
                    end
                end
                W_DATA: begin
                    if (waccept) begin
                        if (wstrb[0]) mem[widx_beat][7:0]   <= wdata[7:0];
                        if (wstrb[1]) mem[widx_beat][15:8]  <= wdata[15:8];
                        if (wstrb[2]) mem[widx_beat][23:16] <= wdata[23:16];
                        if (wstrb[3]) mem[widx_beat][31:24] <= wdata[31:24];
                        if (wstrb[4]) mem[widx_beat][39:32] <= wdata[39:32];
                        if (wstrb[5]) mem[widx_beat][47:40] <= wdata[47:40];
                        if (wstrb[6]) mem[widx_beat][55:48] <= wdata[55:48];
                        if (wstrb[7]) mem[widx_beat][63:56] <= wdata[63:56];

                        if (wlast || wbeat_q == wlen_q) begin
                            bid_q  <= wid_q;
                            wstate <= W_RESP;
                        end else begin
                            wbeat_q <= wbeat_q + 8'd1;
                        end
                    end
                end
                W_RESP: begin
                    if (bready) wstate <= W_IDLE;
                end
                default: wstate <= W_IDLE;
            endcase
        end
    end

    // -------------------------------------------------------------- read FSM
    localparam R_IDLE = 1'b0, R_DATA = 1'b1;

    reg              rstate;
    reg [ID_W-1:0]   rid_q;
    reg [WIN-1:0]    ridx_q;
    reg [7:0]        rlen_q;
    reg [7:0]        rbeat_q;
    reg [DATA_W-1:0] rdata_q;

    assign arready = (rstate == R_IDLE);
    assign rvalid  = (rstate == R_DATA);
    assign rid     = rid_q;
    assign rdata   = rdata_q;
    assign rresp   = 2'b00;
    assign rlast   = (rstate == R_DATA) && (rbeat_q == rlen_q);

    always @(posedge aclk) begin
        if (!aresetn) begin
            rstate  <= R_IDLE;
            rbeat_q <= 8'd0;
            rid_q   <= {ID_W{1'b0}};
            ridx_q  <= {WIN{1'b0}};
            rlen_q  <= 8'd0;
            rdata_q <= {DATA_W{1'b0}};
        end else begin
            case (rstate)
                R_IDLE: begin
                    if (arvalid) begin
                        rid_q   <= arid;
                        ridx_q  <= araddr[WIN+2:3];
                        rlen_q  <= arlen;
                        rbeat_q <= 8'd0;
                        rdata_q <= mem[araddr[WIN+2:3]];
                        rstate  <= R_DATA;
                    end
                end
                R_DATA: begin
                    if (rready) begin
                        if (rbeat_q == rlen_q) begin
                            rstate <= R_IDLE;
                        end else begin
                            rbeat_q <= rbeat_q + 8'd1;
                            rdata_q <= mem[ridx_q + rbeat_q[WIN-1:0] + 1'b1];
                        end
                    end
                end
                default: rstate <= R_IDLE;
            endcase
        end
    end

endmodule
