Wikileet Prompts

### **Prompt 1: Setting Up Firebase and Integrating It with Flutter**

**Project Rundown:**

I'm building a family gift list app using Flutter and Firestore (Firebase). The app allows family members to create and share their gift lists. When someone gets an item from a person's list, the item remains visible to the owner but is marked or hidden from other users to prevent duplicate gifts. The app is currently a PWA (Progressive Web App) built with Flutter.Please approach this as a principle software engineer leading the project? I will drive the implementation, and will learn what the best steps are in the process.

**Instructions:**

- Guide me through setting up a Firebase project for my Flutter app.
- Help me integrate Firebase into my Flutter project, including adding the necessary dependencies.
- Assist with configuring Firestore as the backend database for data storage.
- Ensure the Firebase setup supports web platforms since I'm using a PWA.
- Provide any best practices for initializing Firebase in a Flutter web app.

---

### **Prompt 2: Designing the Firestore Database Structure**

**Project Rundown:**

*As above.*

**Instructions:**

- Help me design the Firestore database schema for my gift list app.
- Determine the collections and documents needed to store users, gift lists, and gift items.
- Explain how to model relationships between users and gifts in Firestore.
- Advise on the best practices for structuring data to optimize for performance and scalability.
- Include considerations for real-time updates and data security.

---

### **Prompt 3: Implementing User Authentication**

**Project Rundown:**

*As above.*

**Instructions:**

- Guide me through implementing user authentication using Firebase Authentication in my Flutter app.
- Assist in setting up email and password authentication.
- Help me create sign-up and login screens in Flutter.
- Show how to handle authentication state changes and maintain user sessions.
- Ensure that only authenticated users can access the main features of the app.

---

### **Prompt 4: Creating User Profiles and Family Groups**

**Project Rundown:**

*As above.*

**Instructions:**

- Help me implement user profiles where each user can have a display name and avatar.
- Show how to create and manage family groups within the app.
- Explain how users can join a family group, possibly through invitation codes.
- Ensure that gift lists are only shared within the same family group.
- Discuss security rules to enforce access control based on family groups.

---

### **Prompt 5: Building the Gift List Feature**

**Project Rundown:**

*As above.*

**Instructions:**

- Assist me in developing the functionality for users to create, edit, and delete items on their gift lists.
- Show how to write data to Firestore when a user adds or modifies a gift item.
- Help design the UI for displaying the user's own gift list in Flutter.
- Ensure data synchronization between the app and Firestore in real-time.
- Include error handling for operations like adding or deleting gifts.

---

### **Prompt 6: Viewing and Interacting with Other Users' Gift Lists**

**Project Rundown:**

*As above.*

**Instructions:**

- Guide me in implementing the feature where users can view other family members' gift lists.
- Explain how to display gift items differently for the list owner and other users (e.g., purchased items marked for others but not for the owner).
- Show how to fetch and display data from Firestore securely.
- Assist in setting up the UI to navigate between different users' gift lists.
- Discuss any necessary security rules to protect user data.

---

### **Prompt 7: Implementing the Purchase Functionality**

**Project Rundown:**

*As above.*

**Instructions:**

- Help me implement a feature that allows users to mark a gift item as purchased.
- Ensure that when an item is marked as purchased, it updates in Firestore and reflects across all users' views.
- Explain how to prevent the gift owner from seeing that the item has been purchased.
- Discuss strategies to handle concurrent purchases and avoid race conditions.
- Include UI elements for users to mark items as purchased and see which items are already purchased (excluding the owner).

---

### **Prompt 8: Real-Time Updates and State Management**

**Project Rundown:**

*As above.*

**Instructions:**

- Show how to implement real-time listeners in Flutter using `StreamBuilder` or similar widgets.
- Help me choose a state management solution (e.g., Provider, Riverpod, Bloc) suitable for my app.
- Explain how to manage the app's state effectively to reflect real-time changes from Firestore.
- Provide examples of updating the UI in response to data changes.
- Discuss best practices for optimizing performance with real-time data.

---

### **Prompt 9: Enhancing the User Interface and UX**

**Project Rundown:**

*As above.*

**Instructions:**

- Assist me in improving the overall UI/UX of the app.
- Provide guidance on designing responsive layouts that work well on different devices.
- Show how to implement intuitive navigation (e.g., using bottom navigation bars, drawers).
- Suggest UI components and animations that enhance user experience.
- Ensure that the app is accessible and user-friendly for all age groups.

---

### **Prompt 10: Setting Up Firestore Security Rules**

