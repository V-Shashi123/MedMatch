module medmatch_top #(
    parameter CLK_FREQ = 100000000
)(
    input clk,
    input reset,

    input scan_valid,
    input [31:0] scanned_patient_id,
    input [31:0] registered_patient_id,

    input verify_enable,
    input [15:0] scanned_medicine_id,
    input [15:0] prescribed_medicine_id,

    input check_enable,
    input [4:0] scheduled_hour,
    input [5:0] scheduled_minute,

    input new_schedule,
    input ir_sensor_input,

    input rfid_start,
    input rfid_read_mode,
    input [5:0] rfid_reg_addr,
    input [7:0] rfid_write_data,
    input rfid_miso,

    input rtc_start,
    inout wire rtc_scl,
    inout wire rtc_sda,

    output [7:0] rfid_read_data,
    output rfid_busy,
    output rfid_done,
    output rfid_sck,
    output rfid_mosi,
    output rfid_cs_n,

    output rtc_busy,
    output rtc_done,
    output rtc_ack_error,

    output patient_verified,
    output patient_rejected,
    output medicine_valid,
    output medicine_invalid,
    output time_valid,
    output early_dose,
    output late_dose,
    output dose_already_taken,
    output medicine_not_expired,
    output medicine_expired,

    output access_granted,
    output access_rejected,
    output [2:0] rejection_reason,

    output green_led,
    output red_led,
    output buzzer,
    output servo_pwm,
    output medicine_removed,

    output lcd_rs,
    output lcd_en,
    output [3:0] lcd_data
);

wire dose_accepted;

wire [7:0] seconds_bcd;
wire [7:0] minutes_bcd;
wire [7:0] hours_bcd;
wire [7:0] day_bcd;
wire [7:0] date_bcd;
wire [7:0] month_bcd;
wire [7:0] year_bcd;

wire [7:0] current_hour;
wire [7:0] current_minute;

wire [31:0] current_date;

assign current_hour =
    (hours_bcd[7:4] * 8'd10) + hours_bcd[3:0];

assign current_minute =
    (minutes_bcd[7:4] * 8'd10) + minutes_bcd[3:0];

assign current_date =
    32'd20000000 +
    ((year_bcd[7:4] * 32'd10 + year_bcd[3:0]) * 32'd10000) +
    ((month_bcd[7:4] * 32'd10 + month_bcd[3:0]) * 32'd100) +
    (date_bcd[7:4] * 32'd10 + date_bcd[3:0]);

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
    .current_hour(current_hour[4:0]),
    .current_minute(current_minute[5:0]),
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
    .expiry_date(32'd20271231),
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

ir_sensor_controller IR1(
    .clk(clk),
    .reset(reset),
    .ir_sensor_input(ir_sensor_input),
    .access_granted(access_granted),
    .medicine_removed(medicine_removed)
);

assign dose_accepted = access_granted && medicine_removed;

servo_controller #(
    .CLK_FREQ(CLK_FREQ)
) SV1(
    .clk(clk),
    .reset(reset),
    .access_granted(access_granted),
    .servo_pwm(servo_pwm)
);

mfrc522_spi #(
    .CLK_FREQ(CLK_FREQ),
    .SPI_FREQ(1000000)
) RFID1(
    .clk(clk),
    .reset(reset),
    .start(rfid_start),
    .read_mode(rfid_read_mode),
    .reg_addr(rfid_reg_addr),
    .write_data(rfid_write_data),
    .miso(rfid_miso),
    .read_data(rfid_read_data),
    .busy(rfid_busy),
    .done(rfid_done),
    .sck(rfid_sck),
    .mosi(rfid_mosi),
    .cs_n(rfid_cs_n)
);

ds3231_i2c #(
    .CLK_FREQ(CLK_FREQ),
    .I2C_FREQ(100000)
) RTC1(
    .clk(clk),
    .reset(reset),
    .start(rtc_start),
    .scl(rtc_scl),
    .sda(rtc_sda),
    .busy(rtc_busy),
    .done(rtc_done),
    .ack_error(rtc_ack_error),
    .seconds_bcd(seconds_bcd),
    .minutes_bcd(minutes_bcd),
    .hours_bcd(hours_bcd),
    .day_bcd(day_bcd),
    .date_bcd(date_bcd),
    .month_bcd(month_bcd),
    .year_bcd(year_bcd)
);

lcd_controller #(
    .CLK_FREQ(CLK_FREQ)
) LCD1(
    .clk(clk),
    .reset(reset),
    .access_granted(access_granted),
    .access_rejected(access_rejected),
    .rejection_reason(rejection_reason),
    .lcd_rs(lcd_rs),
    .lcd_en(lcd_en),
    .lcd_data(lcd_data)
);

endmodule