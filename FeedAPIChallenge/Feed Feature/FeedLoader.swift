//
//  Copyright © Essential Developer. All rights reserved.
//

import Foundation

public protocol FeedLoader {
	func load() async throws -> [FeedImage]
}
