# 🛒 Decart Admin Portal


## 📝 Description

**Decart Admin** is a robust, Flutter-based administrative dashboard designed to securely manage the backend operations of the Decart e-commerce platform. Built with a focus on real-time data synchronization and strict security, this portal acts as the centralized control center for store owners. 

Powered by Firebase Cloud Firestore and Firebase Authentication, the app ensures that only verified administrators can manipulate store data. It provides seamless tools to manage the product catalog, monitor live customer orders, update shipping statuses (which sync instantly to the buyer's tracking screen), and control user privileges.

## ✨ Key Features
* **🔒 Secure Role-Based Access (RBAC):** Protected login system that strictly verifies the boolean in Firestore before granting access, backed by custom Firebase Security Rules.
* **📦 Live Order Management:** Monitor all customer orders across the platform using optimized queries. Update order statuses (Placed -> Shipped -> Delivered) that trigger real-time UI updates on the buyer's app.
* **🛍️ Product Catalog Control:** Easily upload new inventory, set pricing, assign categories, and manage product descriptions dynamically.
* **👥 User Directory & Privileges:** Full visibility into registered customers. Admins can seamlessly promote other users to admin status, edit profiles, or permanently remove accounts from the database.
* **⚡ Real-Time Sync:** Utilizes Flutter to instantly reflect database changes without requiring manual refreshes.

## 🛠️ Tech Stack
* **Frontend:** Flutter & Dart
* **Backend:** Firebase (Cloud Firestore)
* **Authentication:** Firebase Auth
* **State Management:** Reactive streams (StreamBuilder)
