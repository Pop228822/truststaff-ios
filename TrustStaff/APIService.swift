//
//  APIService.swift
//  TrustStaff
//
//  Created by Aram Gazaryan on 20.06.2025.
//


import Foundation
import KeychainAccess

struct APIService {
    static let baseURL = "https://app.truststaff.ru/api"

    static func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            completion(false, "Некорректный URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "email": email,
            "password": password
        ]

        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }

            guard let data = data else {
                completion(false, "Пустой ответ от сервера")
                return
            }

            // 👇 Печатаем весь ответ
            if let raw = String(data: data, encoding: .utf8) {
                print("🔵 RAW RESPONSE: \(raw)")
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let token = json["access_token"] as? String {
                    let keychain = Keychain(service: "ru.truststaff.app")
                    try? keychain.set(token, key: "accessToken")
                    try? keychain.set(email, key: "email")
                    completion(true, nil)
                    return
                }

                if let detail = json["detail"] as? String {
                    if detail.lowercased().contains("2fa") {
                        completion(false, "2fa_required")
                    } else {
                        completion(false, detail)
                    }
                    return
                }

                if let msg = json["message"] as? String {
                    completion(false, msg)
                    return
                }

                completion(false, "Неизвестный ответ сервера")
                return
            }

            completion(false, "Ошибка разбора ответа")
        }.resume()
    }
    
    static func verify2FA(email: String, code: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/verify-2fa") else {
            completion(false, "Некорректный URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "email": email,
            "code": code
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["access_token"] as? String else {
                completion(false, "Ошибка разбора ответа")
                return
            }

            let keychain = Keychain(service: "ru.truststaff.app")
            try? keychain.set(token, key: "accessToken")
            try? keychain.set(email, key: "email")

            completion(true, nil)
        }.resume()
    }
    
    static func resend2FA(email: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/resend-2fa") else {
            completion(false, "Некорректный URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? String, status == "resent" else {
                completion(false, "Ошибка при повторной отправке")
                return
            }

            completion(true, nil)
        }.resume()
    }
    
    func addEmployee(token: String, employee: EmployeeFormData, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "https://truststaff.ru/api/employees/add") else {
            completion(false, "Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let fields: [String: String] = [
            "last_name": employee.lastName,
            "first_name": employee.firstName,
            "middle_name": employee.middleName,
            "birth_date": employee.birthDate,
            "contact": employee.contact
        ]

        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(false, "Ошибка разбора ответа")
                return
            }

            if json["status"] as? String == "success" {
                completion(true, nil)
            } else {
                completion(false, json["detail"] as? String ?? "Ошибка")
            }
        }.resume()
    }
    
    static func searchCandidate(fullName: String, birthDate: Date, completion: @escaping ([EmployeeSearchResult]?, String?) -> Void) {
        guard let url = URL(string: "https://truststaff.ru/api/employees/check") else {
            completion(nil, "Некорректный URL")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let birthDateString = dateFormatter.string(from: birthDate)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = try? Keychain(service: "ru.truststaff.app").get("accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload = [
            "full_name": fullName,
            "birth_date": birthDateString
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(nil, "Ошибка формирования запроса")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }

            guard let data = data else {
                completion(nil, "Нет данных от сервера")
                return
            }

            do {
                let decoded = try JSONDecoder().decode([EmployeeSearchResult].self, from: data)
                completion(decoded, nil)
            } catch {
                print("❌ Ошибка декодирования: \(error)")
                print("📦 Ответ сервера: \(String(data: data, encoding: .utf8) ?? "nil")")
                completion(nil, "Ошибка декодирования")
            }
        }.resume()
    }
    
}
