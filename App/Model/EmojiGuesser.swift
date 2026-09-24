import Foundation

/// Picks an emoji for a breadcrumb so it's recognizable at a glance in the Dynamic Island.
enum EmojiGuesser {
    private static let table: [(keywords: Set<String>, emoji: String)] = [
        (["key", "keys"], "🔑"),
        (["scissor", "scissors"], "✂️"),
        (["charger", "charge", "cable", "plug"], "🔌"),
        (["plant", "plants", "flowers"], "🪴"),
        (["water", "drink", "bottle"], "💧"),
        (["pill", "pills", "meds", "medicine", "vitamin", "vitamins"], "💊"),
        (["glasses", "sunglasses", "contacts"], "👓"),
        (["wallet", "card", "cash", "money"], "👛"),
        (["laundry", "washing", "clothes", "towel", "towels"], "🧺"),
        (["call", "ring", "phone"], "📞"),
        (["email", "mail", "reply", "text", "message", "dm"], "✉️"),
        (["dog", "puppy", "walk"], "🐶"),
        (["cat", "litter"], "🐱"),
        (["trash", "garbage", "bin", "rubbish", "recycling"], "🗑️"),
        (["milk"], "🥛"),
        (["coffee", "tea"], "☕️"),
        (["homework", "assignment", "essay", "study", "exam"], "📝"),
        (["book", "read", "reading"], "📖"),
        (["pen", "pencil", "paper", "notebook"], "✏️"),
        (["oven", "stove", "cook", "cooking", "dinner", "lunch", "breakfast", "food", "snack"], "🍳"),
        (["battery", "batteries"], "🔋"),
        (["box", "package", "parcel", "tape"], "📦"),
        (["light", "lamp", "bulb", "lights"], "💡"),
        (["shoes", "shoe", "sock", "socks"], "👟"),
        (["jacket", "coat", "hoodie", "sweater"], "🧥"),
        (["bag", "backpack"], "🎒"),
        (["headphones", "earbuds", "airpods"], "🎧"),
        (["laptop", "computer", "ipad"], "💻"),
        (["remote", "tv"], "📺"),
        (["password", "code", "login"], "🔐"),
        (["pay", "bill", "bills", "rent"], "💸"),
        (["gift", "present", "birthday"], "🎁"),
        (["umbrella"], "☂️"),
        (["toothbrush", "teeth", "floss"], "🪥"),
        (["shower", "bath"], "🚿"),
        (["car", "gas", "parking"], "🚗"),
        (["bike"], "🚲"),
        (["photo", "photos", "picture", "camera"], "📷"),
        (["calendar", "appointment", "meeting"], "📅"),
    ]

    static func guess(for text: String) -> String {
        let words = Set(text.lowercased().split { !$0.isLetter }.map(String.init))
        for entry in table where !entry.keywords.isDisjoint(with: words) {
            return entry.emoji
        }
        return "🍞"
    }
}
