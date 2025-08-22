import SwiftUI
import KeychainAccess

struct AddRecordView: View {
    let employeeID: Int

    @State private var position = ""
    @State private var hiredAt = Date()
    @State private var firedAtTemp = Date()  // используем Date вместо Date?
    @State private var misconduct = ""
    @State private var commendation = ""
    @State private var isFired: Bool = false
    @State private var isSubmitting = false
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(header: Text("Основное")) {
                TextField("Должность", text: $position)
                DatePicker("Принят", selection: $hiredAt, displayedComponents: .date)

                Toggle("Уволен", isOn: $isFired)
                if isFired {
                    DatePicker("Дата увольнения", selection: $firedAtTemp, displayedComponents: .date)
                }
            }

            Section(header: Text("Дополнительно")) {
                TextField("Нарушение", text: $misconduct)
                TextField("Похвала", text: $commendation)
            }

            Button("Сохранить") {
                submitRecord()
            }
            .disabled(isSubmitting)
        }
        .overlay {
            if isSubmitting {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Сохраняем...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
        }
        .navigationTitle("Новая запись")
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
    }
    
    func urlEncode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }

    func submitRecord() {
        isSubmitting = true

        guard let url = URL(string: "https://app.truststaff.ru/employee/\(employeeID)/add-record") else {
            isSubmitting = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let keychain = Keychain(service: "ru.truststaff.app")
        let token = (try? keychain.get("accessToken")) ?? ""
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var body = "position=\(urlEncode(position))&hired_at=\(formatter.string(from: hiredAt))"
        if isFired {
            body += "&fired_at=\(formatter.string(from: firedAtTemp))"
        }
        if !misconduct.isEmpty {
            body += "&misconduct=\(urlEncode(misconduct))"
        }
        if !commendation.isEmpty {
            body += "&commendation=\(urlEncode(commendation))"
        }

        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                dismiss()
            }
        }.resume()
    }
}
