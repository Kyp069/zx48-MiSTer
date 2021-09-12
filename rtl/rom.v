//-------------------------------------------------------------------------------------------------
module rom
//-------------------------------------------------------------------------------------------------
#
(
	parameter KB = 0,
	parameter FN = ""
)
(
	input  wire                      clock,
	input  wire                      ce,
	output reg [                7:0] q,
	input  wire[$clog2(KB*1024)-1:0] a
);
//-------------------------------------------------------------------------------------------------

reg[7:0] rom[(KB*1024)-1:0];
initial if(FN != "") $readmemh(FN, rom, 0);

always @(posedge clock) if(ce) q <= rom[a];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