**Project Rundown:**

*As above.*

**Instructions:**

- Help me write Firestore security rules to protect user data.
- Ensure that users can only read and write data they are authorized to access.
- Explain how to secure data based on family groups and user permissions.
- Provide examples of rules that prevent unauthorized access or modifications.
- Discuss testing strategies for security rules to ensure they work as intended.

---

### **Prompt 11: Implementing Error Handling and Validation**

**Project Rundown:**

*As above.*

**Instructions:**

- Guide me on how to implement robust error handling in my Flutter app.
- Show how to validate user input both on the client side and before writing to Firestore.
- Explain how to display error messages and feedback to the user.
- Provide best practices for logging errors and monitoring app stability.
- Include examples of handling network errors and Firestore exceptions.

---

### **Prompt 12: Testing and Debugging the App**

**Project Rundown:**

*As above.*

**Instructions:**

- Assist me in setting up unit tests and widget tests for my Flutter app.
- Explain how to use Flutter's testing framework to ensure code reliability.
- Help me identify common issues and debugging techniques in Flutter and Firebase.
- Show how to simulate Firestore data for testing purposes.
- Discuss strategies for continuous testing during development.

---

### **Prompt 13: Optimizing Performance**

**Project Rundown:**

*As above.*

**Instructions:**

- Provide guidance on optimizing the app's performance, especially regarding real-time data syncing.
- Explain how to use pagination or data limiting when fetching data from Firestore.
- Show how to optimize images and other assets in the app.
- Discuss best practices for reducing app load time and improving responsiveness.
- Include tips on profiling the app to identify performance bottlenecks.

---

### **Prompt 14: Preparing for Deployment**

**Project Rundown:**

*As above.*

**Instructions:**

- Help me prepare the app for deployment as a Progressive Web App (PWA).
- Ensure that all PWA requirements are met (manifest, service worker, HTTPS).
- Guide me through deploying the app to a hosting platform like Firebase Hosting or Netlify.
- Explain how to test the PWA features thoroughly before release.
- Provide advice on post-deployment monitoring and updates.

---

# WikiLeet Development Progress

## Active Implementation
Currently working on Family Group and House Structure:
1. 🏃‍♂️ Family Group and House Refactoring:
   - [ ] Fix house assignments when users select a house
   - [ ] Add "Create House" button functionality
   - [ ] Update layout for family list and gift list side-by-side view on larger screens
   - [ ] Review and fix any mixed up family group vs house creation logic

## Architecture Notes
- Family Groups: Represent the top-level workspace where users collaborate
- Houses: Represent teams or sub-groups within a family group
- Relationships:
  - Users belong to one Family Group
  - Within a Family Group, users can be part of different Houses
  - Houses are used for further organization within the Family Group

## Completed Features
- Basic project structure and Firebase integration
- Google Sign-In Authentication
- Family Group Management
  - Creation and management of family groups
  - House-based organization
  - Admin interface
  - Real-time member list updates
  - User profile display and caching
  - Group joining via invite codes
  - Member removal functionality
- Gift List Management
  - Comprehensive CRUD operations for gifts
  - Real-time gift status updates
  - Gift visibility controls
  - Gift categorization
  - Purchase tracking system
  - Gift URL integration

## Pending Features
1. Family Group and House Structure
   - [ ] Fix house assignment functionality
   - [ ] Implement proper house creation flow
   - [ ] Update UI for better organization display
   - [ ] Add house management features
2. Gift List Enhancement
   - [ ] Add search and filtering capabilities
   - [ ] Implement gift recommendations
   - [ ] Add gift sorting options
   - [ ] Add batch operations
3. Security & Data Validation
   - [ ] Review and enhance Firestore security rules
   - [ ] Implement robust family group access controls
   - [ ] Add comprehensive data validation
   - [ ] Add error handling and recovery mechanisms
4. UI/UX Improvements
   - [ ] Implement responsive layouts with side-by-side views
   - [ ] Enhance navigation patterns
   - [ ] Add loading states and error feedback
   - [ ] Implement modern UI components
   - [ ] Add accessibility features

## Implementation Order
1. 🏃‍♂️ Current: Family Group and House Structure Refactoring
2. Gift List Enhancements
3. Security Rules & Validation
4. UI/UX Improvements
5. Testing Infrastructure
6. Polish and Deploy

## Technical Debt
- Review and optimize Firebase queries
- Implement proper error handling throughout the app
- Add comprehensive logging
- Document code and architecture
- Add automated testing
