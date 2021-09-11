//-------------------------------------------------------------------------------------------------
module zx48
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,  // 56 MHz

	input  wire       reset,
	input  wire       locked,

	input  wire       model,
	input  wire       nomap,

	output wire[ 1:0] blank,
	output wire[ 1:0] sync,
	output wire[23:0] rgb,
	output wire       pce,    // pixel ce

	input  wire       ear,
	output wire[ 9:0] laudio,
	output wire[ 9:0] raudio,

	input  wire       kstrobe,
	input  wire       kpress,
	input  wire[ 7:0] kcode,
	output wire[1:0]  kleds,

	input  wire[ 5:0] jstick,

	output wire       usdCs,
	output wire       usdCk,
	input  wire       usdMiso,
	output wire       usdMosi
);
//-------------------------------------------------------------------------------------------------

reg[3:0] ce;
always @(negedge clock) if(locked) ce <= ce+1'd1;

wire ce7M0p = locked & ~ce[0] & ~ce[1] &  ce[2];
wire ce7M0n = locked & ~ce[0] & ~ce[1] & ~ce[2];

wire ce3M5p = locked & ~ce[0] & ~ce[1] & ~ce[2] &  ce[3];
wire ce3M5n = locked & ~ce[0] & ~ce[1] & ~ce[2] & ~ce[3];

assign pce = ce7M0n;

//-------------------------------------------------------------------------------------------------

reg mreqt23iorqtw3;
always @(posedge clock) if(cc3M5p) mreqt23iorqtw3 <= mreq & ioFE & io7FFD;

reg cpuck;
always @(posedge clock) if(ce7M0n) cpuck <= !(cpuck && contend);

