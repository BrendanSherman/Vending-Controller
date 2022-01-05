/* Author - Brendan Sherman (shermabk@bc.edu)
 * Computer Organization Final Project
 * Vending Machine Design
 */

`define cost1 = 4'b0010 //item 1: $2
`define cost2 = 4'b0011 //item 2: $3
`define cost3 = 4'b0100	//item 3: $5

//Register - stores initial balance using switch inputs for (in) and (load)
module Register4Bit(
	input clock,
	input clear,
	input load,
	input [3:0] in,
	output reg[3:0] out
	output reg[1:0] state);

	always @(negedge clock, posedge clear)
		if (clear)
			out = 0;
		else if (load) begin
			out = in;
			state = 2'b00;
		end
endmodule

//Determines item purchased based on button input (item)
module Mux4Bit4To1(
	input [3:0] item_selector,
	output reg [3:0] out);
		
	always(@item_selector)
		if(item_selector == 3'b000)
			out = 4'b0000;
		else if(item_selector == 3'b001)
			out = cost1;
		else if(item_selector == 3'b010)
			out = cost2;
		else if(item_selector == 3'b100)
			out = cost3;

endmodule

//Determines whether to output change or previous balance and error, based on comparator output
module Mux4Bit2to1
	input gt,
	input[3:0] change,
	input[3:0] prev_balance,
	output reg [3:0] out,
	output reg [1:0] state);

	always(@change, prev_balance, gt)
		if(gt == 1) begin
			out = change;
			state = 2'b10;
		end
		else if(gt == 0) begin
			out = prev_balance;
			state = 2'b11
		end
endmodule

//Subtracts cost of item, determined by mux, from current balance
module Subtractor4Bit(
	input[3:0] balance,
	input[3:0] item_cost,
	output [3:0] change);
	
	assign change = balance - item_cost;
endmodule

//Outputs controller state to 7 segment decoder
module StateDecoder(
	input[2:0] state,
	output reg[6:0] segments);
	
	always @(state)
		case(state)
			1: segments = 7'b1000010; //"d" = default
			2: segments = 7'b1110010; //"c" = change
			3: segments = 7'b0110000; //"E" = error
			default: segments = 7'bxxxxxxx;
		endcase
endmodule

//Outputs balance to 7 segment decoder 
module SevenSegmentDecoder(
	input[3:0] x
	output reg[6:0] segments);
	
	always @(x)
		case(x)
			0: segments = 7'b1000000;
			1: segments = 7'b1111001;
			2: segments = 7'b0100100;
			3: segments = 7'b0110000;
			4: segments = 7'b0011001;
			5: segments = 7'b0010010;
			6: segments = 7'b0000010;
			7: segments = 7'b1111000;
			8: segments = 7'b0000000;
			9: segments = 7'b0010000;
			default: segments = 7'bxxxxxxx;
		endcase
endmodule

//Outputs 1 if the balance is greater than the item_cost
module Comparator4Bit(
	input [3:0] a, //cost
	input [3:0] b // balance,
	output gt);

	wire w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15, w16;
	wire f1, f2, f3, f4; //Final outputs for each case

	//Case 1 (A3 && !B3)
	not g1(w1, b[3]) //B3' 
	and g2(f1, a[3], w1);

	//Case 2 (A3 XNOR B3) && A2 && !B2
	not g3(w2, b[2]); //B2'
	xnor g4(w3, a[3], b[3]); //A3 = B3
	and(w4, a[2], g3); 
	and(f2, w3, w4);  

	//Case 3 (A3 XNOR B3) && (A2 XNOR B2) && A1 && !B1
	not g5(w5, b[1]); //B1'
	xnor g6(w6, a[2], b[2]); // A2 = B2
	and g9(w9, a[1], g5);
	and g8(w8, w9, w6);
	and g7(f3, w8, w3);

	//Case 4 (A3 XNOR B3) && (A2 XNOR B2) && (A1 XNOR B1) && A0 && !B0
	not g10(w10, b[0]); //B0'
	xnor g11(w11, a[1], b[1]); // A1 = B1
	and g12(w12, a[0], g10);
	and g13(w13, w12, g11);
	and g14(w14, w13, w6);
	and g15(f4, w14, w3);

	// gt = Case 1 || Case 2 ||  Case 3 || Case 4
	or g16(w15, f1, f2);
	or g17(w16, f3, f4);
	or g18(gt, w15, w16);
	
endmodule

//final schematic circuit
module VendingMachine(
	input clock,
	input clear,
	input load,
	input [3:0] balance,
	input [3:0] item_selector);
	
	wire [3:0] w1, w2, w3, w4;	
	wire gt;
	wire [1:0] state;

	output [6:0] segments;	
	output [6:0] segments2;

	Register4Bit balanceReg(clock, clear, load, balance, w1, state); //w1 balance
	Mux4Bit4To1  item_costs(item_selector, w2); //w2 = cost
	Comparator4Bit comp(w1, w2, gt);  //gt = balance > cost
	Subtractor4Bit subtractor(w1, w2, w3); //w3 = balance - cost (change)
	
	Mux4Bit2To1 verifier(gt, w3, w1, w4, state); //w4 = change or previous balance 
	
	
	SevenSegmentDecoder(w4, segments);	
	StateDecoder(state, segments2); 	 	
endmodule
	
