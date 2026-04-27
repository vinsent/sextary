import Foundation
import Alamofire

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
        // Kimi API endpoint - using official China region endpoint
        let url = "https://api.moonshot.cn/v1/chat/completions"
        // Ensure API Key format is correct
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(trimmedKey)",
            "Content-Type": "application/json"
        ]
        
        // Create Kimi API request
        let kimiRequest = KimiChatRequest(
            model: "kimi-k2.5",
            messages: messages,
            stream: false
        )
        
        do {
            // Encode request to JSON
            let jsonData = try JSONEncoder.shared.encode(kimiRequest)
            let parameters = try JSONSerialization.jsonObject(with: jsonData, options: []) as? Parameters ?? [:]
            
            // Get Kimi API response
            let (data, response) = try await NetworkService.shared.requestWithData(url, method: .post, parameters: parameters, headers: headers)
            
            // First check if data is empty
            guard !data.isEmpty else {
                print("Error: Empty response data")
                throw URLError(.badServerResponse)
            }
            
            if response.statusCode != 200 {
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
                    let customError = NSError(domain: "KimiAPIError", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(responseString)"])
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
        } catch let error as AFError {
            // Handle Alamofire errors
            print("Network error: \(error.localizedDescription)")
            throw error
        } catch {
            // Handle other errors
            print("Other error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func stream(_ messages: [Message]) async throws -> AsyncThrowingStream<String, Error> {
        // Kimi API endpoint - using official China region endpoint
        let url = "https://api.moonshot.cn/v1/chat/completions"
        // Ensure API Key format is correct
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(trimmedKey)",
            "Content-Type": "application/json"
        ]
        
        // Create Kimi API request with stream enabled
        let kimiRequest = KimiChatRequest(
            model: "kimi-k2.5",
            messages: messages,
            stream: true
        )
        
        // Encode request to JSON
        let jsonData = try JSONEncoder.shared.encode(kimiRequest)
        let parameters = try JSONSerialization.jsonObject(with: jsonData, options: []) as? Parameters ?? [:]
        
        // Use NetworkService for streaming request
        let stream = NetworkService.shared.streamRequest(url, method: .post, parameters: parameters, headers: headers)
        
        // Process the stream and yield only the content
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await jsonString in stream {
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
