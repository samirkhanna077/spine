//
//  ContentView.swift
//  spine-app
//
//  Created by Ethan Gibbs on 2/2/25.
//

import SwiftUI

import SwiftUI

enum Tab: Int {
    case feed, log, post, profile
}

struct ContentView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var selectedTab: Tab = .feed
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                FeedView()
                    .tag(Tab.feed)
                
                ReadingLogView()
                    .tag(Tab.log)
                
                PostView()
                    .tag(Tab.post)
                
                ProfileView()
                    .tag(Tab.profile)
            }
            
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .environmentObject(userViewModel)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack {
            tabButton(tab: .feed, icon: "book", title: "Feed")   // Stylish photo icon
            Spacer()
            tabButton(tab: .post, icon: "plus.circle", title: "Post")
            Spacer()
            tabButton(tab: .log, icon: "book.closed", title: "Log")        // Stylish book icon
            Spacer()
            tabButton(tab: .profile, icon: "person.crop.circle", title: "Profile")
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 20)
        .background(
            BlurView(style: .systemUltraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                .shadow(radius: 10)
        )
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
    
    @ViewBuilder
    func tabButton(tab: Tab, icon: String, title: String) -> some View {
        Button(action: {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? "\(icon).fill" : icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
