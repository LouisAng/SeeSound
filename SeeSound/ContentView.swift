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
    @State private var canGoBack: Bool = false    // 뒤로 가기 가능 여부
    @State private var canGoForward: Bool = false // 앞으로 가기 가능 여부
    @State private var showingBookmarks: Bool = false
    @State private var bookmarks: [Bookmark] = []
    @State private var showingAddBookmark: Bool = false
    @State private var bookmarkTitle: String = ""
    
    init() {
        _urlString = State(initialValue: defaultURL)
        _currentURL = State(initialValue: URL(string: defaultURL)!)
        
        if let savedBookmarks = UserDefaults.standard.data(forKey: "bookmarks"),
           let decodedBookmarks = try? JSONDecoder().decode([Bookmark].self, from: savedBookmarks) {
            _bookmarks = State(initialValue: decodedBookmarks)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 컨트롤 영역
            if isControlVisible {
                VStack {
                    // URL 입력 영역
                    HStack {
                        // 뒤로 가기 버튼
                        Button(action: {
                            // WebView에서 구현할 메서드
                            NotificationCenter.default.post(name: .init("goBack"), object: nil)
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(canGoBack ? .blue : .gray)
                        }
                        .disabled(!canGoBack)
                        
                        // 앞으로 가기 버튼
                        Button(action: {
                            NotificationCenter.default.post(name: .init("goForward"), object: nil)
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(canGoForward ? .blue : .gray)
                        }
                        .disabled(!canGoForward)
                        
                        // 즐겨찾기 버튼 추가
                        Button(action: {
                            showingBookmarks.toggle()
                        }) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                        
                        // 즐겨찾기 추가 버튼
                        Button(action: {
                            bookmarkTitle = urlString
                            showingAddBookmark = true
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                        
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
                       scrollSpeed: scrollSpeed,
                       canGoBack: $canGoBack,
                       canGoForward: $canGoForward)
                
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
        .sheet(isPresented: $showingBookmarks) {
            BookmarkListView(bookmarks: $bookmarks, currentURL: $currentURL, showingBookmarks: $showingBookmarks)
        }
        .alert("즐겨찾기 추가", isPresented: $showingAddBookmark) {
            TextField("제목", text: $bookmarkTitle)
            Button("추가") {
                addBookmark(title: bookmarkTitle, url: urlString)
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("즐겨찾기의 제목을 입력하세요")
        }
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
    
    private func addBookmark(title: String, url: String) {
        let bookmark = Bookmark(title: title, url: url)
        bookmarks.append(bookmark)
        saveBookmarks()
    }
    
    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: "bookmarks")
        }
    }
}

#Preview {
    ContentView()
}

// 즐겨찾기 목록 뷰 추가
struct BookmarkListView: View {
    @Binding var bookmarks: [Bookmark]
    @Binding var currentURL: URL
    @Binding var showingBookmarks: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(bookmarks) { bookmark in
                    Button(action: {
                        if let url = URL(string: bookmark.url) {
                            currentURL = url
                            showingBookmarks = false
                        }
                    }) {
                        VStack(alignment: .leading) {
                            Text(bookmark.title)
                                .font(.headline)
                            Text(bookmark.url)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: deleteBookmarks)
            }
            .navigationTitle("즐겨찾기")
            .navigationBarItems(trailing: Button("닫기") {
                showingBookmarks = false
            })
        }
    }
    
    private func deleteBookmarks(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: "bookmarks")
        }
    }
}
