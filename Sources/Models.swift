import Foundation

struct Ingredient: Codable, Identifiable {
    let id: Int
    let name: String
    let category: String
}
struct CookingStep: Codable, Identifiable {
    var id: String { title }
    let title: String
    let station: String
    let instruction: String
    let ingredients: [Int]
    let seconds: Double
    let tolerance: Double
    let heat: Double
    let action: String
}
struct Recipe: Codable, Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let ingredients: [Int]
    let grams: String
    let steps: [CookingStep]
    let source: String
    var duration: Int { Int(steps.map(\.seconds).reduce(0,+)) }
}
struct Catalog: Codable {
    let ingredients: [Ingredient]
    let recipes: [Recipe]
    static func load() throws -> Catalog {
        guard let url = Bundle.main.url(forResource: "Catalog", withExtension: "json") else { throw CocoaError(.fileNoSuchFile) }
        return try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))
    }
}
struct StageResult: Identifiable {
    let id = UUID()
    let title: String
    let time: Double
    let heat: Double
    let technique: Double
    let burn: Double
    var score: Double {
        let value = max(0, min(100, time * 45 + heat * 25 + technique * 30 - burn * 30))
        return time < 0.3 ? min(49, value) : value
    }
}
// Pure deterministic scoring; heat exposure is integrated, not wall-clock alone.
enum CookingMath {
    static func timeQuality(elapsed: Double, ideal: Double, tolerance: Double) -> Double {
        max(0, 1 - max(0, abs(elapsed-ideal)-tolerance) / max(ideal * 0.7, 1))
    }
    static func thermalRate(temperature: Double, reference: Double) -> Double {
        max(0, min(2, (temperature-35) / max(1, reference-35)))
    }
}
