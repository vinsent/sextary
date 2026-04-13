import XCTest
@testable import sextary

class APIKeyViewModelTests: XCTestCase {
    var viewModel: APIKeyViewModel!
    var saveCalled: Bool = false
    
    override func setUp() {
        super.setUp()
        saveCalled = false
        viewModel = APIKeyViewModel {
            self.saveCalled = true
        }
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(viewModel)
    }
    
    func testLoadSavedAPIKey() {
        // 测试加载已保存的API密钥
        viewModel.loadSavedAPIKey()
        // 由于测试环境中可能没有保存的API密钥，这里主要测试方法调用不崩溃
    }
    
    func testSaveAPIKey() async {
        viewModel.apiKey = "test_api_key"
        viewModel.saveAPIKey()
        
        // 等待保存操作完成
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // 验证保存回调被调用
        XCTAssertTrue(saveCalled)
    }
}
