module tb_ALSU;
    reg [2:0] A, B, opcode;
    reg cin, serial_in, direction, red_op_A, red_op_B, bypass_A, bypass_B, CLK, reset;
    wire [5:0] out;
    wire [15:0] lede;
    
    parameter INPUT_PRIORITY = "A";
    parameter FULL_ADDER = "ON";
    
    // Instantiate ALSU module
    ALSU #(
        .INPUT_PRIORITY(INPUT_PRIORITY),
        .FULL_ADDER(FULL_ADDER)
    ) DUT (
        .A(A),
        .B(B),
        .opcode(opcode),
        .serial_in(serial_in),
        .direction(direction),
        .red_op_A(red_op_A),
        .red_op_B(red_op_B),
        .bypass_A(bypass_A),
        .bypass_B(bypass_B),
        .CLK(CLK),
        .reset(reset),
        .out(out),
        .lede(lede)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #1 CLK = ~CLK; // Toggle clock every 1 time unit
    end

    integer i; // Declare loop variable
    reg [5:0] out_ex; // Expected output for verification

    // Stimulus process
    initial begin
        reset = 1;
        A = 3'b000;
        B = 3'b000;
        opcode = 3'b000;
        cin = 0;
        serial_in = 0;
        direction = 0;
        red_op_A = 0;
        red_op_B = 0;
        bypass_A = 0;
        bypass_B = 0;

        @(negedge CLK);
        reset = 0;

        // Random test cases
        for (i = 0; i < 10; i = i + 1) begin
            A = $random;
            B = $random;
            opcode = $urandom_range(0, 7);
            cin = $random;
            serial_in = $random;
            direction = $random;
            red_op_A = $random;
            red_op_B = $random;
            bypass_A = $random;
            bypass_B = $random;

            @(negedge CLK);
        end

        // Basic check
        if ((out != A) && (lede != 0)) begin
            $display("The ALSU Design is Wrong!");
            $stop;
        end

        // Further testing with expected values
        for (i = 0; i < 10; i = i + 1) begin
            A = $random;
            B = $random;
            opcode = $urandom_range(0, 7);
            cin = $random;
            serial_in = $random;
            direction = $random;
            red_op_A = $random;
            red_op_B = $random;
            bypass_A = $random;
            bypass_B = $random;

            // Expected output calculation
            case (opcode)
                3'b000: begin
                    if (red_op_A && red_op_B)
                        out_ex = (INPUT_PRIORITY == "A") ? &A : &B;
                    else if (red_op_A)
                        out_ex = &A;
                    else if (red_op_B)
                        out_ex = &B;
                    else
                        out_ex = A & B;
                end
                3'b001: begin
                    if (red_op_A && red_op_B)
                        out_ex = (INPUT_PRIORITY == "A") ? A : B;
                    else if (red_op_A)
                        out_ex = ^A;
                    else if (red_op_B)
                        out_ex = ^B;
                    else
                        out_ex = A ^ B;
                end
                3'b010: begin
                    if (FULL_ADDER == "ON")
                        out_ex = A + B + cin;
                    else
                        out_ex = A + B;
                end
                3'b011: begin
                    out_ex = A * B;
                end
                3'b100: begin
                    if (direction)
                        out_ex = {out[4:0], serial_in};
                    else
                        out_ex = {serial_in, out[5:1]};
                end
                3'b101: begin
                    if (direction)
                        out_ex = {out[4:0], out[5]};
                    else
                        out_ex = {out[0], out[5:1]};
                end
                default: out_ex = 0;
            endcase

            @(negedge CLK);
            if (out !== out_ex) begin
                $display("Error: Expected %b, Got %b", out_ex, out);
                $stop;
            end
        end

        $display("All test cases passed successfully!");
        $finish;
    end

    // Monitoring signal values
    initial begin
        $monitor(
            "A = %b, B = %b, opcode = %b, cin = %b, serial_in = %b, direction = %b, red_op_A = %b, red_op_B = %b, bypass_A = %b, bypass_B = %b, CLK = %b, reset = %b, out = %b, lede = %b",
            A, B, opcode, cin, serial_in, direction, red_op_A, red_op_B, bypass_A, bypass_B, CLK, reset, out, lede
        );
    end
endmodule
