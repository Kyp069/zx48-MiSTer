//-------------------------------------------------------------------------------------------------
module memory
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	input  wire       ce,

	input  wire       reset,
	input  wire       rfsh,
	input  wire       iorq,
	input  wire       mreq,
	input  wire       wr,
	input  wire       rd,
	input  wire       m1,
	input  wire[ 7:0] d,
	output wire[ 7:0] q,
	input  wire[15:0] a,

	input  wire       vce,
	output wire[ 7:0] vq,
	input  wire[12:0] va
);
//-------------------------------------------------------------------------------------------------

reg forcemap;
reg automap;
reg mapram;
reg m1on;
reg[3:0] mappage;

always @(posedge clock) if(ce)
if(!reset)
begin
	forcemap <= 1'b0;
	automap <= 1'b0;
	mappage <= 4'd0;
	mapram <= 1'b0;
	m1on <= 1'b0;
end
else
begin
	if(!iorq && !wr && a[7:0] == 8'hE3)
	begin
		forcemap <= d[7];
		mappage <= d[3:0];
		mapram <= d[6]|mapram;
	end

	if(!mreq && !m1)
	begin
		if(a == 16'h0000 || a == 16'h0008 || a == 16'h0038 || a == 16'h0066 || a == 16'h04C6 || a == 16'h0562)
			m1on <= 1'b1; // activate automapper after this cycle

		else if(a[15:3] == 13'h3FF)
			m1on <= 1'b0; // deactivate automapper after this cycle

		else if(a[15:8] == 8'h3D)
		begin
			m1on <= 1'b1; // activate automapper immediately
			automap <= 1'b1;
		end
	end

	if(m1) automap <= m1on;
end

wire map = forcemap || automap;
wire[3:0] page = !a[13] && mapram ? 4'd3 : mappage;

//-------------------------------------------------------------------------------------------------

wire[ 7:0] romQ;
wire[13:0] romA = a[13:0];

rom #(.KB(16), .FN("48.hex")) Rom
(
	.clock  (clock  ),
	.ce     (ce     ),
	.q      (romQ   ),
	.a      (romA   )
);

//-------------------------------------------------------------------------------------------------

wire[13:0] dprA1 = { 1'b0, va[12:7], !rfsh && mem01 ? a[6:0] : va[6:0] };

wire       dprWe2 = !(!mreq && !wr && mem01);
wire[ 7:0] dprQ2;
wire[13:0] dprA2 = a[13:0];

dprf #(.KB(16)) Dpr
(
	.clock  (clock  ),
	.ce1    (vce    ),
	.q1     (vq     ),
	.a1     (dprA1  ),
	.ce2    (ce     ),
	.we2    (dprWe2 ),
	.d2     (d      ),
	.q2     (dprQ2  ),
	.a2     (dprA2  )
);

//-------------------------------------------------------------------------------------------------

wire       ramWe = !(!mreq && !wr && mem1x);
wire[ 7:0] ramQ;
wire[14:0] ramA = a[14:0];

ram #(.KB(32)) Ram
(
	.clock  (clock  ),
	.ce     (ce     ),
	.we     (ramWe  ),
	.d      (d      ),
	.q      (ramQ   ),
	.a      (ramA   )
);

//-------------------------------------------------------------------------------------------------

wire[ 7:0] xroQ;
wire[12:0] xroA = a[12:0];

rom #(.KB(8), .FN("esxdos.hex")) EsxRom
(
	.clock  (clock  ),
	.ce     (ce     ),
	.q      (xroQ   ),
	.a      (xroA   )
);

//-------------------------------------------------------------------------------------------------

wire       xraWe = !(!mreq && !wr && mem001);
wire[ 7:0] xraQ;
wire[16:0] xraA = { page, a[12:0] };

ram #(.KB(128)) EsxRam
(
	.clock  (clock  ),
	.ce     (ce     ),
	.we     (xraWe  ),
	.d      (d      ),
	.q      (xraQ   ),
	.a      (xraA   )
);

//-------------------------------------------------------------------------------------------------

wire mem00 = a[15:14] == 2'b00;
wire mem01 = a[15:14] == 2'b01;
wire mem1x = a[15];

wire mem000 = mem00 && !a[13] && map;
wire mem001 = mem00 &&  a[13] && map;

assign q = mem000 ? (mapram ? xraQ : xroQ) : mem001 ? xraQ : mem00 ? romQ : mem01 ? dprQ2 : ramQ;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
