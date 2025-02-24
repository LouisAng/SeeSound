import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isScrolling: Bool
    @Binding var currentURL: URL
    let scrollSpeed: Double
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // 모바일 뷰 설정 추가
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.delegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        
        // 모바일 User-Agent 설정
        let mobileUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
        webView.customUserAgent = mobileUserAgent
        
        // 메모리 관리 개선
        webView.configuration.processPool = WKProcessPool()
        webView.configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        // 노티피케이션 옵저버 추가
        NotificationCenter.default.addObserver(forName: .init("goBack"), object: nil, queue: .main) { _ in
            webView.goBack()
        }
        NotificationCenter.default.addObserver(forName: .init("goForward"), object: nil, queue: .main) { _ in
            webView.goForward()
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url?.absoluteString != url.absoluteString {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        if isScrolling {
            if context.coordinator.displayLink != nil {
                context.coordinator.currentSpeed = scrollSpeed
                context.coordinator.lastSetSpeed = scrollSpeed  // lastSetSpeed도 업데이트
            } else {
                context.coordinator.startAutoScroll(webView: webView, speed: scrollSpeed)
            }
        } else {
            context.coordinator.stopAutoScroll()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate, WKNavigationDelegate {
        var parent: WebView
        var displayLink: CADisplayLink?
        weak var webView: WKWebView?
        var currentSpeed: Double = 0.0
        var lastSetSpeed: Double = 0.0  // 마지막으로 설정된 속도 저장
        
        init(_ parent: WebView) {
            self.parent = parent
            super.init()
        }
        
        func startAutoScroll(webView: WKWebView, speed: Double) {
            stopAutoScroll()
            self.webView = webView
            self.currentSpeed = speed
            self.lastSetSpeed = speed  // 속도 저장
            
            displayLink = CADisplayLink(target: self, selector: #selector(autoScroll))
            displayLink?.preferredFramesPerSecond = 60
            displayLink?.add(to: .main, forMode: .common)
            
            print("스크롤 시작 - 속도: \(speed)")  // 디버깅용
        }
        
        func stopAutoScroll() {
            displayLink?.invalidate()
            displayLink = nil
        }
        
        @objc func autoScroll() {
            guard let webView = webView else { return }
            let scrollView = webView.scrollView
            
            let speed = currentSpeed
            
            let pixelsPerFrame = max(0.5, speed / 60.0)  // 프레임당 최소 0.5픽셀 이동
            
            let currentOffset = scrollView.contentOffset.y
            let maxScrollOffset = scrollView.contentSize.height - scrollView.bounds.height
            
            if currentOffset >= maxScrollOffset {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.isScrolling = false
                }
                stopAutoScroll()
                return
            }
            
            let newY = currentOffset + pixelsPerFrame
            if !newY.isNaN && newY.isFinite {
                scrollView.setContentOffset(
                    CGPoint(x: scrollView.contentOffset.x, y: newY),
                    animated: false
                )
            }
        }
        
        // URL 변경 처리
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.request.url?.absoluteString == "about:blank" {
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
            
            if let url = navigationAction.request.url,
               url.absoluteString != "about:blank" {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.currentURL = url
                }
            }
        }
        
        // 수동 스크롤 처리
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            if parent.isScrolling {
                stopAutoScroll()
            }
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if parent.isScrolling, let webView = webView {
                // 마지막으로 설정된 속도로 다시 시작
                startAutoScroll(webView: webView, speed: lastSetSpeed)
            }
        }
        
        // 웹뷰 상태 변경 시 호출
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.canGoBack = webView.canGoBack
                self?.parent.canGoForward = webView.canGoForward
            }
        }
    }
} 
