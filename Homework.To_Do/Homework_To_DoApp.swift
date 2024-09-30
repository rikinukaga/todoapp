import SwiftUI
import UserNotifications

@main
struct Homework_To_DoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }
}

struct User: Identifiable, Codable {
    var id = UUID()
    var email: String
    var password: String
}

class UserManager {
    static let shared = UserManager()
    private let usersKey = "registeredUsers"
    
    func saveUsers(_ users: [User]) {
        if let encodedData = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encodedData, forKey: usersKey)
        }
    }
    
    func loadUsers() -> [User] {
        if let data = UserDefaults.standard.data(forKey: usersKey),
           let users = try? JSONDecoder().decode([User].self, from: data) {
            return users
        }
        return []
    }
}

struct LoginView: View {
    @State var userMail = ""
    @State var userPassword = ""
    @Binding var isLoggedIn: Bool
    @Binding var users: [User]
    @State private var showRegistration = false
    @State private var isPasswordVisible = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .center) {
            Text("ようこそ！")
                .font(.largeTitle)
                .padding()
            
            TextField("メールアドレスを入力", text: $userMail)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .autocapitalization(.none)
            
            HStack(spacing: 5) {
                if isPasswordVisible {
                    TextField("パスワードを入力", text: $userPassword)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .autocapitalization(.none)
                } else {
                    SecureField("パスワードを入力", text: $userPassword)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .autocapitalization(.none)
                }
                
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            Button(action: {
                if !userMail.isEmpty && !userPassword.isEmpty {
                    if users.contains(where: { $0.email == userMail && $0.password == userPassword }) {
                        isLoggedIn = true
                    } else {
                        alertMessage = "メールアドレスまたはパスワードが間違っています。"
                        showAlert = true
                    }
                } else {
                    alertMessage = "メールアドレスまたはパスワードを入力してください。"
                    showAlert = true
                }
            }) {
                Text("ログインする")
            }
            .padding()
            
            Button(action: {
                showRegistration.toggle()
            }) {
                Text("新規登録")
            }
            .padding()
        }
        .navigationTitle("ログイン")
        .sheet(isPresented: $showRegistration) {
            RegistrationView(users: $users, isLoggedIn: $isLoggedIn)
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

struct RegistrationView: View {
    @Binding var users: [User]
    @Binding var isLoggedIn: Bool
    @State private var newUserEmail = ""
    @State private var newUserPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            TextField("メールアドレスを入力", text: $newUserEmail)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .autocapitalization(.none)
            
            TextField("パスワードを入力", text: $newUserPassword)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .autocapitalization(.none)
            
            Button(action: {
                if validatePassword(newUserPassword) {
                    if !newUserEmail.isEmpty {
                        let newUser = User(email: newUserEmail, password: newUserPassword)
                        users.append(newUser)
                        UserManager.shared.saveUsers(users)
                        newUserEmail = ""
                        newUserPassword = ""
                        isLoggedIn = true
                        requestNotificationPermission()
                    } else {
                        alertMessage = "メールアドレスを入力してください。"
                        showAlert = true
                    }
                } else {
                    alertMessage = "パスワードは英数字を含む6文字以上でなければなりません。"
                    showAlert = true
                }
            }) {
                Text("登録する")
            }
            .padding()
        }
        .navigationTitle("ユーザー登録")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func validatePassword(_ password: String) -> Bool {
        let regex = "^(?=.*[a-zA-Z])(?=.*\\d)[A-Za-z\\d]{6,}$"
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", regex)
        return passwordTest.evaluate(with: password)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            } else if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
    }
}

struct Task: Identifiable {
    let id = UUID()
    var name: String
    var isActive: Bool
    var timerDuration: TimeInterval? // タイマーの元の時間
    var remainingTime: TimeInterval // カウントダウンの残り時間
}

struct ContentView: View {
    @State var isLoggedIn = false
    @State private var users: [User] = UserManager.shared.loadUsers()
    @State var inputText = ""
    @State private var tasks: [Task] = []
    @State private var timerHours: Int = 0 // 時間
    @State private var timerMinutes: Int = 0 // 分
    @State private var timerSeconds: Int = 0 // 秒
    @State private var showTimerPicker = false
    @State private var showTaskAddedAlert = false
    @State private var taskAddedMessage = "タスクを追加しました！"
    
    var body: some View {
        NavigationStack {
            if isLoggedIn {
                VStack {
                    Spacer()
                    
                    TextField("今日やることを追加", text: $inputText)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                    
                    Button(action: {
                        showTimerPicker.toggle()
                    }) {
                        Text("タイマー時間を設定")
                    }
                    .padding()
                    
                    if showTimerPicker {
                        HStack {
                            Picker("時間", selection: $timerHours) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text("\(hour)時間").tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                            
                            Picker("分", selection: $timerMinutes) {
                                ForEach(0..<60, id: \.self) { minute in
                                    Text("\(minute)分").tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                            
                            Picker("秒", selection: $timerSeconds) {
                                ForEach(0..<60, id: \.self) { second in
                                    Text("\(second)秒").tag(second)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                        }
                        .padding()
                    }
                    
                    Button(action: {
                        let totalDuration = TimeInterval(timerHours * 3600 + timerMinutes * 60 + timerSeconds)
                        if !inputText.isEmpty && totalDuration > 0 {
                            let newTask = Task(name: inputText, isActive: true, timerDuration: totalDuration, remainingTime: totalDuration)
                            tasks.append(newTask)
                            startTimerForTask(at: tasks.count - 1)
                            inputText = ""
                            timerHours = 0
                            timerMinutes = 0
                            timerSeconds = 0
                            taskAddedMessage = "タスクを追加しました！"
                        } else {
                            taskAddedMessage = "有効なタスク名と時間を入力してください。"
                        }
                        showTaskAddedAlert = true
                    }) {
                        Text("タスクを追加")
                    }
                    .alert(isPresented: $showTaskAddedAlert) {
                        Alert(title: Text(taskAddedMessage))
                    }
                    .padding()
                    
                    NavigationLink(destination: TaskListView(tasks: $tasks)) {
                        Text("タスク一覧を見る")
                    }
                    .padding()
                    
                    Spacer()
                }
                .navigationTitle("やることリスト")
            } else {
                LoginView(isLoggedIn: $isLoggedIn, users: $users)
            }
        }
    }
    
    func startTimerForTask(at index: Int) {
        guard tasks.indices.contains(index) else { return }
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if tasks[index].remainingTime > 0 {
                tasks[index].remainingTime -= 1
            } else {
                tasks[index].isActive = false
                timer.invalidate()
                triggerNotification(for: tasks[index])
            }
        }
    }
    
    func triggerNotification(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "タイマー終了"
        content.body = "\(task.name)のタイマーが終了しました！"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知エラー: \(error)")
            }
        }
    }
}

struct TaskListView: View {
    @Binding var tasks: [Task]
    
    var body: some View {
        List {
            ForEach(tasks.indices, id: \.self) { index in
                HStack {
                    VStack(alignment: .leading) {
                        Text(tasks[index].name)
                            .font(.headline)
                        if let duration = tasks[index].timerDuration {
                            Text("タイマー: \(formattedTime(from: tasks[index].remainingTime))")
                                .font(.subheadline)
                        }
                    }
                    Spacer()
                    Toggle(isOn: $tasks[index].isActive) {
                        Text("")
                    }
                    .labelsHidden()
                }
            }
            .onDelete(perform: deleteTask)
        }
        .navigationTitle("タスク一覧")
        .toolbar {
            EditButton()
        }
    }
    
    func formattedTime(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
}

