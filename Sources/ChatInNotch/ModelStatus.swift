import FoundationModels

/// Availability of the on-device model, in a form the UI can show. Reading it from a view keeps it live.
struct ModelStatus {
    let text: String
    let isReady: Bool

    static var current: ModelStatus {
        switch SystemLanguageModel.default.availability {
        case .available: ModelStatus(text: "Ready", isReady: true)
        case .unavailable(.appleIntelligenceNotEnabled): ModelStatus(text: "Apple Intelligence is off", isReady: false)
        case .unavailable(.modelNotReady): ModelStatus(text: "Downloading model…", isReady: false)
        case .unavailable(.deviceNotEligible): ModelStatus(text: "Mac not supported", isReady: false)
        case .unavailable: ModelStatus(text: "Unavailable", isReady: false)
        }
    }
}
