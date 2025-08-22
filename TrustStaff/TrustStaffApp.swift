import SwiftUI

@main
struct TrustStaffApp: App {
    @StateObject var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if viewModel.isAuthenticated {
                    HomeView()
                } else {
                    LoginView()
                }
            }
            .onAppear {
                viewModel.checkToken()
            }
            .environmentObject(viewModel)
        }
    }
}
