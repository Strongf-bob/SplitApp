import XCTest
@testable import SplitApp

final class CurrentUserEndpointTests: XCTestCase {
    func testUsesAuthenticatedCurrentUserEndpoint() {
        XCTAssertEqual(CurrentUserEndpoint().path, "/api/users/me")
    }

    func testPaymentPhoneUpdateUsesCurrentUserPatchEndpoint() throws {
        let endpoint = UpdateCurrentUserEndpoint()
        let body = UpdateCurrentUserRequest(paymentPhone: "+7 926 624-33-77")
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: String]

        XCTAssertEqual(endpoint.path, "/api/users/me")
        XCTAssertEqual(endpoint.method, .PATCH)
        XCTAssertEqual(json?["payment_phone"], "+7 926 624-33-77")
        XCTAssertEqual(json?["payment_phone_visibility"], "friends")
    }

    func testUserDTOReadsPaymentPhone() throws {
        let data = Data(
            #"{"id":"00000000-0000-0000-0000-000000000001","name":"Алексей","phone_number":"+79990000000","payment_phone":"+79266243377"}"#.utf8
        )

        let user = try JSONDecoder().decode(UserDTO.self, from: data)

        XCTAssertEqual(user.paymentPhone, "+79266243377")
    }
}
