import Foundation

struct Message: Encodable {
    enum Role: String, Encodable {
        case system
        case user
        case assistant
    }
    var role: Role
    var content: String
    
    static func system(_ content: String) -> Message {
        Message(role: .system, content: content)
    }
    static func user(_ content: String) -> Message {
        Message(role: .user, content: content)
    }
    static func assistant(_ content: String) -> Message {
        Message(role: .assistant, content: content)
    }
}

struct KimiChatRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double = 1.0
    let max_tokens: Int = 2048
    let top_p: Double = 0.95
    let frequency_penalty: Double = 0
    let presence_penalty: Double = 0
    let stream: Bool
    let n: Int = 1
    
    init(model: String, messages: [Message], stream: Bool = false) {
        self.model = model
        self.messages = messages
        self.stream = stream
    }
}

struct KimiChatResponse: Decodable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let system_fingerprint: String?
    let choices: [KimiChoice]?
    let usage: KimiUsage?
}

struct KimiChoice: Decodable {
    let index: Int
    let message: KimiAssistantMessage
    let finish_reason: String?
}

struct KimiAssistantMessage: Decodable {
    let role: String
    let content: String
}

struct KimiUsage: Decodable {
    let prompt_tokens: Int?
    let completion_tokens: Int?
    let total_tokens: Int?
}

// Streaming response structs
struct KimiStreamResponse: Decodable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let system_fingerprint: String?
    let choices: [KimiStreamChoice]?
    let usage: KimiUsage?
}

struct KimiStreamChoice: Decodable {
    let index: Int
    let delta: KimiDelta
    let finish_reason: String?
}

struct KimiDelta: Decodable {
    let role: String?
    let content: String?
}

struct KimiErrorResponse: Decodable {
    let error: KimiError
}

struct KimiError: Decodable, LocalizedError {
    let message: String
    let type: String
    let code: String?
    
    var errorDescription: String? {
        return message
    }
}

class KimiAPIService {
    private let apiKey: String
    
    init(with apiKey: String) {
        self.apiKey = apiKey
    }
    
    func send(_ messages: [Message]) async throws -> KimiChatResponse {
        // Kimi API endpoint - 使用官方中国区域端点
        var request = URLRequest(url: URL(string: "https://api.moonshot.cn/v1/chat/completions")!)
        request.httpMethod = "POST"
        // 确保API Key格式正确
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        request.addValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 创建Kimi API请求
        let kimiRequest = KimiChatRequest(
            model: "kimi-k2.5",
            messages: messages,
            stream: false
        )
        
        let jsonData = try JSONEncoder.shared.encode(kimiRequest)
        request.httpBody = jsonData
        
        do {
            // Get Kimi API response
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 首先检查data是否为空
            guard !data.isEmpty else {
                print("Error: Empty response data")
                throw URLError(.badServerResponse)
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if httpResponse.statusCode != 200 {
                let responseString = String(data: data, encoding: .utf8) ?? "No response data"
                print("Error response: \(responseString)")
                
                // Try to parse Kimi API error response
                do {
                    let errorResponse = try JSONDecoder.shared.decode(KimiErrorResponse.self, from: data)
                    print("Kimi API error: \(errorResponse.error.message)")
                    throw errorResponse.error
                } catch {
                    // If parsing fails, create a custom error with the response string
                    print("Error parsing error response: \(error.localizedDescription)")
                    let customError = NSError(domain: "KimiAPIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(responseString)"])
                    throw customError
                }
            }
            
            // Parse successful response
            let kimiResponse = try JSONDecoder.shared.decode(KimiChatResponse.self, from: data)
            print("Received response from Kimi API: \(kimiResponse.id ?? "unknown")")
            return kimiResponse
        } catch let error as KimiError {
            // Handle Kimi API errors first
            print("Kimi API error: \(error.message) (\(error.code ?? "unknown"))")
            throw error
        } catch let error as URLError {
            // Handle network errors
            print("Network error: \(error.localizedDescription)")
            throw error
        } catch {
            // Handle other errors
            print("Other error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func stream(_ messages: [Message]) async throws -> AsyncThrowingStream<String, Error> {
        // Kimi API endpoint - 使用官方中国区域端点
        var request = URLRequest(url: URL(string: "https://api.moonshot.cn/v1/chat/completions")!)
        request.httpMethod = "POST"
        // 确保API Key格式正确
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        request.addValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 创建Kimi API请求，启用stream
        let kimiRequest = KimiChatRequest(
            model: "kimi-k2.5",
            messages: messages,
            stream: true
        )
        
        let jsonData = try JSONEncoder.shared.encode(kimiRequest)
        request.httpBody = jsonData
        
        return AsyncThrowingStream { continuation in
            // 使用URLSession的bytes方法处理流式响应
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
                    
                    // 处理流式数据
                    var buffer = Data()
                    for try await byte in bytes {
                        buffer.append(byte)
                        
                        // 检查是否有完整的行
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
                                    if let jsonData = jsonString.data(using: .utf8) {
                                        do {
                                            let streamResponse = try JSONDecoder.shared.decode(KimiStreamResponse.self, from: jsonData)
                                            if let deltaContent = streamResponse.choices?.first?.delta.content, !deltaContent.isEmpty {
                                                continuation.yield(deltaContent)
                                            }
                                            
                                            if streamResponse.choices?.first?.finish_reason != nil {
                                                continuation.finish()
                                                return
                                            }
                                        } catch {
                                            print("Error parsing stream response: \(error.localizedDescription)")
                                        }
                                    }
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

extension JSONDecoder {
    static let shared: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

extension JSONEncoder {
    static let shared: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}
