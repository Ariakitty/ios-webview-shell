import SwiftUI
import WebKit

struct WebShellView: UIViewRepresentable {
    let url: String
    var authKey: String? = nil
    var injectedCSS: String? = nil
    var injectedJS: String? = nil

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()

        var earlyScript = ""

        if let key = authKey {
            earlyScript += "localStorage.setItem('auth_key', '\(key)');\n"
        }

        if let css = injectedCSS {
            let escaped = css
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")
            earlyScript += """
            (function() {
                var s = document.createElement('style');
                s.textContent = '\(escaped)';
                (document.head || document.documentElement).appendChild(s);
            })();
            """
        }

        if let js = injectedJS {
            earlyScript += js + "\n"
        }

        if !earlyScript.isEmpty {
            let script = WKUserScript(
                source: earlyScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            controller.addUserScript(script)
        }

        config.userContentController = controller
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear

        if let requestURL = URL(string: url) {
            webView.load(URLRequest(url: requestURL))
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
