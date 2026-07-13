import Combine
import IOKit.ps
import XCTest
@testable import MaraCore

@MainActor
final class BatteryMonitoringIntegrationTests: XCTestCase {
    func test_iokitMonitorPublishesCoherentInitialSnapshot() {
        var monitor: IOKitBatteryMonitor? = IOKitBatteryMonitor()
        var received: [BatterySnapshot] = []
        let cancellable = monitor?.snapshots.sink { received.append($0) }

        guard let snapshot = monitor?.snapshot else {
            return XCTFail("monitor unexpectedly missing")
        }
        XCTAssertEqual(received, [snapshot])
        if case .battery(let percentage, _) = snapshot {
            XCTAssertTrue((0...100).contains(percentage))
        }

        cancellable?.cancel()
        monitor = nil   // main-actor deinit must remove and invalidate the CFRunLoop source safely
    }

    // MARK: - parse: 하드웨어 비의존 순수 변환 (헤드리스 CI에서도 커버됨)

    func test_parse_acPower_reportsOnAC() {
        let snapshot = IOKitBatteryMonitor.parse([
            kIOPSCurrentCapacityKey: 80,
            kIOPSMaxCapacityKey: 100,
            kIOPSPowerSourceStateKey: kIOPSACPowerValue,
        ])
        XCTAssertEqual(snapshot, .battery(percentage: 80, isOnAC: true))
    }

    func test_parse_batteryPower_reportsOffAC() {
        let snapshot = IOKitBatteryMonitor.parse([
            kIOPSCurrentCapacityKey: 30,
            kIOPSMaxCapacityKey: 100,
            kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue,
        ])
        XCTAssertEqual(snapshot, .battery(percentage: 30, isOnAC: false))
    }

    func test_parse_computesRatioWhenMaxNot100() {
        let snapshot = IOKitBatteryMonitor.parse([
            kIOPSCurrentCapacityKey: 25,
            kIOPSMaxCapacityKey: 50,
            kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue,
        ])
        XCTAssertEqual(snapshot, .battery(percentage: 50, isOnAC: false))
    }

    func test_parse_clampsAbove100() {
        let snapshot = IOKitBatteryMonitor.parse([
            kIOPSCurrentCapacityKey: 120,
            kIOPSMaxCapacityKey: 100,
            kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue,
        ])
        XCTAssertEqual(snapshot, .battery(percentage: 100, isOnAC: false))
    }

    func test_parse_missingCurrentCapacity_isUnavailable() {
        let snapshot = IOKitBatteryMonitor.parse([
            kIOPSMaxCapacityKey: 100,
            kIOPSPowerSourceStateKey: kIOPSACPowerValue,
        ])
        XCTAssertEqual(snapshot, .unavailable)
    }

    func test_parse_nonPositiveMaxCapacity_isUnavailable() {
        let snapshot = IOKitBatteryMonitor.parse([
            kIOPSCurrentCapacityKey: 50,
            kIOPSMaxCapacityKey: 0,
            kIOPSPowerSourceStateKey: kIOPSACPowerValue,
        ])
        XCTAssertEqual(snapshot, .unavailable)
    }

    func test_parse_missingState_isUnavailable() {
        let snapshot = IOKitBatteryMonitor.parse([
            kIOPSCurrentCapacityKey: 50,
            kIOPSMaxCapacityKey: 100,
        ])
        XCTAssertEqual(snapshot, .unavailable)
    }
}
