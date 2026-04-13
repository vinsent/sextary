import XCTest
@testable import sextary

class ChatViewModelTests: XCTestCase {
    var viewModel: ChatViewModel!
    
    override func setUp() {
        super.setUp()
        // 使用一个测试用的API密钥
        viewModel = ChatViewModel(apiKey: "test_api_key")
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.messages.isEmpty)
        XCTAssertEqual(viewModel.messages.first?.content, "Hello! I'm your AI assistant. How can I help you today?")
        XCTAssertFalse(viewModel.messages.first?.isUser ?? true)
    }
    
    func testSendMessage() {
        let initialMessageCount = viewModel.messages.count
        viewModel.inputText = "Test message"
        viewModel.sendMessage()
        
        // 应该添加一条用户消息
        XCTAssertEqual(viewModel.messages.count, initialMessageCount + 1)
        XCTAssertTrue(viewModel.messages.last?.isUser ?? false)
        XCTAssertEqual(viewModel.messages.last?.content, "Test message")
        // 输入框应该被清空
        XCTAssertEqual(viewModel.inputText, "")
    }
}
