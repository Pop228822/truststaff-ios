import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var message: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            Text("🔒 Восстановление пароля")
                .font(.title2)
                .bold()

            TextField("Введите email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)

            if let message = message {
                Text(message)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Button(action: submit) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Отправить письмо")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            Spacer()
        }
        .padding()
    }

    func submit() {
        guard let url = URL(string: "https://app.truststaff.ru/api/forgot-password") else { return }
        isLoading = true
        message = nil

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "email=\(email)".data(using: .utf8)

        URLSession.shared.dataTask(with: request) { _, _, _ in
            DispatchQueue.main.async {
                isLoading = false
                message = "Если пользователь существует, письмо отправлено."
            }
        }.resume()
    }
}
