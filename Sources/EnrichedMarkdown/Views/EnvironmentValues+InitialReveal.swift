import SwiftUI

extension EnvironmentValues {
    var markdownInitialReveal: MarkdownInitialReveal? {
        get { self[MarkdownInitialRevealKey.self] }
        set { self[MarkdownInitialRevealKey.self] = newValue }
    }
}
