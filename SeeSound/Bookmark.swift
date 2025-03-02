import Foundation

struct Bookmark: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: String
    
    init(id: UUID = UUID(), title: String, url: String) {
        self.id = id
        self.title = title
        self.url = url
    }
} 