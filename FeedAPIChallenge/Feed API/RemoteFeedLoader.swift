//
//  Copyright © Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load() async throws -> [FeedImage] {
		let urlRequest = URLRequest(url: url)

		let (data, response) = try await self.client.perform(from: urlRequest)
		return try FeedImageMapper.map(data, response: response)
	}
}
