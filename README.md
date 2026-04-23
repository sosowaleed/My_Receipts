# My Receipts

![My Receipts App Banner](https://via.placeholder.com/1280x400.png/673AB7/FFFFFF?text=My+Receipts+App)

**My Receipts** is a clean, modern, and powerful personal finance tracker built with Flutter. It's designed for simplicity and privacy, storing all your financial data locally on your device using SQLite. This cross-platform application helps you manage your income and expenses with ease, providing insightful analysis and powerful "what-if" simulation tools to forecast your financial future.

---

## ✨ Features

*   **Multi-Profile Management**: Create separate profiles to manage finances for personal use, a small business, or different family members.
*   **Intuitive Transaction Logging**: Quickly add income or expenses through a streamlined overlay.
*   **Category Management**: Organize your transactions with customizable, isolated categories for income and expenses within each profile.
*   **Recurrent Transactions**: Set up daily, weekly, or monthly recurrent transactions (like salaries or subscriptions) and let the app handle them automatically.
*   **Dual Calendar System**: Natively supports both Gregorian and Hijri calendars for viewing and managing your financial history.
*   **Data Portability**: Easily import and export your transaction history or entire financial simulations using CSV files.
*   **Powerful Financial Dashboard**:
    *   **At-a-glance summaries** of your recent financial activity.
    *   **Income vs. Expense** bar charts to visualize monthly cash flow.
    *   **Expense & Earnings Breakdown** pie charts to see where your money comes from and where it goes.
    *   **Intelligent Financial Projections**: A dynamic line chart that forecasts your future wallet balance by combining historical spending habits with scheduled recurrent transactions.
*   **"What-If" Simulations**:
    *   Create sandboxed copies of your financial history or start from a blank slate to experiment with different financial scenarios.
    *   Model the impact of a new job, a large purchase, or a change in spending habits without affecting your real data.
    *   Compare your simulated forecast directly against your original history with a side-by-side or stacked dashboard view.
*   **Responsive & Cross-Platform**: Designed to work beautifully on both Android and Windows, with layouts that adapt to your screen size.
*   **Multi-Language Support**: Fully localized for English and Arabic (Saudi Arabia).

---

## 🛠️ Tech Stack & Architecture

*   **Framework**: Flutter (v3.22.0+)
*   **Language**: Dart (v3.4.0+)
*   **State Management**: Provider
*   **Local Database**: SQLite (`sqflite` package)
*   **Charting**: `fl_chart`
*   **File Handling**: `file_picker`, `csv`
*   **Architecture**: Follows a clean, service-oriented architecture with a clear separation between UI, state management (Providers), business logic (Services), and data models.

---

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

*   Flutter SDK (version 3.22.0 or higher)
*   An IDE like VS Code or Android Studio with Flutter support.
*   A configured emulator or physical device for Android or Windows.

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/your_username/my_receipts.git
    ```
2.  **Navigate to the project directory:**
    ```sh
    cd my_receipts
    ```
3.  **Install dependencies:**
    ```sh
    flutter pub get
    ```
4.  **Generate localization files:**
    ```sh
    flutter gen-l10n
    ```
5.  **Generate launcher icons:**
    ```sh
    dart run flutter_launcher_icons
    ```
6.  **Run the app:**
    ```sh
    flutter run
    ```

---

## 🏗️ Building for Release

### Android (APK)

```sh
flutter build apk --release
```

### Windows

```sh
flutter build windows --release
```

---

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.


Project Link: [https://github.com/your_username/my_receipts](https://github.com/your_username/my_receipts)
