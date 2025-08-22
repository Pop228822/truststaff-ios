import SwiftUI

struct HomeView: View {
    
    @State private var showFeedbackSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Успешный вход")
                    .font(.title)
                    .bold()

                Text("Добро пожаловать в TrustStaff")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                VStack(spacing: 16) {
                    NavigationLink(destination: MyEmployeesView()) {
                        MenuButton(label: "Мои сотрудники", systemIcon: "person.3.fill")
                    }

                    NavigationLink(destination: AddEmployeeView()) {
                        MenuButton(label: "Добавить сотрудника", systemIcon: "plus.circle.fill")
                    }

                    NavigationLink(destination: SearchCandidateView()) {
                        MenuButton(label: "Проверить кандидата", systemIcon: "magnifyingglass")
                    }

                    NavigationLink(destination: MyInfoView()) {
                        MenuButton(label: "Мой аккаунт", systemIcon: "house.fill")
                    }

                    NavigationLink(destination: AddVerificationView()) {
                        MenuButton(label: "Верификация работодателя", systemIcon: "person.crop.circle")
                    }
                    Button(action: {
                        showFeedbackSheet = true
                        }) {
                       MenuButton(label: "Оставить отзыв", systemIcon: "bubble.left.fill")
                    }
                }

                Spacer()
            }
            .padding()
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showFeedbackSheet) {
                            FeedbackForm()
                        }
        }
    }
}

struct MenuButton: View {
    let label: String
    let systemIcon: String

    var body: some View {
        HStack {
            Image(systemName: systemIcon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)

            Text(label)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

