module lcd_controller #(
    parameter CLK_FREQ = 100000000
)(
    input clk,
    input reset,
    input access_granted,
    input access_rejected,
    input [2:0] rejection_reason,
    output reg lcd_rs,
    output reg lcd_en,
    output reg [3:0] lcd_data
);

localparam DELAY_20MS = CLK_FREQ / 50;
localparam DELAY_2MS  = CLK_FREQ / 500;
localparam DELAY_50US = CLK_FREQ / 20000;

reg [31:0] counter;
reg [5:0] state;
reg [7:0] current_char;
reg [7:0] message [0:31];
reg [7:0] character;
reg [5:0] index;
reg [1:0] nibble;
reg [31:0] wait_time;
reg busy;

integer i;

always @(*) begin
    if (access_granted) begin
        message[0] = "A";
        message[1] = "C";
        message[2] = "C";
        message[3] = "E";
        message[4] = "S";
        message[5] = "S";
        message[6] = " ";
        message[7] = "G";
        message[8] = "R";
        message[9] = "A";
        message[10] = "N";
        message[11] = "T";
        message[12] = "E";
        message[13] = "D";
    end
    else if (access_rejected) begin
        message[0] = "A";
        message[1] = "C";
        message[2] = "C";
        message[3] = "E";
        message[4] = "S";
        message[5] = "S";
        message[6] = " ";
        message[7] = "D";
        message[8] = "E";
        message[9] = "N";
        message[10] = "I";
        message[11] = "E";
        message[12] = "D";
    end
    else begin
        message[0] = "M";
        message[1] = "E";
        message[2] = "D";
        message[3] = "M";
        message[4] = "A";
        message[5] = "T";
        message[6] = "C";
        message[7] = "H";
        message[8] = " ";
        message[9] = "R";
        message[10] = "E";
        message[11] = "A";
        message[12] = "D";
        message[13] = "Y";
    end

    for (i = 14; i < 32; i = i + 1)
        message[i] = " ";
end

always @(posedge clk) begin
    if (reset) begin
        counter <= 0;
        state <= 0;
        index <= 0;
        nibble <= 0;
        lcd_rs <= 0;
        lcd_en <= 0;
        lcd_data <= 0;
        busy <= 0;
    end
    else begin
        case (state)
            0: begin
                lcd_rs <= 0;
                lcd_data <= 4'b0011;
                lcd_en <= 1;
                if (counter >= DELAY_20MS) begin
                    counter <= 0;
                    lcd_en <= 0;
                    state <= 1;
                end
                else counter <= counter + 1;
            end

            1: begin
                lcd_data <= 4'b0011;
                lcd_en <= 1;
                if (counter >= DELAY_2MS) begin
                    counter <= 0;
                    lcd_en <= 0;
                    state <= 2;
                end
                else counter <= counter + 1;
            end

            2: begin
                lcd_data <= 4'b0011;
                lcd_en <= 1;
                if (counter >= DELAY_50US) begin
                    counter <= 0;
                    lcd_en <= 0;
                    state <= 3;
                end
                else counter <= counter + 1;
            end

            3: begin
                lcd_data <= 4'b0010;
                lcd_en <= 1;
                if (counter >= DELAY_50US) begin
                    counter <= 0;
                    lcd_en <= 0;
                    state <= 4;
                end
                else counter <= counter + 1;
            end

            4: begin
                lcd_rs <= 0;
                lcd_data <= 4'b0010;
                lcd_en <= 1;
                if (counter >= DELAY_50US) begin
                    counter <= 0;
                    lcd_en <= 0;
                    state <= 5;
                end
                else counter <= counter + 1;
            end

            5: begin
                lcd_data <= 4'b1000;
                lcd_en <= 1;
                if (counter >= DELAY_50US) begin
                    counter <= 0;
                    lcd_en <= 0;
                    state <= 6;
                end
                else counter <= counter + 1;
            end

            6: begin
                lcd_data <= 4'b0000;
                lcd_en <= 1;
                if (counter >= DELAY_50US) begin
                    counter <= 0;
                    lcd_en <= 0;
                    state <= 7;
                end
                else counter <= counter + 1;
            end

            7: begin
                lcd_data <= 4'b1100;
                lcd_en <= 1;
                if (counter >= DELAY_50US) begin
                    counter <= 0;
                    lcd_en <= 0;
                    state <= 8;
                end
                else counter <= counter + 1;
            end

            8: begin
                lcd_data <= 4'b0000;
                lcd_en <= 1;
                if (counter >= DELAY_50US) begin
                    counter <= 0;
                    lcd_en <= 0;
                    state <= 9;
                end
                else counter <= counter + 1;
            end

            9: begin
                lcd_data <= 4'b0001;
                lcd_en <= 1;
                if (counter >= DELAY_2MS) begin
                    counter <= 0;
                    lcd_en <= 0;
                    state <= 10;
                    index <= 0;
                end
                else counter <= counter + 1;
            end

            10: begin
                current_char <= message[index];
                lcd_rs <= 1;
                lcd_data <= message[index][7:4];
                lcd_en <= 1;
                state <= 11;
            end

            11: begin
                lcd_en <= 0;
                lcd_data <= current_char[3:0];
                lcd_en <= 1;
                state <= 12;
            end

            12: begin
                lcd_en <= 0;
                if (counter >= DELAY_50US) begin
                    counter <= 0;
                    if (index == 13) begin
                        state <= 13;
                    end
                    else begin
                        index <= index + 1;
                        state <= 10;
                    end
                end
                else counter <= counter + 1;
            end

            13: begin
                state <= 10;
                index <= 0;
            end

            default: state <= 0;
        endcase
    end
end

endmodule