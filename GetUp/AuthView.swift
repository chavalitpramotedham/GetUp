import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct AuthView: View {
    @ObservedObject var taskManager: TaskManager
    @Binding var showAuthPopup: Bool
    
    @State private var isLogin = true // Toggle between login and signup
    @State private var email = ""
    @State private var password = ""
    @State private var nickname = ""
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    @State private var shouldNavigateToMainPage = false
    
    var body: some View {
        VStack(alignment:.center, spacing: 20) {
            
            Text("Add New Account")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.top,10)
                .padding(.bottom,5)
            
            // Login/Signup Toggle
            Picker("", selection: $isLogin) {
                Text("Login").tag(true)
                Text("Signup").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
//            .padding()
            
            // Email and Password Fields
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Additional Fields for Signup
            if !isLogin {
                
                Rectangle()
                    .fill(.gray.opacity(0.5))
                    .frame(width:.infinity,height: 1)
                
                
                HStack(alignment:.center,spacing:20){
                    Button(action: {
                        showImagePicker = true
                    }) {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.black, lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 2)
                        } else {
                            ZStack{
                                Circle()
                                    .fill(Color.gray.opacity(0.6))
                                    .stroke(Color.black, lineWidth: 1) // Add a black outline
                                    .frame(width: 50, height: 50)
                                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 2)
                                
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .scaleEffect(0.4)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle()) // Make the image circular
                            }
                        }
                    }
                    
                    TextField("Nickname", text: $nickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // Error Message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            NavigationLink(
                destination: MainPageView(taskManager: taskManager),
                isActive: $shouldNavigateToMainPage,
                label: { EmptyView() }
            ).hidden() // Hidden navigation link
            
//                Spacer()
            
            // Login/Signup Button
            
            Button(action: handleAuthAction) {
                if isLoading {
                    ProgressView()
                } else {
                    Text(isLogin ? "Login" : "Signup")
                        .foregroundStyle(.white)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isLoading || email.isEmpty || password.isEmpty || (!isLogin && (nickname.isEmpty || profileImage == nil)) ? Color.gray.opacity(0.5) : Color.black)
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty || (!isLogin && (nickname.isEmpty || profileImage == nil)))
            .frame(maxWidth:.infinity)
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $profileImage)
        }
        .transition(.scale) // Popup scale animation
    }
    
    // Handle Login/Signup
    private func handleAuthAction() {
        isLoading = true
        errorMessage = ""
        
        if isLogin {
            loginUser()
        } else {
            signupUser()
        }
    }
    
    // Login User
    private func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                print("Login successful for user: \(authResult?.user.uid ?? "Unknown UID")")
                
                let uid = authResult?.user.uid ?? ""
                
                if uid != "" {
                    setUID(uid)
                    shouldNavigateToMainPage = true // Navigate to MainPageView
                }
            }
        }
    }
    
    // Signup User
    private func signupUser() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                isLoading = false
                errorMessage = error.localizedDescription
                return
            }
            
            guard let uid = authResult?.user.uid else {
                isLoading = false
                errorMessage = "Unexpected error: User ID is missing."
                return
            }
            
            // Save Nickname and Profile Image
            saveUserProfile(uid: uid)
        }
    }
    
    // Save Nickname and Profile Image
    private func saveUserProfile(uid: String) {
        let storageRef = Storage.storage().reference().child("userImages/\(uid).jpg")
        
        guard let profileImage = profileImage, let imageData = profileImage.jpegData(compressionQuality: 0.8) else {
            isLoading = false
            errorMessage = "Profile image is invalid."
            return
        }
        
        // Upload Profile Image
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                isLoading = false
                errorMessage = "Error uploading image: \(error.localizedDescription)"
                return
            }
            
            // Get Image URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    isLoading = false
                    errorMessage = "Error fetching image URL: \(error.localizedDescription)"
                    return
                }
                
                guard let imageUrl = url?.absoluteString else {
                    isLoading = false
                    errorMessage = "Image URL is missing."
                    return
                }
                
                // Save Data to Firestore
                let userData: [String: Any] = [
                    "userName": nickname,
                    "userImageURL": imageUrl,
                    "email": email,
                    "userConnections": []
                ]
                
                Firestore.firestore().collection("users").document(uid).setData(userData) { error in
                    isLoading = false
                    if let error = error {
                        errorMessage = "Error saving user data: \(error.localizedDescription)"
                    } else {
                        print("User signed up successfully with UID: \(uid)")
                        setUID(uid)
                        shouldNavigateToMainPage = true // Navigate to MainPageView
                    }
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
