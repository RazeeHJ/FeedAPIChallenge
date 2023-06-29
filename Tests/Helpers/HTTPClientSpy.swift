//
//  Copyright © Essential Developer. All rights reserved.
//

import XCTest
import Foundation
import FeedAPIChallenge

class HTTPClientSpy: HTTPClient {
	private(set) var requests = [URLRequest]()
	private let result: (Data, HTTPURLResponse)?
	private let error: RemoteFeedLoader.Error?

	var requestedURLs: [URL] {
		return requests.map { $0.url! }
	}

	init(result: (Data, HTTPURLResponse)?, error: RemoteFeedLoader.Error?) {
		self.result = result
		self.error = error
	}

	func perform(from urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
		self.requests.append(urlRequest)
		guard let result = result else {
			throw error ?? .connectivity
		}

		return result
	}

	func complete(with error: Error, at index: Int = 0, file: StaticString = #filePath, line: UInt = #line) async throws {
		guard requests.count > index else {
			return XCTFail("Can't complete request never made", file: file, line: line)
		}

		throw error
	}

	func complete(withStatusCode code: Int, data: Data, at index: Int = 0, file: StaticString = #filePath, line: UInt = #line) -> (Data, HTTPURLResponse)? {
		guard requestedURLs.count > index else {
			XCTFail("Can't complete request never made", file: file, line: line)
			return nil
		}

		let response = HTTPURLResponse(
			url: requestedURLs[index],
			statusCode: code,
			httpVersion: nil,
			headerFields: nil
		)!

		return (data, response)
	}
}
