//
//  Copyright © Essential Developer. All rights reserved.
//

import Foundation

public protocol HTTPClient {
	func perform(from urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse)
}
