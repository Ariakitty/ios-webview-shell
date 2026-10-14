# ios-webview-shell

把你的网页装进 iPhone — SwiftUI + WKWebView 套壳 App 指南

---

## 这是什么

"套壳 App" 就像给你的网页穿了一件 iOS 的外套。

想象你有一个已经在浏览器里跑得很好的网页（比如一个 dashboard、一个工具页面），你想让它变成手机上的独立 App，有自己的图标，打开不用输网址，还能用 iPhone 的原生功能（推送通知、HealthKit、摄像头等等）。

这就是套壳 App 做的事：

```
┌─────────────────────────┐
│  iOS Native Shell       │  ← SwiftUI 外壳（穿的衣服）
│  ┌───────────────────┐  │
│  │                   │  │
│  │   Your Website    │  │  ← WKWebView 加载你的网页（身体）
│  │                   │  │
│  │                   │  │
│  └───────────────────┘  │
│  JS Bridge ←→ Swift     │  ← 网页和原生代码之间的翻译官
└─────────────────────────┘
```

## 适用场景

- 你有一个 Cloudflare Worker / Vercel / 任意服务器上跑着的网页
- 你想在手机主屏幕上有个图标一点就打开
- 你想要推送通知、HealthKit、NFC 等原生能力
- 你不想用 Swift 重写整个前端

## 准备

