import Foundation

enum APIClientError: Error {
    case invalidResponse
}

struct APIClient {
    var dataEndpoint: URL

    func fetchPayload() async throws -> MoiMoiDataPayload {
        let (data, response) = try await URLSession.shared.data(from: dataEndpoint)
        guard
            let httpResponse = response as? HTTPURLResponse,
            200..<300 ~= httpResponse.statusCode
        else {
            throw APIClientError.invalidResponse
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MoiMoiDataPayload.self, from: data)
    }
}
