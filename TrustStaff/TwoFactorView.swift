import SwiftUICore
import SwiftUI
struct TwoFactorView: View {
    @State private var code = ""
    @State private var errorMessage = ""
    @State private var isVerified = false
    @State private var resendDelay = 60
    @State private var timer: Timer? = nil
    let email: String

    var body: some View {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Введите код из письма")
                        .font(.title2)
                        .bold()

                    TextField("Код подтверждения", text: $code)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }

                    Button("Подтвердить") {
                        APIService.verify2FA(email: email, code: code) { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    isVerified = true
                                } else {
                                    errorMessage = error ?? "Ошибка"
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    if resendDelay > 0 {
                        Text("Можно запросить код повторно через \(resendDelay) сек.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } else {
                        Button("Отправить код повторно") {
                            APIService.resend2FA(email: email) { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        errorMessage = "Код отправлен повторно"
                                        startResendTimer()
                                    } else {
                                        errorMessage = error ?? "Ошибка"
                                    }
                                }
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .onAppear {
                    startResendTimer()
                }
                .navigationDestination(isPresented: $isVerified) {
                    HomeView()
                }
            }
        }

    private func startResendTimer() {
        resendDelay = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if resendDelay > 0 {
                resendDelay -= 1
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }
}
