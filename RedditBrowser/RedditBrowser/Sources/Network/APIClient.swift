//
//  APIClient.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

import Foundation
import Combine

// MARK: - NetworkRequestError
enum NetworkRequestError: LocalizedError, Equatable {
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case error4xx(_ code: Int)
    case serverError
    case error5xx(_ code: Int)
    case decodingError( _ description: String)
    case urlSessionFailed(_ error: URLError)
    case timeOut
    case unknownError
}

// MARK: - NetworkDispatcher
protocol NetworkDispatcher {
    var urlSession: URLSession! { get }

    func dispatch<ReturnType: Codable>(request: URLRequest) -> AnyPublisher<ReturnType, NetworkRequestError>
}

struct NetworkDispatcherImpl: NetworkDispatcher {
    let urlSession: URLSession!

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func dispatch<ReturnType: Codable>(request: URLRequest) -> AnyPublisher<ReturnType, NetworkRequestError> {
        debugPrint("[\(request.httpMethod?.uppercased() ?? "")] '\(request.url!)'")
        return urlSession
            .dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .default))
            .tryMap { data, response in
                guard let response = response as? HTTPURLResponse else { throw httpError(0) }

                debugPrint("[\(response.statusCode)] '\(request.url!)'")
                if !(200...299).contains(response.statusCode) {
                    throw httpError(response.statusCode)
                }
                return data
            }
            .receive(on: DispatchQueue.main)
            .decode(type: ReturnType.self, decoder: JSONDecoder())
            .mapError { error in
                debugPrint("ERROR: \(error)")
                return handleError(error)
            }
            .eraseToAnyPublisher()
    }

    private func httpError(_ statusCode: Int) -> NetworkRequestError {
        switch statusCode {
        case 400: return .badRequest
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 402, 405...499: return .error4xx(statusCode)
        case 500: return .serverError
        case 501...599: return .error5xx(statusCode)
        default: return .unknownError
        }
    }

    private func handleError(_ error: Error) -> NetworkRequestError {
        switch error {
        case is Swift.DecodingError: return .decodingError(error.localizedDescription)
        case let urlError as URLError: return .urlSessionFailed(urlError)
        case let error as NetworkRequestError: return error
        default: return .unknownError
        }
    }
}

// MARK: - APIClient
protocol APIClient {
    var networkDispatcher: NetworkDispatcher { get }
    func dispatch<R:Request>(_ request: R) -> AnyPublisher<R.ReturnType, NetworkRequestError>
}

class APIClientImpl: APIClient {
    var networkDispatcher: NetworkDispatcher = NetworkDispatcherImpl()

    func dispatch<R>(_ request: R) -> AnyPublisher<R.ReturnType, NetworkRequestError> where R : Request {
        guard let urlRequest = request.asURLRequest(baseURL: APIConstants.baseURL) else {
            return Fail(outputType: R.ReturnType.self, failure: NetworkRequestError.badRequest)
                .eraseToAnyPublisher()
        }

        let requestPublisher: AnyPublisher<R.ReturnType, NetworkRequestError> = networkDispatcher.dispatch(request: urlRequest)
        return requestPublisher.eraseToAnyPublisher()
    }
}
