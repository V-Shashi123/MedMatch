module medmatch_controller(
    input patient_verified,
    input medicine_valid,
    input time_valid,
    input dose_already_taken,
    input medicine_not_expired,
    output reg access_granted,
    output reg access_rejected,
    output reg [2:0] rejection_reason
);

always @(*) begin
    access_granted = 1'b0;
    access_rejected = 1'b0;
    rejection_reason = 3'b000;

    if (!patient_verified) begin
        access_rejected = 1'b1;
        rejection_reason = 3'b001;
    end
    else if (!medicine_valid) begin
        access_rejected = 1'b1;
        rejection_reason = 3'b010;
    end
    else if (!time_valid) begin
        access_rejected = 1'b1;
        rejection_reason = 3'b011;
    end
    else if (dose_already_taken) begin
        access_rejected = 1'b1;
        rejection_reason = 3'b100;
    end
    else if (!medicine_not_expired) begin
        access_rejected = 1'b1;
        rejection_reason = 3'b101;
    end
    else begin
        access_granted = 1'b1;
        access_rejected = 1'b0;
        rejection_reason = 3'b000;
    end
end

endmodule