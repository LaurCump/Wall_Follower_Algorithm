`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: UPB
// Engineer: Cumpanasoiu Laurentiu
// 
// Create Date:    13:06:59 11/22/2021 
// Design Name: 
// Module Name:    maze 
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
module maze(
	input 						     clk,
	input [maze_width-1 : 0]     starting_col, starting_row,
	input                        maze_in,
	output reg[maze_width-1 : 0] row, col,
	output reg                   maze_oe,
	output reg                   maze_we,
	output reg                   done);
	
parameter maze_width = 6;

// starile principale ale automatului nostru
`define START         		 0
`define FIRST_DIRECTION     1
`define FIRST_DISPLACEMENT	 2
`define DIRECTION     		 3
`define DISPLACEMENT  		 4
`define NEXT_POSITION     	 5
`define DISPLACEMENT_NEXT   6
`define FINISH 				 7

// directiile posibile de deplasare
parameter RIGHT = 0;
parameter DOWN  = 1;
parameter LEFT  = 2;
parameter UP    = 3;

reg [maze_width-1 : 0] row_prev, col_prev;		// variabile pentru a retine pozitia anterioara
reg [maze_width-1 : 0] row_next, col_next; 		// variabile pentru a retine pozitia viitoare 
reg [maze_width-1 : 0] row_right, col_right;			// variabile pentru a retine pozitia din dreapta celei curente

reg [4:0] state = `START, next_state;		// stari automat
reg [1:0] direction;		// variabila care imi arata directia de deplasare 

//partea secventiala
always @(posedge clk) begin
	if (done == 0)
		state <= next_state;
end

//partea combinationala	
always@(*) begin
	maze_oe = 0;
	maze_we = 0;
	done = 0;

	//algoritmul propriu-zis
	case(state)
		`START: begin	// starea initiala in care copiez coordonatele punctului de start in row si col
			direction = RIGHT; 	// caut sa ma deplasez initial la dreapta
			row = starting_row; 
			col = starting_col;
			row_prev = starting_row;
			col_prev = starting_col;
			
			maze_we = 1; 	// marcam cu 2 pozitia desemnata de indicii de start
			next_state = `FIRST_DIRECTION;
		end
		
		
		`FIRST_DIRECTION: begin		// starea in care aflam directia initiala de deplasare
			if (direction == RIGHT) begin
				col = col + 1;
			end
			if (direction == DOWN) begin
				row = row + 1;
			end
			if (direction == LEFT) begin
				col = col - 1;
			end
			if (direction == UP) begin
				row = row - 1;
			end
			
			maze_oe = 1;	// returnam informatia pe firul maze_in
			next_state = `FIRST_DISPLACEMENT;
		end
		
		
		`FIRST_DISPLACEMENT: begin 	// starea in care ne deplasam din punctul de pornire in noua pozitie
			if (maze_in == 0) begin 	// avem drum liber
				row_prev = row;
				col_prev = col;
				
				maze_we = 1;
				next_state = `DIRECTION;
			end
			
			if (maze_in == 1) begin 	// avem perete, deci ne intoarcem si incercam urmatoarea directie
				row = row_prev;
				col = col_prev;
				
				// incrementam directia
				case(direction)
					RIGHT: direction = DOWN;
					DOWN:  direction = LEFT;
					LEFT:  direction = UP;
					UP:    direction = RIGHT;
				endcase
				
				next_state = `FIRST_DIRECTION;
			end
		end
		
		
		`DIRECTION: begin 	// starea in care verific directia spre care voi merge din pozitia in care ma aflu
			case(direction)
				RIGHT: begin 	// in dreapta
					row_prev = row;
					col_prev = col;
					
					row_next = row;
					col_next = col + 1;
					
					// in partea dreapta a pozitiei in care sunt urmaresc deplasarea in jos
					row_right = row + 1; 
					col_right = col;
				end
				
				DOWN: begin 	// in jos
					row_prev = row;
					col_prev = col;
					
					row_next = row + 1;
					col_next = col;
					
					// in partea dreapta a pozitiei in care sunt urmaresc deplasarea in stanga
					row_right = row; 
					col_right = col - 1;
				end
				
				LEFT: begin 	// in stanga
					row_prev = row;
					col_prev = col;
					
					row_next = row;
					col_next = col - 1;
					
					// in partea dreapta a pozitiei in care sunt urmaresc deplasarea in sus
					row_right = row - 1; 
					col_right = col;
				end
				
				UP: begin 	// in sus
					row_prev = row;
					col_prev = col;
					
					row_next = row - 1;
					col_next = col;
					
					// in partea dreapta a pozitiei in care sunt urmaresc deplasarea in dreapta
					row_right = row; 
					col_right = col + 1;
				end
				
			endcase
			
			//ne uitam in partea dreapta a pozitiei
			row = row_right;
			col = col_right;
			
			maze_oe = 1;
			next_state = `DISPLACEMENT;
		end
		
		
		`DISPLACEMENT: begin 	// starea in care verific informatia din maze_in din partea dreapta pentru a lua o decizie si ma deplasez conform acesteia
			if (maze_in == 0) begin				
				// verificam daca e solutie
				if (row == 0 || col == 0 || row == 63 || col == 63) begin 	// daca suntem pe marginea labirintului
						row_prev = row;
						col_prev = col;
						
						maze_we = 1;
						next_state = `FINISH;  // ies din labirint
				end
					
				else begin	// mergem pe pozitia din dreapta
					row = row_right;
					col = col_right;
		
					// incrementam directia
					case(direction)
						RIGHT: direction = DOWN;
						DOWN:  direction = LEFT;
						LEFT:  direction = UP;
						UP:    direction = RIGHT;
					endcase
					
               maze_we = 1;
					next_state = `DIRECTION;
				end
					
			end		
					
			if (maze_in == 1) begin 	// mergem pe pozitia next
				next_state = `NEXT_POSITION;
			end
			
		end
			
			
		`NEXT_POSITION: begin		// starea in care mergem pe pozitia urmatoare
			row = row_next;
			col = col_next;
			
			maze_oe = 1;
			next_state = `DISPLACEMENT_NEXT;
		end
			
				
		`DISPLACEMENT_NEXT: begin 		// starea in care verificam informatia din maze_in din pozitia next pentru a lua o decizie si ma deplasez conform acesteia
			if (maze_in == 0) begin
				if (row == 0 || col == 0 || row == 63 || col == 63) begin	// daca suntem pe marginea labirintului
					row_prev = row;
					col_prev = col;
					
					maze_we = 1;
					next_state = `FINISH; 	// ies din labirint
				end
				
				else begin	 // cat suntem in interiorul labirintului
					maze_we = 1;
					next_state = `DIRECTION;
				end
				
			end
		
			if (maze_in == 1) begin   // intoarcere la stanga
				row = row_prev;
				col = col_prev;
				
				// decrementam directia
				case(direction)
					RIGHT: direction = UP;
					DOWN:  direction = RIGHT;
					LEFT:  direction = DOWN;
					UP:    direction = LEFT;
				endcase
				
				next_state = `DIRECTION;
			end
		
		end
			
		
		`FINISH: begin  	// starea finala in care am gasit iesirea din labirint
			done = 1;
		end
		
		default: ;
	
	endcase
	
end
	
endmodule
