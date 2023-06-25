//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

internal final class FeedImageMapper {
	private struct Root: Decodable {
		let items: [Item]

		var feed: [FeedImage] {
			return items.map { $0.item }
		}
	}

	private struct Item: Decodable {
		let id: UUID
		let description: String?
		let location: String?
		let imageURL: URL

		enum CodingKeys: String, CodingKey {
			case id = "image_id"
			case description = "image_desc"
			case location = "image_loc"
			case imageURL = "image_url"
		}

		var item: FeedImage {
			return FeedImage(id: id, description: description, location: location, url: imageURL)
		}
	}

	private static var OK_200: Int { return 200 }

	internal static func map(_ data: Data, response: HTTPURLResponse) throws -> [FeedImage] {
		guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
			throw RemoteFeedLoader.Error.invalidData
		}

		return root.feed
	}
}
