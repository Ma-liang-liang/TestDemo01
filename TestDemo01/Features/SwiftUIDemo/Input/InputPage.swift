//
//  InputPage.swift
//  TestDemo
//
//  Created by 马亮亮 on 2025/7/7.
//

import SwiftUI

struct InputPage: View {
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var searchText = ""
    @State private var multilineText = ""
    @State private var notes = ""
    @State private var showPassword = false
    @State private var verificationCode = ""
    @State private var priceText = ""
    @State private var amount = ""
    @State private var websiteURL = ""
    @State private var showDatePicker = false
    @State private var selectedDate = ""
    @State private var selectedFileName = ""
    @State private var voiceText = ""
    @State private var isRecording = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - 基础输入框
                    Section("基础输入框") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("用户名")
                                .font(.headline)
                            TextField("请输入用户名", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // MARK: - 密码输入框
                    Section("密码输入框") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("密码")
                                .font(.headline)
                            SecureField("请输入密码", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // MARK: - 带验证的邮箱输入框
                    Section("邮箱输入框") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("邮箱地址")
                                .font(.headline)
                            TextField("example@email.com", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            if !email.isEmpty && !isValidEmail(email) {
                                Text("请输入有效的邮箱地址")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // MARK: - 数字输入框
                    Section("手机号码输入框") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("手机号码")
                                .font(.headline)
                            TextField("请输入手机号码", text: $phoneNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                                .onChange(of: phoneNumber) { newValue in
                                    // 限制只能输入数字
                                    phoneNumber = newValue.filter { $0.isNumber }
                                    // 限制长度
                                    if phoneNumber.count > 11 {
                                        phoneNumber = String(phoneNumber.prefix(11))
                                    }
                                }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // MARK: - 搜索框
                    Section("搜索框") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("搜索")
                                .font(.headline)
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("搜索内容...", text: $searchText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // MARK: - 左侧图标输入框
                    Section("左侧图标输入框") {
                        VStack(spacing: 15) {
                            // 用户名输入框
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                TextField("用户名", text: $username)
                                    .textFieldStyle(PlainTextFieldStyle())
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            // 邮箱输入框
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                TextField("邮箱地址", text: $email)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            // 电话输入框
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 20)
                                TextField("电话号码", text: $phoneNumber)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.phonePad)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // MARK: - 右侧按钮输入框
                    Section("右侧按钮输入框") {
                        VStack(spacing: 15) {
                            // 密码输入框（显示/隐藏）
                            HStack {
                                if showPassword {
                                    TextField("密码", text: $password)
                                        .textFieldStyle(PlainTextFieldStyle())
                                } else {
                                    SecureField("密码", text: $password)
                                        .textFieldStyle(PlainTextFieldStyle())
                                }
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            // 验证码输入框
                            HStack {
                                TextField("验证码", text: $verificationCode)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.numberPad)
                                
                                Button(action: {
                                    // 发送验证码逻辑
                                    print("发送验证码")
                                }) {
                                    Text("发送验证码")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            // 价格输入框
                            HStack {
                                TextField("输入价格", text: $priceText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                
                                Text("¥")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // MARK: - 左右都有元素的输入框
                    Section("左右都有元素的输入框") {
                        VStack(spacing: 15) {
                            // 货币输入框
                            HStack {
                                Text("$")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                TextField("0.00", text: $amount)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                
                                Text("USD")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            // 搜索框（左侧图标，右侧清除和筛选）
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                
                                TextField("搜索商品...", text: $searchText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(Color.pink)
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Button(action: {
                                    // 打开筛选
                                    print("打开筛选")
                                }) {
                                    Image(systemName: "line.horizontal.3.decrease.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            // 网址输入框
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                
                                TextField("https://", text: $websiteURL)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                
                                Button(action: {
                                    // 打开网址
                                    print("打开网址: \(websiteURL)")
                                }) {
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.blue)
                                }
                                .disabled(websiteURL.isEmpty)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // MARK: - 可点击的输入框按钮
                    Section("可点击的输入框按钮") {
                        VStack(spacing: 15) {
                            // 日期选择器
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.red)
                                
                                Button(action: {
                                    showDatePicker.toggle()
                                }) {
                                    HStack {
                                        Text(selectedDate.isEmpty ? "选择日期" : selectedDate)
                                            .foregroundColor(selectedDate.isEmpty ? .gray : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            // 文件上传
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.blue)
                                
                                Button(action: {
                                    // 选择文件
                                    print("选择文件")
                                }) {
                                    HStack {
                                        Text(selectedFileName.isEmpty ? "选择文件" : selectedFileName)
                                            .foregroundColor(selectedFileName.isEmpty ? .gray : .primary)
                                        Spacer()
                                        Image(systemName: "folder")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                            // 语音输入
                            HStack {
                                TextField("说点什么...", text: $voiceText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                
                                Button(action: {
                                    // 开始语音识别
                                    isRecording.toggle()
                                    print(isRecording ? "开始录音" : "停止录音")
                                }) {
                                    Image(systemName: isRecording ? "mic.fill" : "mic")
                                        .foregroundColor(isRecording ? .red : .blue)
                                        .font(.title2)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isRecording ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // MARK: - 多行文本输入框 (iOS 14+)
                    Section("多行文本输入框") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("详细描述")
                                .font(.headline)
                            TextEditor(text: $multilineText)
                                .frame(minHeight: 100)
                                .padding(4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                            
                            Text("字数统计: \(multilineText.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // MARK: - 自定义样式的多行输入框
                    Section("自定义多行输入框") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("备注")
                                .font(.headline)
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $notes)
                                    .frame(minHeight: 120)
                                    .padding(8)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(notes.isEmpty ? Color.gray.opacity(0.3) : Color.blue, lineWidth: 2)
                                    )
                                
                                if notes.isEmpty {
                                    Text("请输入备注信息...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                            
                            HStack {
                                Spacer()
                                Text("\(notes.count)/500")
                                    .font(.caption)
                                    .foregroundColor(notes.count > 500 ? .red : .gray)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // MARK: - 表单组合示例
                    Section("表单组合示例") {
                        VStack(spacing: 15) {
                            Group {
                                HStack {
                                    Text("姓名")
                                        .frame(width: 60, alignment: .leading)
                                    TextField("请输入姓名", text: $username)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                HStack {
                                    Text("邮箱")
                                        .frame(width: 60, alignment: .leading)
                                    TextField("请输入邮箱", text: $email)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                }
                                
                                HStack(alignment: .top) {
                                    Text("备注")
                                        .frame(width: 60, alignment: .leading)
                                        .padding(.top, 8)
                                    TextEditor(text: $notes)
                                        .frame(height: 80)
                                        .padding(4)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        )
                                }
                            }
                            
                            Button(action: {
                                // 处理提交逻辑
                                print("表单提交")
                            }) {
                                Text("提交")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("输入框示例")
        }
    }
    
    // MARK: - 辅助方法
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        InputPage()
    }
}
