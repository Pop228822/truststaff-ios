import SwiftUI
import KeychainAccess

struct AddEmployeeView: View {
    @State private var lastName = ""
    @State private var firstName = ""
    @State private var middleName = ""
    @State private var birthDate = Date()
    @State private var contact = ""

    @State private var message = ""
    @State private var showAlert = false
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // ФИО
                Section {
                    Text("Заполните данные, чтобы добавить нового сотрудника в вашу команду.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("ФИО сотрудника")) {
                    TextField("Фамилия", text: $lastName)
                        .textContentType(.familyName)
                        .autocapitalization(.words)

                    TextField("Имя", text: $firstName)
                        .textContentType(.givenName)
                        .autocapitalization(.words)

                    TextField("Отчество", text: $middleName)
                        .autocapitalization(.words)
                }

                // Доп. данные
                Section(header: Text("Дополнительная информация")) {
                    DatePicker("Дата рождения", selection: $birthDate, displayedComponents: .date)

                    TextField("Контакт: телефон или Telegram (необязательно)", text: $contact)
                        .keyboardType(.default)
                }

                // Кнопка
                Section {
                    Button {
                        addEmployee()
                    } label: {
                        Label("Добавить сотрудника", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Новый сотрудник")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Назад", systemImage: "chevron.left")
                    }
                }
            }
            .alert("Результат", isPresented: $showAlert) {
                Button("Ок", role: .cancel) { }
            } message: {
                Text(message)
            }
        }
    }

    func addEmployee() {
        guard let url = URL(string: "https://app.truststaff.ru/api/employees/add") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let token = try? Keychain(service: "ru.truststaff.app").get("accessToken")
        request.setValue("Bearer \(token ?? "")", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var body = Data()
        let fields = [
            ("last_name", lastName),
            ("first_name", firstName),
            ("middle_name", middleName),
            ("birth_date", formatter.string(from: birthDate)),
            ("contact", contact)
        ]

        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    message = "Ошибка: \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    message = "Некорректный ответ сервера"
                    showAlert = true
                    return
                }

                if httpResponse.statusCode == 200 {
                    message = "Сотрудник успешно добавлен"
                } else if let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let detail = json["detail"] as? String {
                    message = "Ошибка: \(detail)"
                } else {
                    message = "Не удалось добавить сотрудника (код: \(httpResponse.statusCode))"
                }

                showAlert = true
            }
        }.resume()
    }
}
