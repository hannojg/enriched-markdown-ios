struct MarkdownInitialReveal: Equatable {
    let sequence: MarkdownRevealSequence
    let index: Int

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.sequence === rhs.sequence && lhs.index == rhs.index
    }
}
