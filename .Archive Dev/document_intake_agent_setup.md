// DocShopApp.swift import SwiftUI

@main struct DocShopApp: App { var body: some Scene { WindowGroup { ContentView() } } }

// ContentView\.swift import SwiftUI

struct ContentView: View { var body: some View { HStack(spacing: 0) { SessionListView() .frame(minWidth: 220, idealWidth: 250, maxWidth: 300) .background(Color(NSColor.windowBackgroundColor))

```
        Divider()

        AgentInteractionView()
    }
    .frame(minWidth: 800, minHeight: 500)
}
```

}

// SessionListView\.swift import SwiftUI

struct SessionListView: View { var body: some View { VStack(alignment: .leading) { Text("DocShop") .font(.title) .padding([.top, .leading])

```
        DocumentDropView()
            .padding()

        Spacer()
    }
}
```

}

// AgentInteractionView\.swift import SwiftUI

struct AgentInteractionView: View { @State private var outputText = "Waiting for import..."

```
var body: some View {
    VStack(alignment: .leading) {
        Text("Import Status")
            .font(.headline)
            .padding(.top)

        ScrollView {
            Text(outputText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .padding()
}
```

}

// DocumentDropView\.swift import SwiftUI

struct DocumentDropView: View { @State private var urlString: String = ""

```
var body: some View {
    VStack(alignment: .leading) {
        TextField("Enter documentation URL", text: $urlString)
            .textFieldStyle(RoundedBorderTextFieldStyle())

        Button("Import into Library") {
            Task {
                await DocProcessingAgent.shared.importFrom(urlString: urlString)
            }
        }
        .padding(.top, 8)
    }
}
```

}

// DocProcessingAgent.swift import Foundation import SwiftSoup

class DocProcessingAgent { static let shared = DocProcessingAgent()

```
private let importedPath: URL = {
    let docsPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("DocShop/Docs/Imported", isDirectory: true)
    try? FileManager.default.createDirectory(at: docsPath, withIntermediateDirectories: true)
    return docsPath
}()

func importFrom(urlString: String) async {
    guard let url = URL(string: urlString) else { return }

    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else { return }

        let doc = try SwiftSoup.parse(html)
        let text = try doc.body()?.text() ?? ""

        let fileName = sanitizeFileName(from: urlString)
        let fileURL = importedPath.appendingPathComponent(fileName + ".md")

        try text.write(to: fileURL, atomically: true, encoding: .utf8)
        print("✅ Imported: \(fileURL.path)")

    } catch {
        print("❌ Failed to import: \(error.localizedDescription)")
    }
}

private func sanitizeFileName(from url: String) -> String {
    return url
        .replacingOccurrences(of: "https://", with: "")
        .replacingOccurrences(of: "http://", with: "")
        .replacingOccurrences(of: "/", with: "-")
        .replacingOccurrences(of: "?", with: "")
        .replacingOccurrences(of: "&", with: "")
        .replacingOccurrences(of: "=", with: "")
}
```

}

