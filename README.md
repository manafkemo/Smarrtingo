# Smarttingo 🚀

Smarttingo is an AI-powered task management and productivity application built with Flutter. It features smart task breakdown, habit tracking, and a focus timer to help you achieve your goals.

## ✨ Features

- **AI Task Breakdown**: Use Google Gemini to break down complex goals into actionable steps.
- **Habit Tracking**: Build and maintain positive routines.
- **Priority Matrix**: Organize tasks using an Eisenhower-style matrix.
- **Focus Timer**: Stay productive with an integrated Pomodoro-style timer.
- **Clean UI**: A modern, responsive design with dark mode support.

## 🛠️ Setup Instructions

### 1. Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- An IDE (VS Code, Android Studio, or IntelliJ)

### 2. Environment Variables

This project uses environment variables for AI services. 

1. Create a `.env` file in the root directory.
2. Copy the contents from `.env.example` into `.env`.
3. Add your API keys:
   - **GEMINI_API_KEY**: Get it at [Google AI Studio](https://aistudio.google.com/app/apikey).

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
# To run on a connected device or emulator
flutter run
```

## 🔒 Security

All sensitive API keys and environment variables are excluded from version control via `.gitignore`. Never commit your `.env` file to public repositories.

---

For help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev/).
