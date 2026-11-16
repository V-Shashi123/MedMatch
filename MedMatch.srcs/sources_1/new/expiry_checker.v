module expiry_checker(
    input clk,
    input reset,
    input check_enable,
    input [31:0] current_date,
    input [31:0] expiry_date,
    output reg medicine_not_expired,
    output reg medicine_expired
);

always @(posedge clk) begin
    if (reset) begin
        medicine_not_expired <= 1'b0;
        medicine_expired <= 1'b0;
    end
    else if (check_enable) begin
        if (current_date <= expiry_date) begin
            medicine_not_expired <= 1'b1;
            medicine_expired <= 1'b0;
        end
        else begin
            medicine_not_expired <= 1'b0;
            medicine_expired <= 1'b1;
        end
    end
end

endmodule