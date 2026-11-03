import SwiftUI

public extension View {
    /// Reveals the first rendered content, line by line through a soft gradient.
    /// Starts after native layout and respects Reduce Motion. Defaults to false.
    /// Use a separate view for each immutable block when displaying a stream.
    func markdownInitialReveal(_ enabled: Bool = true) -> some View {
        environment(\.markdownInitialReveal, enabled)
    }
}
