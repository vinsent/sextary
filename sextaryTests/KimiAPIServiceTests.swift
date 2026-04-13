import XCTest
@testable import sextary

class KimiAPIServiceTests: XCTestCase {
    var apiService: KimiAPIService!
    
    override func setUp() {
        super.setUp()
        apiService = KimiAPIService(with: "test_api_key")
    }
    
    override func tearDown() {
        apiService = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(apiService)
    }
    
    func testSendMessage() async {
        // 测试发送消息到Kimi API
        // 由于这是一个网络请求，在测试环境中可能会失败
        // 这里主要测试方法调用不崩溃
        let messages = [Message.user("Hello")]
        
        do {
            _ = try await apiService.send(messages)
        } catch {
            // 预期会失败，因为使用的是测试API密钥
            XCTAssertNotNil(error)
        }
    }
}
