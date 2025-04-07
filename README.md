# Internship Management System (CTIS IMS)

A comprehensive Flutter application designed to manage and track student internships for academic institutions. This system allows students, instructors, and administrators to handle the entire internship process in one centralized platform.

[YouTube videosunu buradan izleyin](https://youtu.be/W8yAaMPWGFY)
[![CTIS IMS](https://img.youtube.com/vi/W8yAaMPWGFY/0.jpg)](https://youtu.be/W8yAaMPWGFY)


## Table of Contents
- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Project Structure](#project-structure)
- [User Guide](#user-guide)
  - [Login](#login)
  - [Dashboard](#dashboard)
  - [Submission](#submission)
  - [Search](#search)
  - [Evaluation](#evaluation)
- [Animation Features](#animation-features)
- [Dark Mode](#dark-mode)
- [Contributors & Creators](#contributors--creators)
- [Contributing](#contributing)
- [License](#license)

## Features

- **User Authentication**: Secure login system with role-based access
- **Submission Management**: Students can upload their internship documents
- **Document Tracking**: Track submission status and deadlines
- **Evaluation Tools**: Instructors can evaluate and grade student submissions
- **Search Functionality**: Easily find student records and submissions
- **Export Data**: Export data for reporting purposes
- **Responsive Design**: Works on web, desktop, and mobile platforms
- **Dark Mode**: Toggle between light and dark themes
- **Animated UI**: Smooth animations for enhanced user experience

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (version 3.10.0 or later)
   - [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)

2. **Dart SDK** (version 3.0.0 or later, included with Flutter)

3. **Git** for cloning the repository
   - [Git Installation Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

4. **Firebase Account** for backend services
   - [Firebase Console](https://console.firebase.google.com/)

5. **IDE** (Visual Studio Code or Android Studio recommended)
   - [VS Code](https://code.visualstudio.com/)
   - [Android Studio](https://developer.android.com/studio)

### Installation

Follow these steps to get the project running on your local machine:

1. **Clone the repository**
   
   Open your terminal/command prompt and run:
   ```bash
   git clone https://github.com/username/InternshipManagementSystem.git
   ```
   
   Replace `username` with the actual GitHub username where the project is hosted.

2. **Navigate to the project directory**
   ```bash
   cd InternshipManagementSystem
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure Firebase**
   
   The app uses Firebase for authentication and data storage. You'll need to:
   
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add a web app to your Firebase project
   - Copy the Firebase configuration to `lib/firebase_keys.dart`
   - Enable Authentication (Email/Password) in the Firebase console
   - Set up Firestore database with proper security rules

5. **Run the application**
   
   For web:
   ```bash
   flutter run -d chrome
   ```
   
   For desktop:
   ```bash
   flutter run -d windows  # or macos, linux
   ```
   
   For mobile:
   ```bash
   flutter run
   ```

## Project Structure

The project follows a structured organization:

- `lib/` - Contains all Dart code for the application
  - `main.dart` - Entry point of the application
  - `login_page.dart` - User authentication screen
  - `home_page.dart` - Main navigation hub
  - `dashboard_page.dart` - Overview of internship status
  - `submission_page.dart` - For uploading and managing documents
  - `search_page.dart` - Search functionality for records
  - `evaluate_page.dart` - Instructor evaluation tools
  - `export_page.dart` - Data export functionality
  - `db_helper.dart` - Firebase database interactions
  - `themes/` - Theme configuration for light/dark mode
  - Animation-related files:
    - `animated_button.dart` - Custom animated button components
    - `animated_loader.dart` - Loading animations
    - `drag_drop_file_picker.dart` - File upload UI
    - `splash_screen.dart` - App launch screen

## User Guide

### Login

- Enter your institutional email and password
- The system automatically detects your role (student, instructor, admin)
- If you forget your password, contact your system administrator

### Dashboard

- View an overview of your submissions or student submissions
- Check deadlines and submission statuses
- Access quick links to main functions

### Submission

For students:
- Upload required documents for your internship
- Track submission statuses
- View feedback from instructors

For instructors:
- View student submissions
- Download submitted files
- Provide feedback

### Search

- Search for student records by Bilkent ID
- Filter search results by course or semester
- View detailed student internship information

### Evaluation

For instructors:
- Grade student submissions
- Upload company evaluation documents
- Add comments and feedback

## Animation Features

The system includes several animation features for enhanced user experience:

- **Splash Screen**: Animated logo and text typing effect
- **Login Page**: Fade-in animation with glowing buttons
- **File Upload**: Drag & drop area with visual feedback
- **Success Dialogs**: Animated notifications for successful actions
- **Loading Indicators**: Custom animated loaders

## Dark Mode

The application supports both light and dark themes:

- Toggle between modes using the button in the top-right corner
- Theme preference is saved for future sessions
- Carefully designed color palette for both modes to ensure readability


## Contributors & Creators

This project was developed by:

- **Hikmet Aydogan** - Frontend Developer & UI Design
  - Email: hkmtbzkrt06@gmail.com
  - GitHub: [hikmetbozkurt](https://github.com/hikmetbozkurt)

- **Bilgehan Demirkaya** - Frontend Development & Database Design
  - Email: bilgehandk@gmail.com
  - GitHub: [bilgehandk](https://github.com/bilgehandk)

- **Arman Yılmazkurt** - Backend Development & Testing
  - Email: armanyilmazkurt123@gmail.com
  - GitHub: [armankurt](https://github.com/armankurt)

Special thanks to:
- **Neşe Şahin ÖZÇELİK** - Project Supervisor
- **Bilkent University CTIS Department** - For their support and guidance

## Contributing

Contributions to the Internship Management System are welcome! Here's how you can contribute:

1. Fork the repository
2. Create a new branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some feature'`)
5. Push to the branch (`git push origin feature/your-feature`)
6. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Developed for Bilkent University CTIS Department © 2023-2024
