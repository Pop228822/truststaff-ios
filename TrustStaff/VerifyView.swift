import SwiftUI

enum VerifyRoute: Hashable {
    case login
}

struct VerifyView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                Text("📩 Подтвердите почту")
                    .font(.title2)
                    .padding(.top)

                Text("Мы отправили письмо на ваш email. Перейдите по ссылке в письме, чтобы завершить регистрацию.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                Button("Перейти ко входу") {
                    path.append(VerifyRoute.login)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                Spacer()
            }
            .padding()
            .navigationBarBackButtonHidden(true)
            .navigationDestination(for: VerifyRoute.self) { route in
                switch route {
                case .login:
                    LoginView()
                }
            }
        }
    }
}
