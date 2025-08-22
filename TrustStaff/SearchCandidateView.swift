import SwiftUI
import Foundation
import KeychainAccess

struct SearchCandidateView: View {
    @State private var fullName = ""
    @State private var birthDate: Date? = nil
    @State private var showDatePicker = false
    @State private var results: [EmployeeSearchResult] = []
    @State private var errorMessage: String?
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Заголовок
            VStack(spacing: 4) {
                Text("Проверка кандидата")
                    .font(.title2.bold())
                Text("Введите данные для поиска")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // Поля ввода
            VStack(spacing: 12) {
                TextField("ФИО", text: $fullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Toggle("Указать дату рождения", isOn: $showDatePicker)

                if showDatePicker {
                    DatePicker("Дата рождения", selection: Binding(
                        get: { birthDate ?? Date() },
                        set: { birthDate = $0 }
                    ), displayedComponents: .date)
                }

                Button(action: search) {
                    Text("🔍 Проверить")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
            }

            // Сообщения об ошибках или статус
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else if results.isEmpty && !fullName.isEmpty {
                Text("Совпадений не найдено")
                    .foregroundColor(.secondary)
            }

            // Результаты
            if !results.isEmpty {
                List {
                    ForEach(results) { emp in
                        Section(header: Text(emp.full_name).bold()) {
                            if let records = emp.records, !records.isEmpty {
                                ForEach(records.indices, id: \.self) { i in
                                    let r = records[i]
                                    VStack(alignment: .leading, spacing: 6) {
                                        if let p = r.position { Text("📌 Должность: \(p)") }
                                        if let h = r.hired_at { Text("🗓 Принят: \(h)") }
                                        if let f = r.fired_at { Text("→ Уволен: \(f)") }
                                        if let m = r.misconduct { Text("⚠ Нарушение: \(m)") }
                                        if let c = r.commendation { Text("👍 Похвала: \(c)") }
                                    }
                                    .padding(.vertical, 4)
                                }
                            } else {
                                Text("Нет записей")
                                    .font(.callout)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Label("Назад", systemImage: "chevron.left")
                }
            }
        }
    }

    func search() {
        guard let url = URL(string: "https://app.truststaff.ru/api/employees/check") else {
            errorMessage = "Неверный URL"
            return
        }

        var jsonPayload: [String: String] = ["full_name": fullName]

        if let birthDate = birthDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            jsonPayload["birth_date"] = formatter.string(from: birthDate)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = try? Keychain(service: "ru.truststaff.app").get("accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonPayload)
        } catch {
            errorMessage = "Ошибка сериализации JSON"
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.results = []
                    return
                }

                guard let data = data else {
                    self.errorMessage = "Нет данных от сервера"
                    self.results = []
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode([EmployeeSearchResult].self, from: data)
                    self.results = decoded
                    self.errorMessage = nil
                } catch {
                    print("Raw response: \(String(data: data, encoding: .utf8) ?? "N/A")")
                    self.errorMessage = "Ошибка декодирования"
                    self.results = []
                }
            }
        }.resume()
    }
}
