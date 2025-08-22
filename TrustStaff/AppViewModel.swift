import Foundation
import KeychainAccess

@MainActor
class AppViewModel: ObservableObject {
    @Published var isAuthenticated = false

    func checkToken() {
        let keychain = Keychain(service: "ru.truststaff.app")
        
        do {
            if let rawToken = try keychain.get("accessToken"), !rawToken.isEmpty {
                print("🟢 Токен найден: \(rawToken)")
                isAuthenticated = true
            } else {
                print("🔴 Токен отсутствует или пустой")
                isAuthenticated = false
            }
        } catch {
            print("❌ Ошибка при чтении токена: \(error.localizedDescription)")
            isAuthenticated = false
        }
    }

    func logout() {
        let keychain = Keychain(service: "ru.truststaff.app")
        try? keychain.remove("accessToken")
        try? keychain.remove("email")
        isAuthenticated = false
    }
}
