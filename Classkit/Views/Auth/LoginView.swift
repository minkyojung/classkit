import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var selectedRole: UserRole = .teacher

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Logo
                VStack(spacing: 12) {
                    Image(systemName: "book.and.wrench.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                    Text("Classkit")
                        .font(.largeTitle.weight(.bold))
                    Text("1:1 과외 관리 앱")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)

                // Form
                VStack(spacing: 16) {
                    if isSignUp {
                        TextField("이름", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)

                        Picker("역할", selection: $selectedRole) {
                            Text("선생님").tag(UserRole.teacher)
                            Text("학생").tag(UserRole.student)
                        }
                        .pickerStyle(.segmented)
                    }

                    TextField("이메일", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    SecureField("비밀번호", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isSignUp ? .newPassword : .password)

                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await performAuth() }
                    } label: {
                        if authManager.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        } else {
                            Text(isSignUp ? "회원가입" : "로그인")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isFormValid || authManager.isLoading)
                }
                .frame(maxWidth: 360)

                // Toggle
                Button {
                    isSignUp.toggle()
                    authManager.errorMessage = nil
                } label: {
                    if isSignUp {
                        Text("이미 계정이 있으신가요? **로그인**")
                    } else {
                        Text("계정이 없으신가요? **회원가입**")
                    }
                }
                .font(.subheadline)

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }

    private var isFormValid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let isEmailValid = trimmedEmail.contains("@") && trimmedEmail.contains(".")
        let isPasswordValid = password.count >= 6
        let isNameValid = !isSignUp || !name.trimmingCharacters(in: .whitespaces).isEmpty
        return isEmailValid && isPasswordValid && isNameValid
    }

    private func performAuth() async {
        if isSignUp {
            await authManager.signUpWithEmail(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                name: name.trimmingCharacters(in: .whitespaces),
                role: selectedRole
            )
        } else {
            await authManager.signInWithEmail(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
        }
    }
}
