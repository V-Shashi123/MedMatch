`timescale 1ns / 1ps

module medmatch_core_tb;

reg clk;
reg reset;

reg scan_valid;
reg [31:0] scanned_patient_id;
reg [31:0] registered_patient_id;
wire patient_verified;
wire patient_rejected;

reg verify_enable;
reg [15:0] scanned_medicine_id;
reg [15:0] prescribed_medicine_id;
wire medicine_valid;
wire medicine_invalid;

reg check_enable;
reg [4:0] current_hour;
reg [5:0] current_minute;
reg [4:0] scheduled_hour;
reg [5:0] scheduled_minute;
wire time_valid;
wire early_dose;
wire late_dose;

reg new_schedule;
reg dose_accepted;
wire dose_already_taken;

reg [31:0] current_date;
reg [31:0] expiry_date;
wire medicine_not_expired;
wire medicine_expired;

wire access_granted;
wire access_rejected;
wire [2:0] rejection_reason;

wire green_led;
wire red_led;
wire buzzer;

integer errors;

patient_verification P1(
    .clk(clk),
    .reset(reset),
    .scan_valid(scan_valid),
    .scanned_patient_id(scanned_patient_id),
    .registered_patient_id(registered_patient_id),
    .patient_verified(patient_verified),
    .patient_rejected(patient_rejected)
);

medicine_verification M1(
    .clk(clk),
    .reset(reset),
    .verify_enable(verify_enable),
    .scanned_medicine_id(scanned_medicine_id),
    .prescribed_medicine_id(prescribed_medicine_id),
    .medicine_valid(medicine_valid),
    .medicine_invalid(medicine_invalid)
);

schedule_controller S1(
    .clk(clk),
    .reset(reset),
    .check_enable(check_enable),
    .current_hour(current_hour),
    .current_minute(current_minute),
    .scheduled_hour(scheduled_hour),
    .scheduled_minute(scheduled_minute),
    .time_valid(time_valid),
    .early_dose(early_dose),
    .late_dose(late_dose)
);

dose_tracker D1(
    .clk(clk),
    .reset(reset),
    .new_schedule(new_schedule),
    .dose_accepted(dose_accepted),
    .dose_already_taken(dose_already_taken)
);

expiry_checker E1(
    .clk(clk),
    .reset(reset),
    .check_enable(check_enable),
    .current_date(current_date),
    .expiry_date(expiry_date),
    .medicine_not_expired(medicine_not_expired),
    .medicine_expired(medicine_expired)
);

medmatch_controller C1(
    .patient_verified(patient_verified),
    .medicine_valid(medicine_valid),
    .time_valid(time_valid),
    .dose_already_taken(dose_already_taken),
    .medicine_not_expired(medicine_not_expired),
    .access_granted(access_granted),
    .access_rejected(access_rejected),
    .rejection_reason(rejection_reason)
);

alert_controller A1(
    .access_granted(access_granted),
    .access_rejected(access_rejected),
    .green_led(green_led),
    .red_led(red_led),
    .buzzer(buzzer)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;
    errors = 0;

    scan_valid = 0;
    scanned_patient_id = 0;
    registered_patient_id = 32'd12345;

    verify_enable = 0;
    scanned_medicine_id = 0;
    prescribed_medicine_id = 16'd5678;

    check_enable = 0;
    current_hour = 8;
    current_minute = 30;
    scheduled_hour = 8;
    scheduled_minute = 30;

    new_schedule = 0;
    dose_accepted = 0;

    current_date = 32'd20261116;
    expiry_date = 32'd20271231;

    #20;
    reset = 0;

    scanned_patient_id = 32'd12345;
    scan_valid = 1;
    #10;
    scan_valid = 0;

    scanned_medicine_id = 16'd5678;
    verify_enable = 1;
    #10;
    verify_enable = 0;

    check_enable = 1;
    #10;
    check_enable = 0;
    #2;

    if (patient_verified && medicine_valid && time_valid &&
        medicine_not_expired && access_granted &&
        green_led && !red_led) begin
        $display("TEST 1 PASSED: Valid medicine access granted");
    end
    else begin
        $display("TEST 1 FAILED: Valid medicine access");
        errors = errors + 1;
    end

    dose_accepted = 1;
    #10;
    dose_accepted = 0;
    #2;

    if (dose_already_taken && access_rejected &&
        !access_granted && rejection_reason == 3'b100) begin
        $display("TEST 2 PASSED: Duplicate dose prevented");
    end
    else begin
        $display("TEST 2 FAILED: Duplicate dose check");
        errors = errors + 1;
    end

    new_schedule = 1;
    #10;
    new_schedule = 0;

    scanned_patient_id = 32'd99999;
    scan_valid = 1;
    #10;
    scan_valid = 0;
    #2;

    if (patient_rejected && access_rejected &&
        rejection_reason == 3'b001) begin
        $display("TEST 3 PASSED: Incorrect patient rejected");
    end
    else begin
        $display("TEST 3 FAILED: Patient verification");
        errors = errors + 1;
    end

    new_schedule = 1;
    #10;
    new_schedule = 0;

    scanned_patient_id = 32'd12345;
    scan_valid = 1;
    #10;
    scan_valid = 0;

    scanned_medicine_id = 16'd9999;
    verify_enable = 1;
    #10;
    verify_enable = 0;
    #2;

    if (medicine_invalid && access_rejected &&
        rejection_reason == 3'b010) begin
        $display("TEST 4 PASSED: Incorrect medicine rejected");
    end
    else begin
        $display("TEST 4 FAILED: Medicine verification");
        errors = errors + 1;
    end

    new_schedule = 1;
    #10;
    new_schedule = 0;

    scanned_medicine_id = 16'd5678;
    verify_enable = 1;
    #10;
    verify_enable = 0;

    current_hour = 8;
    current_minute = 0;
    check_enable = 1;
    #10;
    check_enable = 0;
    #2;

    if (early_dose && access_rejected &&
        rejection_reason == 3'b011) begin
        $display("TEST 5 PASSED: Early dose rejected");
    end
    else begin
        $display("TEST 5 FAILED: Early dose checking");
        errors = errors + 1;
    end

    new_schedule = 1;
    #10;
    new_schedule = 0;

    current_hour = 9;
    current_minute = 0;
    check_enable = 1;
    #10;
    check_enable = 0;
    #2;

    if (late_dose && access_rejected &&
        rejection_reason == 3'b011) begin
        $display("TEST 6 PASSED: Late dose rejected");
    end
    else begin
        $display("TEST 6 FAILED: Late dose checking");
        errors = errors + 1;
    end

    new_schedule = 1;
    #10;
    new_schedule = 0;

    current_hour = 8;
    current_minute = 30;
    current_date = 32'd20280101;
    check_enable = 1;
    #10;
    check_enable = 0;
    #2;

    if (medicine_expired && access_rejected &&
        rejection_reason == 3'b101) begin
        $display("TEST 7 PASSED: Expired medicine rejected");
    end
    else begin
        $display("TEST 7 FAILED: Expiry checking");
        errors = errors + 1;
    end

    if (errors == 0)
        $display("ALL 7 MEDMATCH TESTS PASSED");
    else
        $display("MEDMATCH TESTING COMPLETED WITH %0d ERRORS", errors);

    $finish;
end

endmodule