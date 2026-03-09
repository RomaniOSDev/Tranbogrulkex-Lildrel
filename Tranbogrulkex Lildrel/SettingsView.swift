import SwiftUI
import StoreKit

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                primaryActions
                legalSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(LinearGradient.appBackgroundGradient.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tune your experience")
                .font(.title.bold())
                .foregroundColor(.appTextPrimary)
            Text("Share your feedback or review how information is handled.")
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
        }
        .padding(.top, 24)
    }

    private var primaryActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: rateApp) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rate this experience")
                            .font(.headline)
                            .foregroundColor(.appTextPrimary)
                        Text("Leave a quick rating on the App Store.")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "star.leadinghalf.filled")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.appAccent)
                }
                .padding(14)
            }
            .buttonStyle(.plain)
            .appCardStyle(cornerRadius: 20)
        }
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Information")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            Button(action: openPrivacyPolicy) {
                HStack {
                    Text("Privacy policy")
                        .font(.subheadline)
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                .padding(12)
            }
            .buttonStyle(.plain)
            .appCardStyle(cornerRadius: 18)

            Button(action: openTermsOfUse) {
                HStack {
                    Text("Terms of use")
                        .font(.subheadline)
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                .padding(12)
            }
            .buttonStyle(.plain)
            .appCardStyle(cornerRadius: 18)
        }
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://adminka.site/nenflapra109cregrarvar.site/privacy/26") {
            UIApplication.shared.open(url)
        }
    }

    private func openTermsOfUse() {
        if let url = URL(string: "https://adminka.site/nenflapra109cregrarvar.site/terms/26") {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

