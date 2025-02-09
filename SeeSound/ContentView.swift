//
//  ContentView.swift
//  SeeSound
//
//  Created by Louis An on 2/5/25.
//

import SwiftUI

struct ContentView: View {
    private let defaultURL = "https://www.google.com"
    @State private var urlString: String
    @State private var currentURL: URL
    @State private var isScrolling: Bool = false
    @State private var scrollSpeed: Double = 50.0
    @State private var isControlVisible: Bool = true  // 컨트롤 영역 표시 여부
    
    init() {
        _urlString = State(initialValue: defaultURL)
        _currentURL = State(initialValue: URL(string: defaultURL)!)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 컨트롤 영역
            if isControlVisible {
                VStack {
                    // URL 입력 영역
                    HStack {
                        if #available(iOS 17.0, *) {
                            TextField("URL을 입력하세요", text: $urlString)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                                .onSubmit {
                                    loadURL()
                                }
                                .onChange(of: currentURL) { oldURL, newURL in
                                    urlString = newURL.absoluteString
                                }
                        } else {
                            TextField("URL을 입력하세요", text: $urlString)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                                .onSubmit {
                                    loadURL()
                                }
                                .onChange(of: currentURL) { newURL in
                                    urlString = newURL.absoluteString
                                }
                        }
                        
                        Button("이동") {
                            loadURL()
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    
                    // 현재 URL 표시
                    Text(currentURL.absoluteString)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .padding(.horizontal)
                    
                    // 스크롤 컨트롤
                    VStack {
                        HStack {
                            Text("스크롤 속도: \(Int(scrollSpeed))")
                            Slider(value: $scrollSpeed, in: 30...500, step: 10)
                        }
                    }
                    .padding()
                }
                .transition(.move(edge: .top))
            }
            
            // 웹뷰
            ZStack(alignment: .top) {
                WebView(url: currentURL, 
                       isScrolling: $isScrolling,
                       currentURL: $currentURL,
                       scrollSpeed: scrollSpeed)
                
                // 모든 컨트롤 버튼들을 하나의 HStack으로 묶기
                HStack(spacing: 12) {
                    // 토글 버튼
                    Button(action: {
                        withAnimation {
                            isControlVisible.toggle()
                        }
                    }) {
                        Image(systemName: isControlVisible ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    // 스크롤 시작/중지 버튼
                    Button(action: {
                        isScrolling.toggle()
                    }) {
                        Image(systemName: isScrolling ? "pause.fill" : "play.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    // 속도 감소 버튼
                    Button(action: {
                        scrollSpeed = max(30, scrollSpeed - 50)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    // 속도 증가 버튼
                    Button(action: {
                        scrollSpeed = min(500, scrollSpeed + 50)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 8)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private func loadURL() {
        var urlToLoad = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if urlToLoad.isEmpty {
            return
        }
        
        if !urlToLoad.contains("://") {
            urlToLoad = "https://" + urlToLoad
        }
        
        if let url = URL(string: urlToLoad) {
            if url.absoluteString != currentURL.absoluteString {
                currentURL = url
            }
        }
    }
}

#Preview {
    ContentView()
}
