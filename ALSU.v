module ALSU(
    input  [2:0] A, B, opcode,
    input  cin, serial_in, direction, red_op_A, red_op_B, bypass_A, bypass_B, CLK, reset,
    output reg [5:0] out,
    output reg [15:0] lede 
);

// Register declarations
reg cin_reg, serial_in_reg, direction_reg, red_op_A_reg, red_op_B_reg, bypass_A_reg, bypass_B_reg;
reg [2:0] A_reg, B_reg, opcode_reg; 

// Parameters
parameter INPUT_PRIORITY = "A";
parameter FULL_ADDER = "ON";

// Signals for invalid conditions
wire invalid_opcode, invalid_red, invalid;
assign invalid_opcode = opcode[1] & opcode[2];
assign invalid_red = (red_op_A & red_op_B) & (opcode[1] | opcode[2]);
assign invalid = (invalid_red & invalid_opcode);

// Register input values on clock edge
always @(posedge CLK or posedge reset) begin
    if(reset) begin
        cin_reg <= 0;
        serial_in_reg <= 0;
        direction_reg <= 0;
        red_op_A_reg <= 0;
        red_op_B_reg <= 0;
        bypass_A_reg <= 0;
        bypass_B_reg <= 0;
        A_reg <= 0;
        B_reg <= 0;
        opcode_reg <= 0;
    end else begin
        cin_reg <= cin;
        serial_in_reg <= serial_in;
        direction_reg <= direction;
        red_op_A_reg <= red_op_A;
        red_op_B_reg <= red_op_B;
        bypass_A_reg <= bypass_A;
        bypass_B_reg <= bypass_B;
        A_reg <= A;
        B_reg <= B;
        opcode_reg <= opcode;
    end
end

// LED logic for invalid operations
always @(posedge CLK or posedge reset) begin
    if(reset) begin
        lede <= 0;
    end else begin 
        if(invalid)
            lede <= ~lede;
        else 
            lede <= 0;
    end
end

// ALSU main logic
always @(posedge CLK or posedge reset) begin
    if(reset) begin
        out <= 0;
    end else if (bypass_A_reg && bypass_B_reg) begin
        out <= (INPUT_PRIORITY == "A") ? A_reg : B_reg;
    end else if (bypass_A_reg) begin
        out <= A_reg;
    end else if (bypass_B_reg) begin
        out <= B_reg;  
    end else if (invalid) begin
        out <= 0;
    end else begin
        case(opcode_reg)
            3'b000 : begin
                if(red_op_A_reg && red_op_B_reg)
                    out <= (INPUT_PRIORITY == "A") ? &A_reg : &B_reg;
                else if(red_op_A_reg)
                    out <= &A_reg;
                else if(red_op_B_reg)
                    out <= &B_reg; 
                else 
                    out <= A_reg & B_reg;
            end
            3'b001 : begin
                if(red_op_A_reg && red_op_B_reg)
                    out <= (INPUT_PRIORITY == "A") ? A_reg : B_reg;
                else if(red_op_A_reg)
                    out <= ^A_reg;
                else if(red_op_B_reg)
                    out <= ^B_reg;
                else 
                    out <= A_reg ^ B_reg; 
            end
            3'b010 : begin
                if(FULL_ADDER == "ON")
                    out <= A_reg + B_reg + cin_reg;
                else 
                    out <= A_reg + B_reg;
            end
            3'b011 : begin 
                out <= A_reg * B_reg;
            end 
            3'b100 : begin
                if(direction_reg)
                    out <= {out[4:0], serial_in_reg};
                else
                    out <= {serial_in_reg, out[5:1]};
            end
            3'b101 : begin
                if(direction_reg)
                    out <= {out[4:0], out[5]};
                else 
                    out <= {out[0], out[5:1]};
            end
            default: out <= 0; // Default case to handle unexpected opcodes
        endcase
    end
end

endmodule
