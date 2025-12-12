//
//  ContentView.swift
//  msdk-demo
//
//  Created by Jing Hao on 12/2/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("MSDK Demo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Select an integration type")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                // Options List
                VStack(spacing: 16) {
                    // Native View - Enabled
                    NavigationLink(destination: NativeProductDetailView()) {
                        OptionCard(
                            title: "Native view",
                            description: "Native iOS integration with Klarna SDK",
                            isEnabled: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Hybrid - Enabled
                    NavigationLink(destination: HybridProductDetailView()) {
                        OptionCard(
                            title: "Hybrid",
                            description: "Web checkout in native WebView",
                            isEnabled: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Klarna WebView - Disabled
                    OptionCard(
                        title: "Klarna WebView",
                        description: "Coming soon",
                        isEnabled: false
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

struct OptionCard: View {
    let title: String
    let description: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isEnabled ? .primary : .gray)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isEnabled {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isEnabled ? Color(UIColor.systemBackground) : Color(UIColor.systemGray6))
                .shadow(color: Color.black.opacity(isEnabled ? 0.1 : 0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

#Preview {
    ContentView()
}
