import SwiftUI

public extension EnvironmentValues {
    /// Whether the first rendered content is revealed through a gradient. Defaults to false.
    var markdownInitialReveal: Bool {
        get { self[MarkdownInitialRevealKey.self] }
        set { self[MarkdownInitialRevealKey.self] = newValue }
    }
}
