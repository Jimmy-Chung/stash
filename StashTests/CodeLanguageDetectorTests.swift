import XCTest
@testable import Stash

final class CodeLanguageDetectorTests: XCTestCase {

    // U-18: SELECT * FROM users → SQL
    func testDetectSQL() {
        let code = "SELECT * FROM users WHERE id = 1 ORDER BY name"
        let result = CodeLanguageDetector.detect(code)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.language, "SQL")
    }

    // U-19: TypeScript keywords → TypeScript
    func testDetectTypeScript() {
        let code = """
        interface User {
          name: string;
          age: number;
        }
        const getUser = (): void => {
          return null;
        };
        """
        let result = CodeLanguageDetector.detect(code)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.language, "TypeScript")
    }

    func testDetectPython() {
        let code = """
        def hello(name):
            print(f"Hello, {name}")
            return True
        """
        let result = CodeLanguageDetector.detect(code)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.language, "Python")
    }

    func testDetectJSON() {
        let code = """
        {"name": "John", "age": 30, "city": "New York"}
        """
        let result = CodeLanguageDetector.detect(code)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.language, "JSON")
    }

    func testShortTextNotCode() {
        let result = CodeLanguageDetector.detect("hello")
        XCTAssertNil(result)
    }
}
