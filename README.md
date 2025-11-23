# 🧱 The Wall (Supabase Version)

A simple social wall Flutter app where users can register, log in, and post public messages in real time using **Supabase Authentication** and **Supabase Database**.

---

## 🚀 Features

- 🔐 **User Authentication** with Supabase (Email & Password)
- 🧱 **Public Wall** where users post messages visible to everyone
- ⚡ **Realtime Updates** using Supabase Realtime / Streams
- 📱 **Modern Flutter UI**
- 🔁 **Session Persistence** thanks to Supabase Auth

---

## 🧩 Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Supabase  
  - Supabase Auth  
  - Supabase Postgres (Database)  
  - Supabase Realtime (optional)  
- **Architecture:** Stateful Widgets & Components

---

## 📂 Folder Structure

```
lib/
 ├── main.dart                       # Supabase initialization + App root
 │
 ├── auth/
 │    ├── auth.dart                  # Listens to Supabase auth state
 │    ├── login_or_register.dart     # Switch login/register
 │    ├── login_page.dart            # Login with Supabase
 │    └── register_page.dart         # Sign up + insert into profiles table
 │
 ├── components/
 │    ├── button.dart
 │    ├── text_field.dart
 │    └── wall_post.dart             # Message UI component
 │
 └── pages/
      └── home_page.dart             # Displays messages from Supabase
```

---

## ⚙️ Setup & Installation

### 1️⃣ Prerequisites

- Flutter SDK  
- A configured **Supabase project**
- Add Supabase package:

```bash
flutter pub add supabase_flutter
```

---

### 2️⃣ Clone this repository

```bash
git clone https://github.com/ZedKaS/TheWall_Flutter.git
cd TheWall_Flutter
```

---

### 3️⃣ Initialize Supabase in `main.dart`

```dart
await Supabase.initialize(
  url: 'https://YOUR-PROJECT.supabase.co',
  anonKey: 'YOUR-ANON-KEY',
);
```

---

## 🗄️ Supabase Database Setup

### Create `profiles` table

```sql
create table profiles (
  id uuid primary key,
  email text not null,
  nom text,
  prenom text,
  username text unique,
  created timestamp default now()
);
```

### Create `posts` table

```sql
create table posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  content text not null,
  created_at timestamp default now()
);
```

Enable RLS + add proper policies in Supabase.

---

## 🧠 How Authentication Works

### 🔑 `auth.dart`
Listens to:

```dart
Supabase.instance.client.auth.onAuthStateChange
```

If user is logged in → **HomePage**  
Else → **LoginOrRegister**

---

### 🔐 `login_page.dart`

Handles login:

```dart
supabase.auth.signInWithPassword(
  email: ...,
  password: ...,
);
```

Shows dialog messages on success/error.

---

### 📝 `register_page.dart`

1. Creates user in Supabase Auth  
2. Inserts profile into table `profiles`

```dart
supabase.from('profiles').insert({...});
```

---

## 📸 Screens Overview

| Screen | Description |
|--------|--------------|
| 🔐 Login / Register | Supabase Auth |
| 🧱 HomePage | Displays posts |
| 🚪 Logout | Ends session |

---

## 🌟 Future Improvements

- Add profile pictures (Supabase Storage)  
- Likes & comments system  
- Realtime notifications  
- Dark Mode  
- Better timestamp formatting  

---

## 📝 License

This project is licensed under the MIT License — feel free to modify and share.
