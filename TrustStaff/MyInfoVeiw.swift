import SwiftUI
import KeychainAccess

struct MeResponse: Decodable {
    let id: Int
    let name: String
    let email: String
    let is_approved: Bool?
    let company_name: String?
    let city: String?
    let inn_or_ogrn: String?
    let verification_status: String
    let passport_filename: String?
    let employee_count: Int
}

struct MyInfoView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var me: MeResponse?
    @State private var shouldRedirect = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Мой аккаунт")
                .font(.title).bold()

            if let me {
                Group {
                    row(label: "👤 Имя", value: me.name)
                    row(label: "📧 Почта", value: me.email)
                    row(label: "🏢 Компания", value: me.company_name ?? "—")
                    row(label: "📍 Город", value: me.city ?? "—")
                    row(label: "🆔 ИНН/ОГРН", value: me.inn_or_ogrn ?? "—")
                    row(label: "✅ Верификация", value: me.verification_status.capitalized, color: (me.is_approved ?? false) ? .green : .orange)
                    row(label: "👥 Сотрудников", value: "\(me.employee_count)")
                }
            } else if isLoading {
                ProgressView("Загрузка...")
            } else {
                Text("Не удалось загрузить данные")
                    .foregroundColor(.red)
            }

            Button("Выйти из аккаунта") {
                appViewModel.logout()
                shouldRedirect = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Назад")
                    }
                }
            }
        }
        .onAppear {
            Task { await fetchMe() }
        }
        .navigationDestination(isPresented: $shouldRedirect) {
            LoginView()
                .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - UI Row
    func row(label: String, value: String, color: Color = .gray) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(color)
        }
        .padding(.horizontal)
    }

    // MARK: - API
    func fetchMe() async {
        isLoading = true
        defer { isLoading = false }

        guard
            let token = (try? Keychain(service: "ru.truststaff.app").get("accessToken")) ?? nil,
            let url = URL(string: "https://app.truststaff.ru/api/me")
        else {
            print("❌ Не найден токен или неверный URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("❌ Неверный статус-код: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return
            }
            
            if httpResponse.statusCode == 401 {
                print("🔒 Неавторизован — токен просрочен?")
                appViewModel.logout()
                shouldRedirect = true
                return
            }

            do {
                let decoded = try JSONDecoder().decode(MeResponse.self, from: data)
                DispatchQueue.main.async {
                    self.me = decoded
                }
            } catch {
                print("❌ Ошибка декодирования:", error)
                print("Ответ сервера:")
                print(String(data: data, encoding: .utf8) ?? "Невозможно декодировать")
            }

        } catch {
            print("❌ Ошибка запроса:", error)
        }
    }
}
