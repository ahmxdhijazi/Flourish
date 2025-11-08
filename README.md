# 🌱 Flourish

Flourish is a social gardening app that helps you track, share, and celebrate your gardening journey. Connect with fellow plant enthusiasts, track your garden's growth, and learn from the community.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

## ✨ Features

- 📸 **Plant Recognition**: Take photos of your plants to identify them and track their growth
- 🌿 **Garden Management**: Keep track of all your plants and their care requirements
- 📊 **Progress Tracking**: Monitor your gardening journey with stats and achievements
- 👥 **Social Features**: Connect with other gardeners, share tips, and celebrate successes
- 🎯 **Gamification**: Earn points and unlock achievements as you grow your garden

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.9.2)
- Dart SDK (>=3.0.0)
- Firebase project setup
- iOS/Android development environment

### Installation

1. Clone the repository
```bash
git clone https://github.com/ahmxdhijazi/WeCooked-SASE2025.git
cd WeCooked-SASE2025/wecookedsase
```

2. Install dependencies
```bash
flutter pub get
```

3. Setup Firebase
- Create a new Firebase project
- Add your iOS/Android apps
- Download and add configuration files
- Enable Authentication, Firestore, and Storage

4. Run the app
```bash
flutter run
```

## 📱 App Structure

```
lib/
├── main.dart              # App entry point
├── auth.dart              # Authentication service
├── services/
│   └── user_service.dart  # User data management
├── models/               
│   └── ...               # Data models
├── pages/
│   ├── login.dart        # Login screen
│   ├── signup.dart       # Signup screen
│   └── profile.dart      # Profile screen
└── utils/
    └── ...              # Utility functions
```

## 🔐 Firebase Setup

### Firestore Structure
```
/users/{userId}/
  - displayName: string
  - profileImageUrl: string?
  - createdAt: timestamp
  - plants: number
  - gardens: number
  - daysActive: number
```

### Security Rules
Set up appropriate security rules for Firestore and Storage to protect user data while allowing necessary access.

## 🛠️ Tech Stack

- **Frontend**: Flutter & Dart
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Cloud Storage
- **UI Libraries**:
  - velocity_x
  - flutter_screenutil
  - google_fonts
  - forui

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev)
- [Firebase](https://firebase.google.com)
- All our amazing contributors!

---

<p align="center">Made with 💚 by We Cooked</p>