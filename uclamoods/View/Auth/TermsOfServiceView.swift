//
//  TermsOfServiceView.swift
//  uclamoods
//
//  Created by Yang Gao on 6/4/25.
//


import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service for Morii")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Effective Date: June 4, 2025")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("""
                Welcome to Morii, a social media platform designed to help you capture and share fleeting moments. These Terms of Service ("Terms") govern your use of the Morii mobile application and related services (collectively, the "App"). By accessing or using the App, you agree to be bound by these Terms. If you do not agree, please do not use the App.
                """)
                    .font(.body)

                Group {
                    Text("1. Eligibility")
                        .font(.headline)
                    Text("""
                    You must be at least 13 years old to use Morii, in compliance with applicable laws. By using the App, you represent that you meet this age requirement and have the legal capacity to enter into these Terms.
                    """)
                        .font(.body)

                    Text("2. User Accounts")
                        .font(.headline)
                    Text("""
                    To use certain features of Morii, you must create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account. You may delete your account at any time via the Settings menu, which will remove your data in accordance with our Privacy Policy.
                    """)
                        .font(.body)

                    Text("3. User-Generated Content")
                        .font(.headline)
                    Text("""
                    You may create and share content, such as posts, photos, videos, and comments, on Morii. You retain ownership of your content but grant Morii a non-exclusive, royalty-free, worldwide license to use, display, and distribute your content for the purpose of operating and improving the App. You agree not to post content that is illegal, offensive, defamatory, or violates our Community Guidelines, including hate speech, nudity, or violence.
                    """)
                        .font(.body)

                    Text("4. Content Moderation")
                        .font(.headline)
                    Text("""
                    Morii employs automated tools, including profanity filters, and user reporting mechanisms to moderate content. We reserve the right to remove or restrict content that violates these Terms or our Community Guidelines. You may report inappropriate content via the App’s reporting features.
                    """)
                        .font(.body)

                    Text("5. Notifications")
                        .font(.headline)
                    Text("""
                    Morii may send you notifications about friend requests, likes, comments, or other activities, as permitted by your device settings. You can manage notification preferences in the App or your device settings.
                    """)
                        .font(.body)

                    Text("6. Location Tracking")
                        .font(.headline)
                    Text("""
                    Morii may request access to your location to enhance features, such as tagging posts with locations or showing nearby content. Location tracking is optional and will only occur with your explicit consent. You can manage location permissions in the App or your device settings.
                    """)
                        .font(.body)

                    Text("7. Termination")
                        .font(.headline)
                    Text("""
                    We may suspend or terminate your account for violating these Terms, our Community Guidelines, or applicable laws. You may terminate your account at any time via the Settings menu.
                    """)
                        .font(.body)

                    Text("8. Limitation of Liability")
                        .font(.headline)
                    Text("""
                    Morii is provided “as is” without warranties of any kind. We are not liable for any damages arising from your use of the App, including data loss, service interruptions, or third-party actions, to the fullest extent permitted by law.
                    """)
                        .font(.body)

                    Text("9. Privacy")
                        .font(.headline)
                    Text("""
                    Your use of Morii is also governed by our Privacy Policy, available at [Insert Privacy Policy URL]. Please review it to understand how we collect, use, and protect your data.
                    """)
                        .font(.body)

                    Text("10. Changes to Terms")
                        .font(.headline)
                    Text("""
                    We may update these Terms from time to time. We will notify you of significant changes via email or in-app notifications. Your continued use of the App after such changes constitutes acceptance of the updated Terms.
                    """)
                        .font(.body)

                    Text("11. Governing Law")
                        .font(.headline)
                    Text("""
                    These Terms are governed by the laws of [Your State/Country, e.g., California, USA], without regard to its conflict of law principles.
                    """)
                        .font(.body)

                    Text("12. Contact Us")
                        .font(.headline)
                    Text("""
                    For questions or support, contact us at moriionios@gmail.com.
                    """)
                        .font(.body)
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

