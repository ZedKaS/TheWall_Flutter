# 🧱 The Wall

A simple social wall Flutter app where users can register, log in, and post public messages that appear in real-time using **Firebase Authentication** and **Cloud Firestore**.

---

## 🚀 Features

- 🔐 **User Authentication** with Firebase (Email & Password)
- 🧱 **Public Wall** where users can post messages visible to everyone
- ⚡ **Realtime Updates** using Firestore Streams
- 📱 **Responsive UI** built with Flutter & Material Design
- 🔁 **Persistent Login** with Firebase `authStateChanges()`

---

## 🧩 Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase
  - Firebase Authentication
  - Cloud Firestore
- **Architecture:** Stateful widgets & component-based UI

---

## 📂 Folder Structure

```
lib/
 ├── main.dart
 ├── firebase_options.dart          # Firebase configuration (auto-generated)
 │
 ├── auth/
 │    ├── auth.dart                 # Auth state listener (switches between login/register & home)
 │    ├── login_or_register.dart    # Wrapper for switching login/register screens
 │    ├── login_page.dart           # User sign-in page
 │    └── register_page.dart        # User sign-up page
 │
 ├── components/
 │    ├── button.dart               # Custom reusable button widget
 │    ├── text_field.dart           # Custom text field widget
 │    └── wall_post.dart            # UI component for displaying a post
 │
 └── pages/
      └── home_page.dart            # Main wall page (Firestore stream + posting)
```

---

## ⚙️ Setup & Installation

### 1️⃣ Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- A configured [Firebase project](https://console.firebase.google.com/)

### 2️⃣ Clone this repository

```bash
git clone https://github.com/ZedKaS/Projet_Flutter_Wall.git
cd thewall
```

### 3️⃣ Install dependencies

```bash
flutter pub get
```

### 4️⃣ Configure Firebase

Run the FlutterFire CLI to connect your Firebase project:

```bash
flutterfire configure
```

This generates `lib/firebase_options.dart`.

### 5️⃣ Run the app

```bash
flutter run
```

---

## 🔥 Firebase Setup Summary

In your Firebase Console:
1. Create a new project (e.g., **walltutorial**).
2. Enable **Authentication → Email/Password**.
3. Create a **Cloud Firestore** database (in *test mode* for development).
4. Run the app — a `User Posts` collection will be created automatically when users post messages.

---

## 🧠 How It Works

- **AuthPage (`auth.dart`)** listens to Firebase Auth state.  
  If a user is logged in → show `HomePage`, otherwise → show `LoginOrRegister`.

- **HomePage** streams posts from Firestore:
  ```dart
  FirebaseFirestore.instance
      .collection("User Posts")
      .orderBy("TimeStamp", descending: false)
      .snapshots();
  ```

- **LoginPage / RegisterPage** handle user authentication via:
  ```dart
  FirebaseAuth.instance.signInWithEmailAndPassword(...)
  FirebaseAuth.instance.createUserWithEmailAndPassword(...)
  ```

- **WallPost** displays each post (message + user email).

---

## 📸 Screens Overview

| Screen | Description |
|--------|--------------|
| 🔐 Login / Register | Firebase Auth (Email/Password) |
| 🧱 HomePage | Displays real-time user posts from Firestore |
| 🚪 Logout | Signs out and returns to Auth screen |

---

## 🌟 Future Improvements

- 🖼 Add profile pictures using Firebase Storage  
- ❤️ Allow likes & comments  
- 📱 Add dark mode toggle  
- 💬 Format timestamps as “2 minutes ago”  

---

---

## 📝 License

This project is licensed under the MIT License — feel free to modify and share.
