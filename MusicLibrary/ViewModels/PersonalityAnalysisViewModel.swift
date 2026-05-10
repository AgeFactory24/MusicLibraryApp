// PersonalityAnalysisViewModel.swift
// MusicLibrary

import SwiftUI
import Combine

@MainActor
final class PersonalityAnalysisViewModel: ObservableObject {
    @Published var tags: [PersonalityTag] = []
    @Published var metrics: ListeningMetrics?
    @Published var isLoading: Bool = false

    private var lastAnalyzedCount: Int = -1

    func analyze(tracks: [Track]) {
        guard !tracks.isEmpty else { return }
        guard tracks.count != lastAnalyzedCount else { return }
        lastAnalyzedCount = tracks.count
        isLoading = true
        defer { isLoading = false }

        let m = PersonalityAnalysisEngine.buildMetrics(from: tracks)
        metrics = m
        tags = PersonalityAnalysisEngine.evaluate(metrics: m, topCount: 5)
    }
}
