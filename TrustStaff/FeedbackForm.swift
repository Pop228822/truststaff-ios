import SwiftUICore
import KeychainAccess
import SwiftUI

struct FeedbackForm: View {
    @Environment(\.dismiss) var dismiss

    @State private var message = ""
    @State private var contact = ""
    @State private var errorMessage: String?
    @State private var success = false
    
    func sendFeedback(message: String, contact: String = "", completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "https://app.truststaff.ru/api/feedback") else {
            completion(false, "Некорректный URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = try? Keychain(service: "ru.truststaff.app").get("accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: String] = [
            "message": message,
            "contact": contact
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(false, "Ошибка ответа сервера")
                return
            }

            if let detail = json["detail"] as? String {
                completion(false, detail)
            } else {
                completion(true, nil)
            }
        }.resume()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Сообщение")) {
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                }

                Section(header: Text("Контакт (необязательно)")) {
                    TextField("Email или телефон", text: $contact)
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }

                if success {
                    Text("Спасибо за отзыв!")
                        .foregroundColor(.green)
                }

                Button("Отправить") {
                    sendFeedback(message: message, contact: contact) { ok, err in
                        DispatchQueue.main.async {
                            if ok {
                                success = true
                                message = ""
                                contact = ""
                                errorMessage = nil
                            } else {
                                errorMessage = err ?? "Ошибка отправки"
                            }
                        }
                    }
                }
            }
            .navigationTitle("Обратная связь")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

