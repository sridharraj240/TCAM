`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:15:28 08/25/2022 
// Design Name: 
// Module Name:    w1601 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module tcamblock64x20 #(parameter W=80,D=512) (sk,reset,we,rules,clk,match,cin);

parameter kw_size=20;    // block64x5 key width size
parameter b_depth = 64;     // block depth
input [W-1:0] sk;
input reset;
input [D-1:0] we;
input [W*8/5-1:0] rules;
input clk;
output [D-1:0] match;
input [D-1:0] cin ;
wire [D-1:0] match1,match2,match3;


      
(* dont_touch = "true" *) block64x20 #(kw_size,D) block64x20_inst (sk[19:0],reset,we,rules[7:0],clk,cin,match1[D-1:0]);
(* dont_touch = "true" *) block64x20 #(kw_size,D) block64x20_inst1 (sk[39:20],reset,we,rules[15:8],clk,match1[D-1:0],match2[D-1:0]);
(* dont_touch = "true" *) block64x20 #(kw_size,D) block64x20_inst2 (sk[59:40],reset,we,rules[23:16],clk,match2[D-1:0],match3[D-1:0]);
(* dont_touch = "true" *) block64x20 #(kw_size,D) block64x20_inst3 (sk[79:60],reset,we,rules[31:24],clk,match3[D-1:0],match[D-1:0]);
	 
endmodule

//depth extension

module block64x20 #(parameter kw_size=20,D=64)(sk,clr,we,rules,clk,cin,match);
parameter rd_size=4;   // block rule depth size
parameter we_size=4;
input [kw_size-1:0] sk;
input clr;
input  [D-1:0]cin;
input [D-1:0] we;
input [7:0] rules;
input clk;
output [D-1:0] match;
genvar i;
generate
for (i=0;i<D/8;i=i+1)
begin:depth_extension
block4X20 #(kw_size,rd_size,we_size) block8X20_inst0(sk,clr,we[i*4+3:i*4],rules,clk,cin[i*4+3:i*4], match[i*4+3:i*4]);
end
endgenerate

endmodule

//4slice
module block4X20#(parameter kw_size=20,rd_size=4, we_size=4)(
    input [kw_size-1:0] sk,
    input clr,
    input [we_size-1:0] we,
    input [7:0] rules,
    input wclk,
	 input [rd_size-1:0]CIN,
    output [rd_size-1:0] match
    );
    
genvar i;
    generate 
    for (i=0; i<rd_size; i=i+1)
    begin:block8X20
    block1X20 block2X20_inst (
    .sk(sk),
    .clr(clr),
    .we(we[i]),
    .rules(rules),
    .wclk(wclk),
	 .CI(CIN[i]),
    .match(match[i])
    );
    end
    endgenerate    
endmodule




 
module block1X20(sk,clr,we,rules,wclk,CI,match);
    input [19:0] sk;
    input clr;
    input we;
    input [7:0] rules;
    input wclk;
	 input CI;
     output match;
    
wire [7:0] match1;
wire[3:0] co5,co6; 

tcam8x5 tcam8x5_inst(sk,clr,we,rules,wclk,match1);


(* H_SET = "uset0", RLOC = "X0Y0" *) (* dont_touch = "true" *)    CARRY4 CARRY4_inst6 (
      .CO(co6),         // 4-bit carry out
      .O(),           // 4-bit carry chain XOR data out
      .CI(CI),         // 1-bit carry cascade input
      .CYINIT(1'b0), // 1-bit carry initialization
      .DI({match1[1],match1[3],match1[5],match1[7]}),         // 4-bit carry-MUX data in
      .S({match1[0],match1[2],match1[4],match1[6]})            // 4-bit carry-MUX select input
   );
	
	assign match=co6[3];
endmodule
	
module tcam8x5(
    input [19:0] sk,
    input clr,
    input we,
    input [7:0] rules,
    input wclk,
  output [7:0] match
    );
    wire [3:0] o5,o6;

  
      
   (* H_SET = "uset0", RLOC = "X0Y0" *) (* dont_touch = "true" *)  RAM32M #(
      .INIT_A(64'h8000000800000000), // Initial contents of A Port
      .INIT_B(64'h8000000800000000), // Initial contents of B Port
      .INIT_C(64'h8000000800000000), // Initial contents of C Port
      .INIT_D(64'h8000000800000000)  // Initial contents of D Port
   ) RAM32M_inst (
      .DOA({o6[0],o5[0]}),     // Read port A 2-bit output
      .DOB({o6[1],o5[1]}),     // Read port B 2-bit output
      .DOC({o6[2],o5[2]}),     // Read port C 2-bit output
      .DOD({o6[3],o5[3]}),     // Read/write port D 2-bit output
      .ADDRA(sk[4:0]), // Read port A 5-bit address input
      .ADDRB(sk[9:5]), // Read port B 5-bit address input
      .ADDRC(sk[14:10]), // Read port C 5-bit address input
      .ADDRD(sk[19:15]), // Read/write port D 5-bit address input
      .DIA(rules[1:0]),     // RAM 2-bit data write input addressed by ADDRD, 
                     //   read addressed by ADDRA
      .DIB(rules[3:2]),     // RAM 2-bit data write input addressed by ADDRD, 
                     //   read addressed by ADDRB
      .DIC(rules[5:4]),     // RAM 2-bit data write input addressed by ADDRD, 
                     //   read addressed by ADDRC
      .DID(rules[7:6]),     // RAM 2-bit data write input addressed by ADDRD, 
                     //   read addressed by ADDRD
      .WCLK(wclk),   // Write clock input
      .WE(we)        // Write enable input
   );
   
   
			
genvar i;
generate 
for (i=0; i<4; i=i+1)
begin:o5_o6_DFF
(* H_SET = "uset0", RLOC = "X0Y0" *) (* dont_touch = "true" *) (*BEL ="SLICE_X0Y0/BFF"*)FDRE #(
      .INIT(1'b0) // Initial value of register (1'b0 or 1'b1)
   ) FDRE_inst1 (
      .Q(match[i*2]),      // 1-bit Data output
      .C(wclk),      // 1-bit Clock input
      .CE(1'b1),    // 1-bit Clock enable input
      .R(clr),      // 1-bit Synchronous reset input
      .D(o5[i])       // 1-bit Data input
   );

 
   (* H_SET = "uset0", RLOC = "X0Y0" *) (* dont_touch = "true" *)(*BEL ="SLICE_X0Y0/BFF"*) FDRE #(
      .INIT(1'b0) // Initial value of register (1'b0 or 1'b1)
   ) FDRE_inst (
      .Q(match[(i*2)+1]),      // 1-bit Data output
      .C(wclk),      // 1-bit Clock input
      .CE(1'b1),    // 1-bit Clock enable input
      .R(clr),      // 1-bit Synchronous reset input
      .D(o6[i])       // 1-bit Data input
   );



  
end
endgenerate							

endmodule

