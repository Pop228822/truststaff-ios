import SwiftUI
import KeychainAccess
import PhotosUI

struct OrgSuggestion: Codable, Identifiable {
    var id: String { inn }  // уникальность — ИНН
    let value: String
    let inn: String
    let address: String
    let display: String
}

struct AddVerificationView: View {
    @State private var companyName = ""
    @State private var registrationAddress = ""
    @State private var inn = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var passportImageData: Data?
    @State private var isSubmitting = false
    @State private var submissionMessage = ""
    @State private var showAlert = false
    @State private var suggestions: [OrgSuggestion] = []
    @State private var showSuggestions = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Название компании / ИП")) {
                    TextField("Введите название", text: $companyName)
                        .onChange(of: companyName) { newValue in
                            if newValue.count >= 2 {
                                loadSuggestions(for: newValue) { results in
                                    DispatchQueue.main.async {
                                        suggestions = results
                                        showSuggestions = !results.isEmpty
                                    }
                                }
                            } else {
                                suggestions = []
                                showSuggestions = false
                            }
                        }

                    if showSuggestions {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(suggestions) { suggestion in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(suggestion.value)
                                            .font(.headline)
                                        Text("\(suggestion.inn) • \(suggestion.address)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(8)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        companyName = suggestion.value
                                        inn = suggestion.inn
                                        registrationAddress = suggestion.address
                                        showSuggestions = false
                                    }
                                }
                            }
                            .padding(.top, 5)
                            .padding(.bottom, 5)
                        }
                        .frame(maxHeight: 200)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: showSuggestions)
                    }
                }

                Section(header: Text("Адрес регистрации")) {
                    TextField("Введите адрес", text: $registrationAddress)
                }

                Section(header: Text("ИНН / ОГРНИП / ОГРН")) {
                    TextField("Введите номер", text: $inn)
                        .keyboardType(.numbersAndPunctuation)
                }

                Section(header: Text("Фото паспорта (1-я страница)")) {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text(passportImageData == nil ? "Выбрать файл" : "Файл выбран")
                            .foregroundColor(.blue)
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                passportImageData = data
                            }
                        }
                    }
                }

                Button(action: submitForm) {
                    Text("Отправить на проверку")
                        .frame(maxWidth: .infinity)
                }
                .disabled(isSubmitting || companyName.isEmpty || inn.isEmpty || passportImageData == nil)
                .alert(submissionMessage, isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                }
            }
            .navigationTitle("Верификация работодателя")
            .navigationBarBackButtonHidden(true) // скрыть стандартную кнопку
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
        }
    }

    func submitForm() {
        guard let url = URL(string: "https://app.truststaff.ru/api/employer/submit-verification") else { return }
        isSubmitting = true

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Поля формы
        let fields = [
            ("company_name", companyName),
            ("city", registrationAddress),
            ("inn_or_ogrn", inn)
        ]

        for (key, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        // Файл
        if let imageData = passportImageData {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"passport_file\"; filename=\"passport.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        // Авторизация
        request.setValue("Bearer \(getToken())", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        submissionMessage = "Заявка успешно отправлена"
                    } else {
                        submissionMessage = "Ошибка: \(httpResponse.statusCode)"
                    }
                } else {
                    submissionMessage = "Сервер не отвечает"
                }
                showAlert = true
            }
        }.resume()
    }
    
    func loadSuggestions(for query: String, completion: @escaping ([OrgSuggestion]) -> Void) {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://app.truststaff.ru/autocomplete/orgs?query=\(encoded)") else {
            completion([])
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("Нет данных или ошибка:", error?.localizedDescription ?? "неизвестно")
                completion([])
                return
            }

            // 👉 отладочный лог
            if let raw = String(data: data, encoding: .utf8) {
                print("Ответ сервера:", raw)
            } else {
                print("Не удалось декодировать в UTF-8")
            }

            if let json = try? JSONDecoder().decode([String: [OrgSuggestion]].self, from: data),
               let results = json["results"] {
                completion(results)
            } else {
                print("Не удалось декодировать JSON в [String: [OrgSuggestion]]")
                completion([])
            }
        }.resume()
    }

    func getToken() -> String {
        return (try? Keychain(service: "ru.truststaff.app").get("accessToken")) ?? ""
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
