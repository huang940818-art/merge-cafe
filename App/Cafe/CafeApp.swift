import SwiftUI
import WebKit

@main
struct CafeApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                .ignoresSafeArea()
                .background(Color(red: 0.965, green: 0.937, blue: 0.894))
                .statusBarHidden(false)
        }
    }
}

/// 存檔放 Application Support/save.json，不靠 WKWebView 的 localStorage
enum SaveFile {
    static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("save.json")
    }
    static func read() -> String? { try? String(contentsOf: url, encoding: .utf8) }
    static func write(_ s: String) { try? s.write(to: url, atomically: true, encoding: .utf8) }
}

struct GameView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.allowsInlineMediaPlayback = true
        let ucc = WKUserContentController()
        ucc.add(context.coordinator, name: "save")
        // 開頁前先把存檔塞進去，遊戲的 load() 會先讀這個
        if let saved = SaveFile.read(),
           let data = try? JSONEncoder().encode(saved),
           let lit = String(data: data, encoding: .utf8) {
            ucc.addUserScript(WKUserScript(source: "window.__NATIVE_SAVE = \(lit);",
                                           injectionTime: .atDocumentStart, forMainFrameOnly: true))
        } else {
            ucc.addUserScript(WKUserScript(source: "window.__NATIVE_SAVE = null;",
                                           injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        cfg.userContentController = ucc

        let web = WKWebView(frame: .zero, configuration: cfg)
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 0.965, green: 0.937, blue: 0.894, alpha: 1)
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.allowsLinkPreview = false
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "web") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
            if let s = m.body as? String { SaveFile.write(s) }
        }
    }
}
