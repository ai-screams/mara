import Foundation
import XCTest
@testable import MaraCore

@MainActor
final class RoutingTableNetworkProviderTests: XCTestCase {
    func test_refresh_retriesUntilGatewayMACBecomesAvailable() async {
        let expected = NetworkIdentity(gatewayMAC: "00:10:db:ff:10:02")
        let reader = SequenceIdentityReader([nil, nil, expected])
        let provider = RoutingTableNetworkProvider(
            readIdentity: { reader.read() },
            retryDelays: [.zero, .zero]
        )

        await provider.refreshForTesting()

        XCTAssertEqual(provider.current, expected)
        XCTAssertEqual(reader.currentReadCount, 3)
    }

    func test_refresh_succeedsOnFirstAttempt_withoutRetry() async {
        let expected = NetworkIdentity(gatewayMAC: "aa:bb:cc:dd:ee:ff")
        let reader = SequenceIdentityReader([expected])
        let provider = RoutingTableNetworkProvider(
            readIdentity: { reader.read() },
            retryDelays: [.zero, .zero]
        )

        await provider.refreshForTesting()

        XCTAssertEqual(provider.current, expected)
        XCTAssertEqual(reader.currentReadCount, 1)   // 첫 read 성공 → sleep/재시도 경로 안 탐
    }

    func test_refresh_stopsAfterBoundedAttempts() async {
        let reader = SequenceIdentityReader([nil, nil, nil, nil])
        let provider = RoutingTableNetworkProvider(
            readIdentity: { reader.read() },
            retryDelays: [.zero, .zero]
        )

        await provider.refreshForTesting()

        XCTAssertNil(provider.current)
        XCTAssertEqual(reader.currentReadCount, 3)
    }
}

private final class SequenceIdentityReader: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [NetworkIdentity?]
    private var readCount = 0

    var currentReadCount: Int {
        lock.withLock { readCount }
    }

    init(_ values: [NetworkIdentity?]) {
        self.values = values
    }

    func read() -> NetworkIdentity? {
        lock.withLock {
            readCount += 1
            return values.isEmpty ? nil : values.removeFirst()
        }
    }
}
