import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isScrolling: Bool
    @Binding var currentURL: URL
    let scrollSpeed: Double
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.delegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        
        // 메모리 관리 개선
        webView.configuration.processPool = WKProcessPool()
        webView.configuration.websiteDataStore = WKWebsiteDataStore.default()
        
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
    }
} 
