import SwiftUI

struct RegisterView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var navigateToVerify = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Заголовок
                VStack(spacing: 6) {
                    Text("Регистрация")
                        .font(.largeTitle).bold()
                    Text("Создайте аккаунт в TrustStaff")
                        .foregroundColor(.gray)
                }
                .padding(.top)

                // Поля
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "person")
                        TextField("Имя", text: $name)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)

                    HStack {
                        Image(systemName: "envelope")
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)

                    HStack {
                        Image(systemName: "lock")
                        SecureField("Пароль", text: $password)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }

                // Ошибка
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                // Кнопка регистрации
                Button(action: register) {
                    Text("Зарегистрироваться")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer()

                // Скрытый переход
                NavigationLink(
                    destination: VerifyView(),
                    isActive: $navigateToVerify
                ) {
                    EmptyView()
                }
                .hidden()
                .frame(height: 0)
            }
            .padding()
            .navigationTitle("Регистрация")
        }
    }

    func register() {
        guard let url = URL(string: "https://app.truststaff.ru/api/register") else {
            errorMessage = "Неверный URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = [
            "name": name,
            "email": email,
            "password": password
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            errorMessage = "Ошибка сериализации"
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONDecoder().decode(RegisterResponse.self, from: data),
                   json.status == "ok" {
                    errorMessage = nil
                    navigateToVerify = true
                } else {
                    errorMessage = "Ошибка регистрации"
                }
            }
        }.resume()
    }
}

struct RegisterResponse: Decodable {
    let status: String
    let message: String?
}
