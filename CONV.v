
`timescale 1ns/10ps

module  CONV(
	input		clk,
	input		reset,
	output reg	busy,	
	input		ready,	
			
	output reg [11:0]	iaddr,
	input[19:0]		idata,	
	
	output reg	 	cwr,
	output reg [11:0] 	caddr_wr,
	output reg [19:0]	cdata_wr,
	
	output reg	 	crd,
	output reg [11:0]caddr_rd,
	input[19:0] 	cdata_rd,
	
	output reg [2:0] 	csel
	);

reg [3:0] state , next_state;
reg [6:0] x,y;
reg [3:0] counter;
reg signed[39:0] buffer_out;
reg signed[19:0] buffer [8:0]; 
reg  signed [19:0] data;

reg [19:0] max;
reg [1:0] counter_out;

parameter	idle=0,
			read=1,
			work=2,
			out_0=3,
			out_0_temp=4,
			pooling=5,
			out_1=6,
			out_1_temp=7,
			finish=8;
always@(posedge clk or posedge reset)begin
	if(reset)
		state<=idle;
	else
		state<=next_state;
end

always@(*)begin
	case(state)
		idle:begin
			if(x == 64 && y == 64)
				next_state=pooling;
			else
				next_state=read;
		end
		read:begin
			if(counter == 0)
				next_state=work;
			else
				next_state=read;
		end
		
		work:begin
			if(counter==9)
				next_state=out_1;
			else
				next_state=work;
		end
		
		out_0:
			next_state=out_0_temp;
			
		out_0_temp:
			next_state=idle;
			
		pooling:begin
			if(counter_out==3)
				next_state=out_1;
			else
				next_state=pooling;
		end
		
		out_1:
			next_state=out_1_temp;
			
		out_1_temp:begin
			if(x==62 && y==62)
				next_state=finish;
			else
				next_state=pooling;
		end
		
		default:
			next_state = finish;
	endcase
end

//busy
always@(posedge clk or posedge reset)begin
	if(state==finish)
		busy<=0;
	else if(next_state==read)
		busy<=1;
end

//cwr
always@(* )begin
	if(state==out_0 || state==out_0_temp)
		cwr=1;
	else
		cwr=0;
end

//crd
always@(*)begin
	if(state==pooling)
		crd=1;
	else
		crd=0;
end

//counter
always@(posedge clk)begin
	if(state==idle)begin
		if(x==63)
			counter<=0;
		else if(x==0 && (y ==63 || y==0))
			counter<=3;
		else if(x==0 && (0<y && y<63))
			counter<=5;
		else if((x>0 && x<63) && (y==0 || y==63))
			counter<=1;
		else if((x>0 && x<63) && (0<y && y<63))
			counter<=2;
		end
	else if(state==read)begin
		if(counter==0)
			counter<=0;
		else
			counter<=counter-1;
	end
	else if(state==work)
		counter<=counter+1;
end

//xy
always@(posedge clk or posedge reset)begin
	if(reset)begin
		x<=0;
		y<=0;
	end
	else if(state==out_0_temp && x==63)begin
		y<=y+1;
		x<=0;
	end
	else if(y==64)begin
		x<=0;
		y<=0;
	end
	else if(state==out_1_temp && x==31)begin
		y<=y+1;
		x<=0;
	end
	else if(state==out_0_temp || state==out_1_temp)
		x<=x+1;
end

//caddr_wr
always@(*)begin
	if(state==out_0 || state==out_0_temp)
		caddr_wr= (y<<6)+x;
	else if(state==out_1 || state==out_1_temp)
		caddr_wr= (y<<5)+x;
	else
		caddr_wr=0;
end

//cdata_wr
always@(*)begin
	if(state==out_0 || state==out_0_temp)begin
		if( buffer_out > 0 && buffer_out [15] == 1 )
			cdata_wr = buffer_out [35:16] + 1;
		else if( buffer_out > 0 && buffer_out [15] == 0 )
			cdata_wr = buffer_out [35:16];
		else
			cdata_wr = 0;
	end
	else if(state==out_1 || state==out_1_temp)
		cdata_wr = max;
	else
		cdata_wr = 0;
end

//max
always@(posedge clk)begin
	if(state==idle)
		max <= 0;
	else if( state == pooling )begin
		if( cdata_rd > max )
			max <= cdata_rd;
	end
end		

//iaddr
always@(*)begin
		if(state==read )begin

			if(x==0 && y ==0)begin
				case(counter)
				3: iaddr=(y<<6)+x;
				2: iaddr=(y<<6)+x+1;
				1: iaddr=(y<<6)+x+64;
				default: iaddr=(y<<6)+x+65;
			endcase
		end
			else if(x==0 && y ==63)begin
			case(counter)
				3: iaddr=(y<<6)+x;
				2: iaddr=(y<<6)+x+1;
				1: iaddr=(y<<6)+x-64;
				default: iaddr=(y<<6)+x-63;
			endcase
		end
			else if(x==0 && (0<y && y<63))begin
			case(counter)
				5: iaddr=(y<<6)+x-64;
				4: iaddr=(y<<6)+x-63;
				3: iaddr=(y<<6)+x;
				2: iaddr=(y<<6)+x+1;
				1: iaddr=(y<<6)+x+64;
				default: iaddr=(y<<6)+x+65;
			endcase
		end	
			else if((0<x && x<63) && y==0)begin
			case(counter)
				1: iaddr=(y<<6)+x+1;
				default: iaddr=(y<<6)+x+65;
			endcase
		end
			else if((0<x && x<63)  && y==63)begin
			case(counter)
				1: iaddr=(y<<6)+x+1;
				default: iaddr=(y<<6)+x-63;
			endcase
		end
		
			
			else if((0<x && x<63) && (0<y && y<63))begin
			case(counter)
				2: iaddr=(y<<6)+x-63;
				1: iaddr=(y<<6)+x+1;
				default: iaddr=(y<<6)+x+65;
			endcase
		end
			else
				iaddr=0;
		end
		else
			iaddr=0;
end

//buffer
always@(posedge clk)begin

	if(state == read)begin
		if(x==0 && y==0)begin
			if(counter == 3)
				buffer [4] <= idata;
			else if( counter == 2)
				buffer [5] <= idata;
			else if( counter == 1)
				buffer [7] <= idata;
			else if( counter == 0)begin
				buffer [8] <= idata;
				buffer [0] <= 0;
				buffer [1] <= 0;
				buffer [2] <= 0;
				buffer [3] <= 0;
				buffer [6] <= 0;
			end
			
		end
		
		else if(x==0 && y==63)begin
			if(counter == 3)
				buffer [4] <= idata;
			else if( counter == 2)
				buffer [5] <= idata;
			else if( counter == 1)
				buffer [1] <= idata;
			else if( counter == 0)begin
				buffer [2] <= idata;
				buffer [0] <= 0;
				buffer [3] <= 0;
				buffer [6] <= 0;
				buffer [7] <= 0;
				buffer [8] <= 0;
			end
		end
		
		else if(x==0 && (0<y && y<63))begin
			if(counter == 5)
				buffer [1] <= idata;
			else if( counter == 4)
				buffer [2] <= idata;
			else if( counter == 3)
				buffer [4] <= idata;
			else if( counter == 2)
				buffer [5] <= idata;
			else if( counter == 1)
				buffer [7] <= idata;
			else if( counter == 0)begin
				buffer [8] <= idata;
				buffer [3] <= 0;
				buffer [6] <= 0;
				buffer [9] <= 0;
			end
		end
		
		else if((0<x && x<63) && y==0)begin
			if(counter == 1)
				buffer [5] <= idata;
			else if( counter == 0)begin
				buffer [8] <= idata;
				buffer [0] <= 0;
				buffer [1] <= 0;
				buffer [2] <= 0;
				buffer [3] <= 0;
				buffer [4] <= 0;
				buffer [6] <= 0;
				buffer [7] <= 0;
			end
		end
		
		else if((0<x && x<63) && y==63)begin
			if(counter == 1)
				buffer [5] <= idata;
			else if( counter == 0)begin
				buffer [2] <= idata;
				buffer [0] <= 0;
				buffer [1] <= 0;
				buffer [3] <= 0;
				buffer [4] <= 0;
				buffer [6] <= 0;
				buffer [7] <= 0;
				buffer [8] <= 0;
			end
		end
		
		else if((0<x && x<63) && (0<y && y<63))begin
			if(counter == 2)
				buffer [2] <= idata;
			else if( counter == 1)
				buffer [5] <= idata;
			else if( counter == 0)begin
				buffer [8] <= idata;
				buffer [0] <= 0;
				buffer [1] <= 0;
				buffer [3] <= 0;
				buffer [4] <= 0;
				buffer [6] <= 0;
				buffer [7] <= 0;
			end
		end
	end
end

//buffer_out
always@(posedge clk)begin
	if(state==idle)
		buffer_out<=0;
	else if(state==work)begin
		if(counter==0)
			buffer_out<=buffer[0]*20'h0A89F+(buffer_out+20'h01310);
		else if(counter==1)
			buffer_out<=buffer[1]*20'h092D5+(buffer_out+20'h01310);
		else if(counter==2)
			buffer_out<=buffer[2]*20'h06D43+(buffer_out+20'h01310);
		else if(counter==3)
			buffer_out<=buffer[3]*20'h01004+(buffer_out+20'h01310);
		else if(counter==4)
			buffer_out<=buffer[4]*20'hF8F71+(buffer_out+20'h01310);
		else if(counter==5)
			buffer_out<=buffer[5]*20'hF6E54+(buffer_out+20'h01310);
		else if(counter==6)
			buffer_out<=buffer[6]*20'hFA6D7+(buffer_out+20'h01310);
		else if(counter==7)
			buffer_out<=buffer[7]*20'hFC834+(buffer_out+20'h01310);
		else if(counter==8)
			buffer_out<=buffer[8]*20'hFAC19+(buffer_out+20'h01310);
	end
end
//counter_out
always@(posedge clk)begin
	if(state==pooling)
		counter_out<=counter_out+1;
	else
		counter_out<=0;
end

//csel
always@(*)begin
	if( state == out_0 || state == out_0_temp )
		csel = 3'b001;
	else if( state == out_1 || state == out_1_temp )
		csel = 3'b011;
	else
		csel = 3'b000;
end

endmodule