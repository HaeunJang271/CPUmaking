// ============================================================================
// tb_ram.v - ram 모듈 테스트벤치
// ============================================================================
// 테스트 케이스:
//   1) 주소 100에 0x1234 쓰기 후 읽기
//   2) 주소 0xFF00에 0xABCD 쓰기 후 읽기
//   3) 주소 100 덮어쓰기 0x5678 후 읽기
//   4) 미쓰기 주소 0 읽기 (0)
// ============================================================================

`timescale 1ns / 1ps

module tb_ram;

    // DUT 입력/출력
    reg         clk;
    reg         write_enable;
    reg  [15:0] address;
    reg  [15:0] data_in;
    wire [15:0] data_out;

    // 테스트 통과/실패 카운터
    integer pass_count;
    integer fail_count;

    // DUT (Device Under Test) 인스턴스
    ram uut (
        .clk          (clk),
        .write_enable (write_enable),
        .address      (address),
        .data_in      (data_in),
        .data_out     (data_out)
    );

    // -------------------------------------------------------------------------
    // 클럭 생성: 주기 10ns (100MHz)
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // 1 클럭 사이클 대기
    // -------------------------------------------------------------------------
    task clock_cycle;
        begin
            @(posedge clk);
        end
    endtask

    // -------------------------------------------------------------------------
    // RAM 쓰기 (상승 에지 1회)
    // -------------------------------------------------------------------------
    task ram_write;
        input [15:0] addr;
        input [15:0] data;
        begin
            address      = addr;
            data_in      = data;
            write_enable = 1;
            clock_cycle();
            write_enable = 0;
        end
    endtask

    // -------------------------------------------------------------------------
    // RAM 읽기: 주소 설정 후 다음 클럭에 data_out 샘플링
    // -------------------------------------------------------------------------
    task ram_read;
        input  [15:0] addr;
        output [15:0] data;
        begin
            address      = addr;
            write_enable = 0;
            clock_cycle();   // 주소 래치
            clock_cycle();   // 동기 읽기 결과 반영
            #1;
            data = data_out;
        end
    endtask

    // -------------------------------------------------------------------------
    // 검증 태스크
    // -------------------------------------------------------------------------
    task check_read;
        input [255:0] test_name;
        input [15:0]  addr;
        input [15:0]  exp_data;
        reg [15:0] read_data;
        begin
            ram_read(addr, read_data);
            if (read_data === exp_data) begin
                $display("[PASS] %s: addr=%0d (0x%04h) data=0x%04h",
                         test_name, addr, addr, read_data);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s: addr=%0d (0x%04h)", test_name, addr, addr);
                $display("       Expected: 0x%04h", exp_data);
                $display("       Actual:   0x%04h", read_data);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // 메인 테스트 시퀀스
    // -------------------------------------------------------------------------
    initial begin
        pass_count   = 0;
        fail_count   = 0;
        clk          = 0;
        write_enable = 0;
        address      = 16'd0;
        data_in      = 16'd0;

        $display("========================================");
        $display(" HAEUN-16 ram TestBench");
        $display("========================================");

        // 테스트 1: 주소 100 쓰기/읽기
        ram_write(16'd100, 16'h1234);
        check_read("write/read addr 100", 16'd100, 16'h1234);

        // 테스트 2: 상위 주소
        ram_write(16'hFF00, 16'hABCD);
        check_read("write/read addr FF00", 16'hFF00, 16'hABCD);

        // 테스트 3: 덮어쓰기
        ram_write(16'd100, 16'h5678);
        check_read("overwrite addr 100", 16'd100, 16'h5678);

        // 테스트 4: 초기화된 0번 주소
        check_read("read addr 0 (zero)", 16'd0, 16'h0000);

        // 최종 요약
        #10;
        $display("----------------------------------------");
        $display(" Result: PASS=%0d, FAIL=%0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" *** ALL TESTS PASS ***");
        else
            $display(" *** SOME TESTS FAILED ***");
        $display("========================================");

        $finish;
    end

endmodule
