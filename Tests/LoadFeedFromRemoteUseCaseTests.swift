//
//  Copyright © Essential Developer. All rights reserved.
//

import XCTest
import FeedAPIChallenge

class LoadFeedFromRemoteUseCaseTests: XCTestCase {
	//  ***********************
	//
	//  [DO NOT DELETE THIS COMMENT]
	//
	//  Follow the TDD process:
	//
	//  1. Uncomment and run one test at a time (run tests with CMD+U).
	//  2. Do the minimum to make the test pass and commit.
	//  3. Refactor if needed and commit again.
	//
	//  Repeat this process until all tests are passing.
	//
	//  ***********************

	func test_init_doesNotRequestDataFromURL() {
		let (_, client) = makeSUT()

		XCTAssertTrue(client.requests.isEmpty)
	}

	func test_loadTwice_requestsDataFromURLTwice() async {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(urlRequest: URLRequest(url: url))

		_ = try? await sut.load()
		_ = try? await sut.load()

		XCTAssertEqual(client.requestedURLs, [url, url])
	}

	func test_load_deliversConnectivityErrorOnClientError() async throws {
		let (sut, _) = makeSUT(error: .connectivity)
		do {
			let result = try await sut.load()
			XCTFail("Expected result \(RemoteFeedLoader.Error.connectivity) got \(result) instead")
		} catch let error as RemoteFeedLoader.Error {
			XCTAssertEqual(error, .connectivity)
		}
	}

	func test_load_deliversInvalidDataErrorOnNon200HTTPResponse() {
		let samples = [199, 201, 300, 400, 500]

		samples.enumerated().forEach { index, code in
			let json = makeItemsJSON([])
			let httpURLResponse = HTTPURLResponse(url: anyURL(), statusCode: code, httpVersion: nil, headerFields: nil)!

			let (sut, _) = makeSUT(result: (json, httpURLResponse))

			Task {
				do {
					let result = try await sut.load()
					XCTFail("Expected result \(RemoteFeedLoader.Error.invalidData) got \(result) instead")
				} catch let error as RemoteFeedLoader.Error {
					XCTAssertEqual(error, .invalidData)
				}
			}
		}
	}

	func test_load_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() async throws {
		let invalidJSON = Data("invalid json".utf8)
		let httpURLResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!

		let (sut, _) = makeSUT(result: (invalidJSON, httpURLResponse))

		do {
			let result = try await sut.load()
			XCTFail("Expected result \(RemoteFeedLoader.Error.invalidData) got \(result) instead")
		} catch let error as RemoteFeedLoader.Error {
			XCTAssertEqual(error, .invalidData)
		}
	}

	func test_load_deliversInvalidDataErrorOn200HTTPResponseWithPartiallyValidJSONItems() async throws {
		let validItem = makeItem(
			id: UUID(),
			imageURL: URL(string: "http://another-url.com")!
		).json
		let invalidItem = ["invalid": "item"]
		let items = [validItem, invalidItem]

		let json = makeItemsJSON(items)
		let httpURLResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!

		let (sut, _) = makeSUT(result: (json, httpURLResponse))

		do {
			let result = try await sut.load()
			XCTFail("Expected result \(RemoteFeedLoader.Error.invalidData) got \(result) instead")
		} catch let error as RemoteFeedLoader.Error {
			XCTAssertEqual(error, .invalidData)
		}
	}

	func test_load_deliversSuccessWithNoItemsOn200HTTPResponseWithEmptyJSONList() async throws {
		let emptyListJSON = makeItemsJSON([])
		let httpURLResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!

		let (sut, _) = makeSUT(result: (emptyListJSON, httpURLResponse))

		do {
			let result = try await sut.load()
			XCTAssertEqual(result, [])
		} catch let error as RemoteFeedLoader.Error {
			XCTFail("Expected result \([]) got \(error) instead")
		}
	}

	func test_load_deliversSuccessWithItemsOn200HTTPResponseWithJSONItems() async throws {
		let item1 = makeItem(
			id: UUID(),
			imageURL: URL(string: "http://a-url.com")!)

		let item2 = makeItem(
			id: UUID(),
			description: "a description",
			location: "a location",
			imageURL: URL(string: "http://another-url.com")!)

		let json = makeItemsJSON([item1.json, item2.json])
		let httpURLResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!

		let (sut, _) = makeSUT(result: (json, httpURLResponse))

		let items = [item1.model, item2.model]

		do {
			let result = try await sut.load()
			XCTAssertEqual(result, items)
		} catch let error as RemoteFeedLoader.Error {
			XCTFail("Expected result \(items) got \(error) instead")
		}
	}

	func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() async throws {
		let url = URL(string: "http://any-url.com")!
		let client = HTTPClientSpy(result: nil, error: nil)
		var sut: RemoteFeedLoader? = RemoteFeedLoader(urlRequest: URLRequest(url: url), client: client)

		var capturedResults = try await sut?.load()
		sut = nil
		XCTAssertEqual(capturedResults, [])
	}

	// MARK: - Helpers

	private func makeSUT(urlRequest: URLRequest = URLRequest(url: URL(string: "https://a-url.com")!), result: (Data, HTTPURLResponse)? = nil, error: RemoteFeedLoader.Error? = nil, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
		let client = HTTPClientSpy(result: result, error: error)
		let sut = RemoteFeedLoader(urlRequest: urlRequest, client: client)
		trackForMemoryLeaks(sut, file: file, line: line)
		trackForMemoryLeaks(client, file: file, line: line)
		return (sut, client)
	}

	private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedImage, json: [String: Any]) {
		let item = FeedImage(id: id, description: description, location: location, url: imageURL)

		let json = [
			"image_id": id.uuidString,
			"image_desc": description,
			"image_loc": location,
			"image_url": imageURL.absoluteString
		].compactMapValues { $0 }

		return (item, json)
	}

	private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
		let json = ["items": items]
		return try! JSONSerialization.data(withJSONObject: json)
	}

	private func anyValidResponse() -> (Data, HTTPURLResponse) {
		(Data(), HTTPURLResponse())
	}

	private func anyURL() -> URL {
		return URL(string: "https://a-url.com")!
	}
}
