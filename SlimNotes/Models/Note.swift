import Foundation

struct Note: Identifiable, Codable {
    var id = UUID()
    var title: String = ""
    var body: String = ""
    var createdAt = Date()
    var updatedAt = Date()

    var displayTitle: String { title.isEmpty ? "제목 없음" : title }
    var preview: String { String(body.prefix(60)).replacingOccurrences(of: "\n", with: " ") }
    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: updatedAt)
    }
}
