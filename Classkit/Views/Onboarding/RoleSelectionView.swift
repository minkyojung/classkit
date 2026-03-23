import SwiftUI

struct RoleSelectionView: View {
    var onSelect: (AppRole) -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "book.and.wrench.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
                Text("Classkit")
                    .font(.largeTitle.bold())
                Text("어떤 모드로 사용하시겠어요?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                RoleCard(
                    icon: "person.fill.checkmark",
                    title: "교사",
                    description: "수업 관리, 과제 출제,\n첨삭 및 성적 관리",
                    color: .blue
                ) {
                    onSelect(.teacher)
                }

                RoleCard(
                    icon: "graduationcap.fill",
                    title: "학생",
                    description: "과제 확인, 숙제 제출,\n첨삭 결과 및 성적 확인",
                    color: .green
                ) {
                    onSelect(.student)
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            Text("나중에 Supabase 연동 시 자동 로그인으로 전환됩니다")
                .font(.caption)
                .foregroundStyle(.quaternary)
                .padding(.bottom, 20)
        }
    }
}

private struct RoleCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                Circle()
                    .fill(color.gradient)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: icon)
                            .font(.title)
                            .foregroundStyle(.white)
                    }

                VStack(spacing: 6) {
                    Text(title)
                        .font(.title2.bold())
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(color.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
