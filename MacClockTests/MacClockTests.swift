import Testing
import Foundation
@testable import MacClock

@Test func mockURLProtocolSmokeTest() async throws {
    let config = URLSessionConfiguration.mocked()
    let session = URLSession(configuration: config)

    MockURLProtocol.requestHandler = { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (response, Data("hello".utf8))
    }
    defer { MockURLProtocol.requestHandler = nil }

    let (data, _) = try await session.data(from: URL(string: "https://test.invalid/")!)
    #expect(String(data: data, encoding: .utf8) == "hello")
}
