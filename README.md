# Fridge Mate 🍎🧊

**Fridge Mate** is a modern, cross-platform mobile application designed to help households manage their food inventory efficiently and reduce food waste. Developed using the **Flutter** framework, the app provides a seamless experience on both **Android** and **iOS** from a single codebase.

## 🚀 Key Features

* [cite_start]**Smart Barcode Scanning**: Identify products using the EAN-13 barcode standard via the device camera[cite: 216, 301, 369].
* **Automated Product Data**: Integration with the **Open Food Facts REST API** to automatically retrieve product names, brands, and nutritional info.
* **Offline-First Architecture**: Uses a local **SQLite** database (`inventory.db`) to ensure data is accessible without an internet connection.
* **Expiration Tracking**: Visual alerts and dynamic banners that prioritize items based on their shelf life.
* **Modern UI/UX**: Built with **Material 3** design principles, featuring dynamic color themes and full support for Light/Dark modes.
* **Multilingual Support**: Fully localized into 6 languages using external JSON translation files.

## 🛠️ Tech Stack

* [cite_start]**Framework**: Flutter (v3.0+)[cite: 198, 480].
* [cite_start]**Language**: Dart[cite: 182, 199].
* [cite_start]**Local Database**: SQLite (via `sqflite` library)[cite: 272, 293].
* [cite_start]**API Interface**: `openfoodfacts` wrapper[cite: 296].
* **Architecture**: Separation of Concerns (Models, Services, Screens, Widgets).

## ⚙️ Installation & Setup

### Prerequisites
* [cite_start]**Flutter SDK**: Version 3.0 or newer[cite: 480].
* [cite_start]**Android Studio / Xcode**: For platform-specific compilation[cite: 482, 487].
* [cite_start]**CocoaPods**: Required for iOS builds[cite: 484].

### Step-by-Step Guide

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/TomsnCZE/FridgeMate-Flutter.git 
    cd FridgeMate-Flutter
    ```

2.  **Download dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Install iOS Pods (macOS only)**:
    ```bash
    cd ios
    pod install
    cd ..
    ```

4.  **Run the application**:
    ```bash
    flutter run
    ```

## 📱 Platform Support
* [cite_start]**Android**: Minimum SDK 26 (Android 8.0+)[cite: 488].
* **iOS**: Compatible with modern iPhones (requires Developer Mode).
