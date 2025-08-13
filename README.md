# Flutter Login + Home App (BLoC State Management)

## 📱 Overview
This Flutter application has two main screens:
1. **Login Screen** – Validates user email and password before allowing login.
2. **Home Screen** – Fetches and displays 10 random images from [Picsum](https://picsum.photos/) using an API.

The project uses **BLoC (Business Logic Component)** for state management, ensuring clean separation of UI and business logic.

## 🖼 Screenshots

### Login Screen
![Login Screen](https://github.com/MojeshReddy/flutter-application/blob/main/images/1000150548.png)

### Home Screen
![Home Screen](https://github.com/MojeshReddy/flutter-application/blob/main/images/1000150548.png)



---

## 🎯 Features

### 1. Login Screen
- **Email Validation** – Checks for proper email format.
- **Password Validation** – Minimum 8 characters, at least:
  - One uppercase letter
  - One lowercase letter
  - One number
  - One special symbol
- **Navigation** – On successful login, navigates to Home Screen.

### 2. Home Screen
- Fetches 10 images from the **Picsum API**:  
  `https://picsum.photos/v2/list?page=1&limit=10`
- Displays images in a vertical list with:
  - Full screen width
  - Auto height based on aspect ratio
  - Title (Montserrat Semi-Bold)
  - Description (Montserrat Regular, dark grey, max 2 lines)

---

## 🛠 Tech Stack
- **Flutter** (Dart)
- **BLoC** – [`flutter_bloc`](https://pub.dev/packages/flutter_bloc)
- **HTTP package** for API calls
- **Google Fonts** for custom typography

---
📥 Download APK
You can download and install the latest APK here
https://drive.google.com/file/d/1MwsRuT5lmL7AkGUxA6r7Vci8VKmQkquK/view?usp=sharing
---

## 🚀 How to Run Locally

### Prerequisites
- Flutter SDK installed → [Install Flutter](https://flutter.dev/docs/get-started/install)
- Android Studio / SDK or physical Android device with USB debugging enabled

### Steps
```bash
# 1. Clone this repository
git clone https://github.com/MojeshReddy/flutter-application.git
cd flutter-application

# 2. Install dependencies
flutter pub get

# 3. Run on connected device
flutter run
