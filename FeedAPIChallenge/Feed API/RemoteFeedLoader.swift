//
//  Copyright © Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let urlRequest: URLRequest
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(urlRequest: URLRequest, client: HTTPClient) {
		self.urlRequest = urlRequest
		self.client = client
	}

	public func load() async throws -> [FeedImage] {
		let (data, response) = try await self.client.perform(from: self.urlRequest)
		return try FeedImageMapper.map(data, response: response)
	}
}
