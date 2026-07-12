import XCTest
@testable import SplitApp

final class BootstrapAuthUseCaseTests: XCTestCase {
    func testBootstrapKeepsTokenWhenRefreshSucceeds() async {
        let storage = TestSecureStorage(values: ["refresh_token": "refresh"])

        let result = await BootstrapAuthUseCase(storage: storage, refresh: {}).execute()

        XCTAssertEqual(result, .authenticated)
        XCTAssertEqual(storage.get("refresh_token"), "refresh")
    }

    func testBootstrapRemovesTokenWhenRefreshFails() async {
        let storage = TestSecureStorage(values: ["refresh_token": "refresh"])

        let result = await BootstrapAuthUseCase(storage: storage, refresh: {
            throw TestError.failed
        }).execute()

        XCTAssertEqual(result, .unauthenticated)
        XCTAssertNil(storage.get("refresh_token"))
    }
}

private enum TestError: Error {
    case failed
}

private final class TestSecureStorage: SecureStorage {
    private var values: [String: String]

    init(values: [String: String]) {
        self.values = values
    }

    func save(_ value: String, for key: String) { values[key] = value }
    func get(_ key: String) -> String? { values[key] }
    func delete(_ key: String) { values[key] = nil }
}
