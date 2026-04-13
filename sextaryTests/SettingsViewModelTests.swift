import XCTest
@testable import sextary

class SettingsViewModelTests: XCTestCase {
    var viewModel: SettingsViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = SettingsViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.apiKeyStatus.isEmpty)
    }
    
    func testCheckAPIKeyStatus() {
        // 测试API密钥状态检查
        viewModel.checkAPIKeyStatus()
        XCTAssertFalse(viewModel.apiKeyStatus.isEmpty)
    }
    
    func testOpenAPIKeyInput() {
        XCTAssertFalse(viewModel.showAPIKeyView)
        viewModel.openAPIKeyInput()
        XCTAssertTrue(viewModel.showAPIKeyView)
    }
}
