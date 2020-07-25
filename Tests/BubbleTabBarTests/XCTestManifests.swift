import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BubbleTabBarTests.allTests),
    ]
}
#endif
