import SwiftUI
import KeychainAccess

struct MyEmployeesView: View {
    @State private var employees: [EmployeeResponse] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var deletingRecordID: Int?
    @State private var isDeleting = false
    
    @Environment(\.dismiss) private var dismiss
    

    var body: some View {
            Group {
                if isLoading {
                    ProgressView("Загрузка сотрудников...")
                } else if let errorMessage = errorMessage {
                    Text("Ошибка: \(errorMessage)").foregroundColor(.red)
                } else if employees.isEmpty {
                    Text("Список сотрудников пуст")
                        .foregroundColor(.gray)
                } else {
                    List(employees) { employee in
                        Section {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(employee.full_name).font(.headline)
                                Text("Дата рождения: \(employee.birth_date)").font(.subheadline)

                                if let contact = employee.contact, !contact.isEmpty {
                                    Text("Контакт: \(contact)").font(.subheadline)
                                }

                                Text("🔎 Записей: \(employee.record_count)")
                                    .font(.footnote).foregroundColor(.gray)

                                ForEach(employee.records, id: \.id) { r in
                                    VStack(alignment: .leading, spacing: 2) {
                                        if let p = r.position     { Text("📌 Должность: \(p)") }
                                        if let h = r.hired_at     { Text("🟢 Принят: \(h)") }
                                        if let f = r.fired_at     { Text("🔴 Уволен: \(f)") }
                                        if let m = r.misconduct   { Text("⚠ Нарушение: \(m)").foregroundColor(.red) }
                                        if let c = r.commendation { Text("👍 Похвала: \(c)").foregroundColor(.green) }

                                        Button(role: .destructive) {
                                            deletingRecordID = r.id
                                            Task {
                                                await performDelete(recordID: r.id)
                                            }
                                        } label: {
                                            Label("Удалить запись", systemImage: "trash")
                                        }
                                    }
                                    .padding(6)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(6)
                                }
                            }

                            // 🔹 Переходы отдельно, без HStack
                            NavigationLink(destination: AddRecordView(employeeID: employee.id)) {
                                Label("➕ Добавить запись", systemImage: "plus")
                            }

                            NavigationLink(destination: GenerateConsentView(employee: employee)) {
                                Label("📄 Согласие", systemImage: "doc")
                            }

                        } header: {
                            Text("🧑‍💼 \(employee.full_name)")
                        }
                    }
                }
            }
            .navigationTitle("Мои сотрудники")
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
            .onAppear(perform: loadEmployees)
    }
    
    @MainActor
    func performDelete(recordID: Int) async {
        guard !isDeleting else {
            print("⛔️ Уже в процессе удаления")
            return
        }

        isDeleting = true
        print("🟢 Начинаем удаление ID:", recordID)

        await deleteRecord(recordID: recordID)

        isDeleting = false
        deletingRecordID = nil
    }

    func loadEmployees() {
        guard let url = URL(string: "https://app.truststaff.ru/api/employees/") else {
            errorMessage = "Неверный URL"
            isLoading = false
            return
        }

        let keychain = Keychain(service: "ru.truststaff.app")
        let token = (try? keychain.get("accessToken")) ?? ""

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let data = data else {
                    errorMessage = "Нет данных"
                    return
                }

                do {
                    print("👀 RAW:", String(data: data, encoding: .utf8) ?? "N/A")
                    employees = try JSONDecoder().decode([EmployeeResponse].self, from: data)
                } catch {
                    errorMessage = "Ошибка разбора данных: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func deleteRecord(recordID: Int) async {
        print("🚀 deleteRecord вызван для ID:", recordID)
        guard let url = URL(string: "https://app.truststaff.ru/api/records/\(recordID)/delete") else {
            errorMessage = "Неверный URL"
            return
        }

        let keychain = Keychain(service: "ru.truststaff.app")
        let token = (try? keychain.get("accessToken")) ?? ""

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Некорректный ответ от сервера"
                return
            }

            if httpResponse.statusCode == 200 {
                for i in employees.indices {
                    if let index = employees[i].records.firstIndex(where: { $0.id == recordID }) {
                        employees[i].records.remove(at: index)
                        break
                    }
                }
            } else {
                let msg = String(data: data, encoding: .utf8) ?? "Ошибка"
                errorMessage = "Не удалось удалить: \(msg)"
            }

        } catch {
            errorMessage = "Ошибка удаления: \(error.localizedDescription)"
        }

        deletingRecordID = nil
    }
}
