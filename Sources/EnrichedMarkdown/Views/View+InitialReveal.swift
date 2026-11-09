import SwiftUI

public extension View {
    /// Reveals the first rendered content, line by line through a soft gradient.
    /// Blocks wait for all earlier indices in the same sequence to finish.
    /// Start indices at zero without gaps. Respects Reduce Motion.
    func markdownInitialReveal(_ enabled: Bool = true, in sequence: MarkdownRevealSequence, at index: Int) -> some View {
        let reveal = enabled ? MarkdownInitialReveal(sequence: sequence, index: index) : nil
        return environment(\.markdownInitialReveal, reveal)
    }
}
