//
//  AboutView.swift
//  nextcloud_user_management
//
//  Created by Georgios Stavropoulos on 19/01/2026.
//
// Copyright (c) 2025 Georgios [Last Name]. All rights reserved.
// Licensed under the Source Available License. See LICENSE file for details.
import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacyPolicy = false
    
    // App version info
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        NavigationStack {
            List {
                // App Info Section
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.blue)
                            
                            Text("NC User Admin")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Version \(appVersion) (\(buildNumber))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                
                // Description
                Section {
                    Text("NC User Admin is a powerful, native iOS app designed for Nextcloud administrators. Easily manage users and groups, control account access, and monitor system activity - all from the convenience of your iPhone or iPad. Whether you're enabling new accounts, organizing group memberships, or checking user quotas, NC User Admin provides a fast, secure, and intuitive interface for all your user management needs.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("About")
                }
                
                // Features
                Section("Features") {
                    FeatureRow(icon: "person.2", title: "User Management", description: "View and manage all users")
                    FeatureRow(icon: "person.3", title: "Group Management", description: "Organize users into groups")
                    FeatureRow(icon: "checkmark.circle", title: "Account Control", description: "Enable/disable user accounts")
                    FeatureRow(icon: "line.3.horizontal.decrease.circle", title: "Filter & Sort", description: "Find users quickly")
                    FeatureRow(icon: "lock.shield", title: "Secure Storage", description: "Keychain-protected credentials")
                    FeatureRow(icon: "faceid", title: "Biometric Auth", description: "Face ID / Touch ID support")
                }
                
                // Requirements
                Section("Requirements") {
                    RequirementRow(icon: "server.rack", title: "Nextcloud Server", value: "v15 or later")
                    RequirementRow(icon: "person.badge.key", title: "Permissions", value: "Admin or Group Admin")
                    RequirementRow(icon: "iphone", title: "iOS Version", value: "17.0 or later")
                }
                
                // Developer Info
                Section("Developer") {
                    LabeledContent("Created by", value: "Georgios Stavropoulos")
                    LabeledContent("Support", value: "bursts.mansard-0v@icloud.com")
                        .textSelection(.enabled)
                    LabeledContent("Year", value: "2026")
                }
                
                // Links
                Section("Support & Resources") {
                    // Email Support
                    Link(destination: URL(string: "mailto:bursts.mansard-0v@icloud.com?subject=NC%20User%20Admin%20Support")!) {
                        HStack {
                            Label("Email Support", systemImage: "envelope")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://docs.nextcloud.com")!) {
                        HStack {
                            Label("Nextcloud Documentation", systemImage: "book")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/nextcloud")!) {
                        HStack {
                            Label("Nextcloud on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Privacy & Legal
                Section {
                    Button {
                        showingPrivacyPolicy = true
                    } label: {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This app does not collect, store, or share any of your personal data. All information stays on your device.")
                            .font(.caption)
                        
                        Text("This app is not officially affiliated with Nextcloud GmbH. Nextcloud is a trademark of Nextcloud GmbH.")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RequirementRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Last Updated: January 19, 2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        PolicySection(
                            title: "Data Collection",
                            content: "NC User Admin does not collect, transmit, or store any personal data outside of your device. All app functionality is performed locally on your device."
                        )
                        
                        PolicySection(
                            title: "Credentials Storage",
                            content: "Your Nextcloud server credentials (URL, username, and password) are stored securely in your device's Keychain using industry-standard encryption. This data never leaves your device and is protected by iOS security features."
                        )
                        
                        PolicySection(
                            title: "Network Communication",
                            content: "The app communicates directly with your Nextcloud server using secure HTTPS connections. No data is transmitted to third parties or external services. All communication occurs exclusively between your device and your configured Nextcloud server."
                        )
                        
                        PolicySection(
                            title: "Biometric Authentication",
                            content: "If you enable Face ID or Touch ID, this authentication is handled entirely by iOS. The app does not have access to your biometric data. Biometric authentication simply unlocks access to your stored credentials in the Keychain."
                        )
                        
                        PolicySection(
                            title: "Analytics",
                            content: "This app does not use any analytics services, tracking pixels, or telemetry. Your usage of the app is completely private."
                        )
                        
                        PolicySection(
                            title: "Third-Party Services",
                            content: "The app does not integrate with any third-party services, SDKs, or frameworks that collect user data."
                        )
                        
                        PolicySection(
                            title: "Children's Privacy",
                            content: "This app does not knowingly collect information from children. The app is intended for Nextcloud administrators managing their server instances."
                        )
                        
                        PolicySection(
                            title: "Changes to This Policy",
                            content: "Any updates to this privacy policy will be reflected in app updates. Continued use of the app after updates constitutes acceptance of any changes."
                        )
                        
                        PolicySection(
                            title: "Contact",
                            content: "If you have questions about this privacy policy, please contact: bursts.mansard-0v@icloud.com"
                        )
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    AboutView()
}
#Preview("Privacy Policy") {
    PrivacyPolicyView()
}