wire contend = !(vduCn && cpuck && mreqt23iorqtw3 && ((a[15:14] == 2'b01) || ramCn || !ioFE));

wire cc3M5p = ce3M5p & contend;
wire cc3M5n = ce3M5n & contend;

//-------------------------------------------------------------------------------------------------

wire rst = reset & keyF6;
wire nmi = keyF5;

reg mi = 1'b1;
always @(posedge clock) if(cc3M5p) mi <= vduI;

wire[ 7:0] d;
wire[ 7:0] q;
wire[15:0] a;

cpu Cpu
(
	.clock  (clock  ),
	.cep    (cc3M5p ),
	.cen    (cc3M5n ),
	.reset  (rst    ),
	.nmi    (nmi    ),
	.rfsh   (rfsh   ),
	.mreq   (mreq   ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.m1     (m1     ),
	.mi     (mi     ),
	.d      (d      ),
	.q      (q      ),
	.a      (a      )
);

//-------------------------------------------------------------------------------------------------

reg mic;
reg speaker;
reg[2:0] border;

always @(posedge clock) if(ce7M0n) if(!ioFE && !wr) { speaker, mic, border } <= q[4:0];

//-------------------------------------------------------------------------------------------------

wire[ 7:0] memQ;
wire[ 7:0] vq;
wire[12:0] va;

memory Memory
(
	.clock  (clock  ),
	.ce     (cc3M5p ),
	.reset  (rst    ),
	.model  (model  ),
	.nomap  (nomap  ),
	.rfsh   (rfsh   ),
	.iorq   (iorq   ),
	.mreq   (mreq   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.m1     (m1     ),
	.d      (q      ),
	.q      (memQ   ),
	.a      (a      ),
	.vce    (ce7M0n ),
	.vq     (vq     ),
	.va     (va     ),
	.cn     (ramCn  )
);

//-------------------------------------------------------------------------------------------------

video Video
(
	.clock  (clock  ),
	.ce     (ce7M0n ),
	.model  (model  ),
	.border (border ),
	.blank  (blank  ),
	.sync   (sync   ),
	.rgb    (rgb    ),
	.cn     (vduCn  ),
	.rd     (vduRd  ),
	.bi     (vduI   ),
	.d      (vq     ),
	.a      (va     )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] spdQ;

wire[7:0] psgA1;
wire[7:0] psgB1;
wire[7:0] psgC1;

wire[7:0] psgA2;
wire[7:0] psgB2;
wire[7:0] psgC2;

wire[7:0] saaL;
wire[7:0] saaR;

audio Audio
(
	.speaker(speaker),
	.mic    (mic    ),
	.ear    (ear    ),
	.spd    (spdQ   ),
	.a1     (psgA1  ),
	.b1     (psgB1  ),
	.c1     (psgC1  ),
	.a2     (psgA2  ),
	.b2     (psgB2  ),
	.c2     (psgC2  ),
	.saaL   (saaL   ),
	.saaR   (saaR   ),
	.laudio (laudio ),
	.raudio (raudio )
);

//-------------------------------------------------------------------------------------------------

wire[4:0] keyQ;
wire[7:0] keyA = a[15:8];

keyboard Keyboard
(
	.clock  (clock  ),
	.strobe (kstrobe),
	.pressed(kpress ),
	.code   (kcode  ),
	.leds   (kleds  ),
	.f6     (keyF6  ),
	.f5     (keyF5  ),
	.q      (keyQ   ),
	.a      (keyA   )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] usdQ;
wire[7:0] usdA = a[7:0];

usd uSD
(
	.clock  (clock  ),
	.cep    (ce7M0p ),
	.cen    (ce7M0n ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.d      (q      ),
	.q      (usdQ   ),
	.a      (usdA   ),
	.cs     (usdCs  ),
	.ck     (usdCk  ),
	.miso   (usdMiso),
	.mosi   (usdMosi)
);

//-------------------------------------------------------------------------------------------------

wire[7:4] spdA = a[7:4];

specdrum Specdrum
(
	.clock  (clock  ),
	.ce     (ce3M5p ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.d      (q      ),
	.q      (spdQ   ),
	.a      (spdA   )
);

//-------------------------------------------------------------------------------------------------

wire[ 7: 0] psgQ;
wire[15:14] psgAh = a[15:14];
wire[ 1: 1] psgAl = a[1];

turbosound Turbosound
(
	.clock  (clock  ),
	.ce     (ce3M5p ),
	.reset  (rst    ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.d      (q      ),
	.ah     (psgAh  ),
	.al     (psgAl  ),
	.q      (psgQ   ),
	.a1     (psgA1  ),
	.b1     (psgB1  ),
	.c1     (psgC1  ),
	.a2     (psgA2  ),
	.b2     (psgB2  ),
	.c2     (psgC2  )
);

//-------------------------------------------------------------------------------------------------

reg[2:0] saac;
wire saace = saac == 6;
always @(posedge clock) if(saace) saac <= 1'd0; else saac <= saac+1'd1;

saa1099 saa1099
(
	.clk_sys(clock  ),
	.ce     (saace  ),
	.rst_n  (rst    ),
	.cs_n   (!(!ioFF && !wr)),
	.a0     (a[8]   ),
	.wr_n   (wr     ),
	.din    (q      ),
	.out_l  (saaL   ),
	.out_r  (saaR   )
);

//-------------------------------------------------------------------------------------------------

wire ioFE = !(!iorq && !a[0]);                     // ula
wire io1F = !(!iorq && !a[5]);                     // kempston
wire ioEB = !(!iorq && a[7:0] == 8'hEB);           // usd
wire ioFF = !(!iorq && a[7:0] == 8'hFF);           // saa
wire ioFFFD = !(!iorq && a[15] && a[14] && !a[1]); // psg
wire io7FFD = !(!iorq && !a[15] && !a[1]);         // paging

assign d
	= !mreq ? memQ
	: !ioEB ? usdQ
	: !io1F ? { 2'b00, jstick }
	: !ioFE ? { 1'b1, ear|speaker, 1'b1, keyQ }
	: !ioFFFD ? psgQ
	: !iorq & vduRd ? vq
	: 8'hFF;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
