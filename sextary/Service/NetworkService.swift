import Foundation
import Alamofire

class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    func request<T: Decodable>(_ url: String, method: HTTPMethod, parameters: Parameters? = nil, headers: HTTPHeaders? = nil) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: method, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    func requestWithData(_ url: String, method: HTTPMethod, parameters: Parameters? = nil, headers: HTTPHeaders? = nil) async throws -> (Data, HTTPURLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: method, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                    case .success(let data):
                        if let httpResponse = response.response, let data = data {
                            continuation.resume(returning: (data, httpResponse))
                        } else {
                            let error = NSError(domain: "NetworkServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]) 
                            continuation.resume(throwing: error)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    func streamRequest(_ url: String, method: HTTPMethod, parameters: Parameters? = nil, headers: HTTPHeaders? = nil) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            // 为了实现流式请求，我们使用 URLSession 的 bytes 方法
            // 这样可以保持与原有实现的兼容性
            guard let url = URL(string: url) else {
                continuation.finish(throwing: URLError(.badURL))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            // 设置请求头
            headers?.forEach { header in
                request.addValue(header.value, forHTTPHeaderField: header.name)
            }
            
            // 设置请求体
            if let parameters = parameters {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
                    request.httpBody = jsonData
                } catch {
                    continuation.finish(throwing: error)
                    return
                }
            }
            
            // 使用 URLSession 的 bytes 方法处理流式响应
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw URLError(.badServerResponse)
                    }
                    
                    if httpResponse.statusCode != 200 {
                        let errorMessage = "API error with status code: \(httpResponse.statusCode)"
                        throw NSError(domain: "KimiAPIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    }
                    
                    // Process streaming data
                    var buffer = Data()
                    for try await byte in bytes {
                        buffer.append(byte)
                        
                        // Check if there's a complete line
                        if let index = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                            let lineData = buffer[..<index]
                            buffer = buffer[index...].dropFirst()
                            
                            if let lineString = String(data: lineData, encoding: .utf8) {
                                let trimmedLine = lineString.trimmingCharacters(in: .whitespaces)
                                if trimmedLine.isEmpty || trimmedLine == "data: [DONE]" {
                                    continue
                                }
                                
                                if trimmedLine.hasPrefix("data: ") {
                                    let jsonString = trimmedLine.dropFirst(5)
                                    continuation.yield(String(jsonString))
                                }
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