| 工具 | 干嘛用的 | 安装 |
|------|---------|------|
| Xcode | 苹果的开发工具，像画画要用画板 | Mac App Store 搜 Xcode |
| xcodegen | 用一个小文件自动生成 Xcode 项目，省得手动点一堆设置 | `brew install xcodegen` |
| Apple ID | 开发者账号，免费的就行（只是测试用） | [developer.apple.com](https://developer.apple.com) |

## 项目结构

```
ios-webview-shell/
├── project.yml              ← 项目配置（告诉 xcodegen 怎么生成 Xcode 项目）
├── Sources/
│   ├── Info.plist            ← App 的身份证（名字、版本、权限）
│   ├── WebShellApp.swift     ← 入口，3 行代码
│   ├── ContentView.swift     ← 主视图，在这里配置你的网址
│   └── WebShellView.swift    ← WKWebView 封装（核心，通常不用改）
├── demo-page/
│   └── index.html            ← 示例网页（可以用浏览器直接打开看效果）
└── README.md
```

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/Ariakitty/ios-webview-shell.git
cd ios-webview-shell
```

### 2. 改成你的网址

打开 `Sources/ContentView.swift`，把 URL 换成你的网页地址：

```swift
struct ContentView: View {
    var body: some View {
        WebShellView(
            url: "https://your-website.com",     // ← 改成你的网址
            authKey: "your-secret-key",           // ← 自动登录密码（可选）
            injectedCSS: """
                .desktop-only { display: none !important; }
            """,
            injectedJS: """
                window.__NATIVE_APP__ = true;
            """
        )
        .ignoresSafeArea()
    }
}
```

### 3. 生成 Xcode 项目

```bash
xcodegen generate
```

这一步就像用模具压饼干——`project.yml` 是模具，`xcodegen` 是你的手，压出来的 `.xcodeproj` 就是饼干。以后改项目配置只要改 `project.yml` 然后重新压一次就行。

### 4. 打开 & 运行

```bash
open WebShell.xcodeproj
```

在 Xcode 里选你的 iPhone（或模拟器），点左上角的 ▶️ 按钮。

## 核心概念

### WKWebView = 一个看不见边框的 Safari

WKWebView 是 iOS 系统内置的浏览器引擎。你可以把它想象成一个没有地址栏、没有标签页、没有工具栏的 Safari，只剩下网页内容本身。它和 Safari 用完全一样的渲染引擎，所以你的网页在 Safari 里长什么样，在 App 里就长什么样。

### JS Bridge = 翻译官

网页（JavaScript）和 iOS 原生代码（Swift）说的是两种不同的语言。JS Bridge 就是它们之间的翻译官。

在这个项目里，翻译官做了三件事：

**1. 注入身份标识**

```javascript
window.__NATIVE_APP__ = true;
```

这样你的网页就能判断自己是在浏览器里打开的，还是在 App 里打开的，然后做出不同的反应（比如隐藏某些按钮、开启某些功能）。

**2. 自动登录**

```javascript
localStorage.setItem('auth_key', 'your-secret-key');
```

如果你的网页需要密码，通过这个注入，打开 App 就自动登录了，不用每次手动输。

**3. 注入 CSS（整容）**

```css
.desktop-only { display: none !important; }
body { padding-bottom: 0 !important; }
```

把网页上不适合手机的东西藏起来，比如桌面版的导航栏、多余的间距。这就像给网页做了个微整形，让它更适合在小屏幕上生活。

### 注入时机

代码里有一个关键概念：`injectionTime: .atDocumentStart`。

这意味着 JS 和 CSS 在网页开始加载的那一刻就注入了，比网页自己的代码都早。就像你在客人到达之前就把房间布置好了，而不是等客人进门了再手忙脚乱地挪家具。

如果你的某些代码需要在网页完全加载后才执行（比如要操作网页上的按钮），可以用 `.atDocumentEnd`：

```swift
let lateScript = WKUserScript(
    source: "document.querySelector('.btn').click();",
    injectionTime: .atDocumentEnd,
    forMainFrameOnly: true
)
controller.addUserScript(lateScript)
```

## 进阶

### 多个 Tab

如果你想像微信那样底部有多个标签页：

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            WebShellView(url: "https://your-site.com/home")
                .tabItem { Label("Home", systemImage: "house") }
            
            WebShellView(url: "https://your-site.com/chat")
                .tabItem { Label("Chat", systemImage: "bubble.left") }
            
            WebShellView(url: "https://your-site.com/settings")
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
```

### 从 Swift 调用网页里的 JS

```swift
webView.evaluateJavaScript("document.title") { result, error in
    if let title = result as? String {
        print("Page title: \(title)")
    }
}
```

### 从网页调用 Swift 原生代码

在 `WebShellView.swift` 里添加消息处理器（就像注册一个信箱，网页往里面投信，Swift 来收信）：

```swift
// 注册信箱
controller.add(context.coordinator, name: "nativeBridge")

// Swift 端收信
class Coordinator: NSObject, WKScriptMessageHandler {
    func userContentController(_ controller: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "nativeBridge" {
            print("Received from web: \(message.body)")
        }
    }
}
```

```javascript
// 网页端投信
window.webkit.messageHandlers.nativeBridge.postMessage({
    action: "vibrate",
    data: { intensity: 0.8 }
});
```

### PWA 兼容

如果你的网页同时也想在 Safari 里当 PWA（添加到主屏幕）用，在 HTML 里加这些：

```html
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
```

然后在 CSS 里处理刘海屏：

```css
body {
    padding-top: env(safe-area-inset-top);
    padding-bottom: env(safe-area-inset-bottom);
}
```

## Demo 页面

`demo-page/index.html` 是一个最简单的示例网页，可以直接用浏览器打开看效果。它会自动检测是否在 native shell 里运行，并显示不同的状态。

把 `ContentView.swift` 里的 URL 指向你本地跑的服务器（或者把 HTML 部署到任意地方），就可以看到套壳效果。

## 踩坑记录

这些是实际开发中踩过的坑：

1. **xcodegen 会清空 entitlements** — 每次 `xcodegen generate` 之后，如果你手动改过 `.entitlements` 文件（比如加了推送、HealthKit 权限），它会被重置成空的。解决办法：在 `project.yml` 里声明 entitlements 路径，或者 generate 之后立刻重新写入
2. **Cookie 在 WKWebView 里不好使** — iOS Safari 和 WKWebView 的 cookie 是隔离的。如果你的网页靠 cookie 做登录，在 App 里会登不上。改用 localStorage（像上面 authKey 那样注入）更靠谱
3. **底部空白太多** — WKWebView 默认会给底部加安全区间距。加上 `scrollView.contentInsetAdjustmentBehavior = .never` 和 CSS 注入 `padding-bottom: 0` 就好了
4. **网页里的链接会跳到 Safari** — 默认情况下，`target="_blank"` 的链接会用 Safari 打开。如果你想全部在 App 内打开，需要实现 `WKNavigationDelegate` 拦截导航
5. **iOS Safari 和 WKWebView 的 JS 限制不同** — 有些 Web API（比如某些 Service Worker 功能）在 WKWebView 里不支持。如果你的网页依赖这些，需要提前确认兼容性

## License

MIT
