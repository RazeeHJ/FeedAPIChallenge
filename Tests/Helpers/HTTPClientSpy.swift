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
}
