//
//  RankingView.swift
//  MusicLibrary
//

import SwiftUI

struct RankingView: View {
    @EnvironmentObject var rankingVM: RankingViewModel
    @EnvironmentObject var libraryVM: LibraryViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("ランキング種別", selection: $rankingVM.rankingType) {
                    ForEach(RankingType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Picker("期間", selection: $rankingVM.rankingPeriod) {
                    ForEach(RankingPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .bottom])

                List {
                    switch rankingVM.rankingType {
                    case .tracks:
                        ForEach(Array(rankingVM.topTracks.enumerated()), id: \.element.id) { index, track in
                            NavigationLink {
                                TrackDetailView(track: track)
                            } label: {
                                RankingRowView(rank: index + 1, track: track)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    case .artists:
                        ForEach(Array(rankingVM.topArtists.enumerated()), id: \.element.id) { index, artist in
                            NavigationLink {
                                ArtistDetailView(artist: artist)
                            } label: {
                                ArtistRankingRowView(rank: index + 1, artist: artist)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    case .albums:
                        ForEach(Array(rankingVM.topAlbums.enumerated()), id: \.element.id) { index, album in
                            NavigationLink {
                                AlbumDetailView(album: album)
                            } label: {
                                AlbumRankingRowView(rank: index + 1, album: album)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("ランキング")
            .onChange(of: rankingVM.rankingPeriod) { _, _ in
                rankingVM.buildRanking(
                    from: libraryVM.tracks,
                    artists: libraryVM.artists,
                    albums: libraryVM.albums
                )
            }
        }
    }
}
