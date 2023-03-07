//
//  ContentView.swift
//  API Calling
//
//  Created by Chris Markiewicz on 2/24/23.
//

import SwiftUI

struct ContentView: View {
    @State private var images = [UIImage]()
    @State private var showingAlert = false
    @State private var currentImage: UIImage?
    @State private var isLoading = false
    var body: some View {
        NavigationView {
            VStack {
                Text("Dog Images")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.7))
                if let currentImage = currentImage {
                    ZStack {
                       Image(uiImage: currentImage)
                                    .resizable()
                                    .scaledToFill()
                       VisualEffectView(effect: UIBlurEffect(style: .light))
                            .edgesIgnoringSafeArea(.all)
                        Image(uiImage: currentImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .onTapGesture {
                                if let currentIndex = images.firstIndex(of: currentImage), currentIndex + 1 < images.count {
                                    self.currentImage = images[currentIndex + 1]
                                } else {
                                    self.currentImage = images.first!
                                }
                            }
                    }
                    .background(Color.clear)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .opacity(isLoading ? 1 : 0) // show ProgressView only when isLoading is true
                }
            }
        }
        .navigationTitle("Dog Images")
        .onChange(of: images) { newImages in
            if let firstImage = newImages.first {
                self.currentImage = firstImage
            }
        }
        .task {
            isLoading = true // set isLoading to true at the beginning of the task
            do {
                await loadData()
                isLoading = false // set isLoading to false after images array has been filled
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Loading Error"),
                  message: Text("There was problem loading the Dog Images"),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    func loadData() async {
        let query = "https://dog.ceo/api/breeds/image/random/10"
        if let url = URL(string: query) {
            if let (data, _) = try? await URLSession.shared.data(from: url) {
                if let decodedResponse = try? JSONDecoder().decode(Images.self, from: data) {
                    let urls = decodedResponse.message
                    for url in urls {
                        fetchImage(url: url)
                    }
                    return
                }
            }
        }
        showingAlert = true
    }
    
    func fetchImage(url: String) {
        guard let url = URL(string: url) else {
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                if let index = images.firstIndex(of: UIImage(data: data)!) {
                    images[index] = UIImage(data: data)!
                    print("Replacing image at index \(index)")
                } else {
                    images.append(UIImage(data: data)!)
                    print("Appending new image")
                }
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Images: Identifiable, Codable {
    var id = UUID()
    var message: [String]
    
    enum CodingKeys: String, CodingKey{
        case message
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

