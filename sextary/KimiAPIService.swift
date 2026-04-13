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
    let stream: Bool = false
    let n: Int = 1
}

struct KimiChatResponse: Decodable {
    let id: String
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
            messages: messages
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
            let kimiResponse = try! JSONDecoder.shared.decode(KimiChatResponse.self, from: data)
            print("Received response from Kimi API: \(kimiResponse.id)")
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
