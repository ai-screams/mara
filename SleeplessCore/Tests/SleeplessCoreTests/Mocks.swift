import Foundation
@testable import SleeplessCore

final class MockPowerAssertionProvider: PowerAssertionProviding {
    private(set) var live: [PowerAssertionToken: PowerAssertionType] = [:]
    private var nextID: UInt32 = 1
    var failNextCreate = false

    func create(type: PowerAssertionType, name: String) -> PowerAssertionToken? {
        if failNextCreate { failNextCreate = false; return nil }
        let token = PowerAssertionToken(id: nextID); nextID += 1
        live[token] = type
        return token
    }
    func release(_ token: PowerAssertionToken) { live[token] = nil }
}
