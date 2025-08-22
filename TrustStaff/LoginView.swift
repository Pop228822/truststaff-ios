import SwiftUICore
import SwiftUI
struct LoginView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showTwoFA = false
    @State private var emailFor2FA = ""
    

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Заголовок
                VStack(spacing: 6) {
                    Text("Добро пожаловать")
                        .font(.largeTitle).bold()
                    Text("Войдите в TrustStaff")
                        .foregroundColor(.gray)
                }
                .padding(.top)

                // Поля
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "envelope")
                        TextField("example@mail.com", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)

                    HStack {
                        Image(systemName: "lock")
                        SecureField("Введите пароль", text: $password)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }

                // Ошибка
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                // Кнопка входа
                Button(action: login) {
                    Text("Войти")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                // Переходы
                VStack(spacing: 8) {
                    NavigationLink("Забыли пароль?", destination: ForgotPasswordView())
                        .font(.footnote)
                        .foregroundColor(.blue)

                    HStack {
                        Text("Впервые у нас?")
                            .font(.footnote)
                        NavigationLink("Зарегистрироваться", destination: RegisterView())
                            .font(.footnote.bold())
                    }
                }

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $appViewModel.isAuthenticated) {
                HomeView()
            }
            .navigationDestination(isPresented: $showTwoFA) {
                TwoFactorView(email: emailFor2FA)
            }
        }
    }

    func login() {
        APIService.login(email: email, password: password) { success, error in
            DispatchQueue.main.async {
                if success {
                    appViewModel.isAuthenticated = true
                } else if error == "2fa_required" {
                    print("🟡 Триггер 2FA перехода")
                    emailFor2FA = email
                    showTwoFA = true
                } else {
                    errorMessage = error ?? "Ошибка входа"
                }
            }
        }
    }
}
