import Foundation

// This is an example Swift file to demonstrate the fix for unnecessary 'try'

func nonThrowingFunction() -> String {
    return "Hello, world!"
}

func throwingFunction() throws -> String {
    throw NSError(domain: "Example", code: 1, userInfo: nil)
}

func exampleUsage() {
    // Correct usage of try with a throwing function
    do {
        let result = try throwingFunction()
        print(result)
    } catch {
        print("Caught an error: \(error)")
    }

    // Incorrect usage of try with a non-throwing function (line 68)
    // let greeting = try nonThrowingFunction() // Original line with unnecessary 'try'

    // Fixed line without 'try'
    let greeting = nonThrowingFunction()
    print(greeting)
}

exampleUsage()
