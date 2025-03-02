import Foundation

struct Tab: Identifiable {
    let id: UUID
    var title: String
    var url: URL
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var isScrolling: Bool = false
    var scrollSpeed: Double = 50.0
    
    init(id: UUID = UUID(), title: String, url: URL) {
        self.id = id
        self.title = title
        self.url = url
    }
} 