import SwiftUI
import KeychainAccess

struct GenerateConsentView: View {
    let employee: EmployeeResponse

    @Environment(\.dismiss) private var dismiss

    @State private var companyName: String = ""
    @State private var inn: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var pdfURL: URL?

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

    var body: some View {
        VStack(spacing: 20) {
            Text("Генерация согласия")
                .font(.title2).bold()

            Group {
                row("👤 Сотрудник", employee.full_name)
                row("📅 Дата рождения", employee.birth_date)
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🏢 Название компании").font(.caption).foregroundColor(.gray)
                        TextField("", text: $companyName)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("🆔 ИНН").font(.caption).foregroundColor(.gray)
                        TextField("", text: $inn)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    }
                }
            }

            if isLoading {
                ProgressView()
            }

            if let errorMessage {
                Text("Ошибка: \(errorMessage)").foregroundColor(.red)
            }

            Button("📄 Скачать PDF") {
                Task { await generatePDF() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            if let url = pdfURL {
                ShareLink("🔗 Поделиться PDF", item: url)
            }

            Spacer()
        }
        .padding()
        .task {
            await loadMeData()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Назад") {
                    dismiss()
                }
            }
        }
    }

    func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundColor(.gray)
        }
    }

    func loadMeData() async {
        guard let token = try? Keychain(service: "ru.truststaff.app").get("accessToken") else {
            errorMessage = "Нет токена"
            return
        }

        guard let url = URL(string: "https://app.truststaff.ru/api/me") else {
            errorMessage = "Неверный URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Ошибка при получении профиля"
                return
            }

            let me = try JSONDecoder().decode(MeResponse.self, from: data)
            companyName = me.company_name ?? ""
            inn = me.inn_or_ogrn ?? ""

        } catch {
            errorMessage = "Ошибка загрузки данных: \(error.localizedDescription)"
        }
    }

    func generatePDF() async {
        isLoading = true
        defer { isLoading = false }

        guard let token = try? Keychain(service: "ru.truststaff.app").get("accessToken") else {
            errorMessage = "Токен не найден"
            return
        }

        guard let url = URL(string: "https://app.truststaff.ru/api/employees/\(employee.id)/generate-consent") else {
            errorMessage = "Неверный URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params = [
            "employer_company_name": companyName,
            "employer_inn": inn
        ]

        let body = params.map {
            "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }.joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Ошибка сервера"
                return
            }

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("consent_\(employee.id).pdf")

            try data.write(to: tempURL)
            pdfURL = tempURL

        } catch {
            errorMessage = "Не удалось загрузить PDF: \(error.localizedDescription)"
        }
    }
}
