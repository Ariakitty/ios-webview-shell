import SwiftUI

struct ContentView: View {
    var body: some View {
        WebShellView(
            url: "https://example.com",
            authKey: "your-secret-key",
            injectedCSS: """
                .desktop-only, .cookie-banner { display: none !important; }
                body { padding-bottom: 0 !important; }
            """,
            injectedJS: """
                window.__NATIVE_APP__ = true;
            """
        )
        .ignoresSafeArea()
    }
}
