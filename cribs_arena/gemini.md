# Gemini Context: Cribs Arena App

This document outlines the core understanding of the Cribs Arena application to ensure consistent and context-aware assistance.

## 1. Project Overview

- **Project Name:** Cribs Arena
- **Technology Stack:** Flutter (Dart)
- **Platform:** Mobile (iOS, Android, etc.)

## 2. Core Purpose

Cribs Arena is a location-based mobile application designed to help users find and connect with agents. Based on the context and UI elements, these are likely real estate agents. The primary user interface is a map where users can visually locate and get more information about available agents.

## 3. Key Features & Components

- **Interactive Map:** The central feature is a Google Map (`lib/screens/user/user_widgets/map_screen.dart`) that displays agent locations.
- **Agent Markers:** Custom markers (`lib/screens/user/user_widgets/agent_marker.dart`) represent agents on the map. These markers are interactive and show details when tapped.
- **Agent Search:** Users can trigger a search for nearby agents using a Floating Action Button. The results are displayed as markers on the map.
- **Filtering:** The UI includes components for filtering search results, although the implementation details are in `lib/screens/user/user_widgets/filter_bottom_sheet.dart`.
- **UI Structure:** The main screen (`lib/screens/user/map_home_screen.dart`) is composed of several smaller, reusable widgets for the header, search bar, navigation, and map section.
- **State Management:** A `MapController` class is used to manage the state of the map (e.g., agent visibility, camera position) from the parent screen.

## 4. Project Structure Highlights

- **Main Entry Point:** `lib/main.dart`
- **Primary User Screen:** `lib/screens/user/map_home_screen.dart`
- **Core Map Logic:** `lib/screens/user/user_widgets/map_screen.dart`
- **Agent Representation:** `lib/screens/user/user_widgets/agent_marker.dart`
- **Assets:** Located in `assets/`, including icons and images for the UI and agent avatars.
- **Dummy Data:** The project currently uses a static list of agents defined in `lib/constants.dart` for demonstration purposes.

## 5. Development Patterns

- **Widget Composition:** The UI is built by composing many small, single-purpose widgets.
- **Stateful Management:** The main screen is a `StatefulWidget` that manages the state of its child components, including tab selection, search status, and map interactions.
- **Controller Pattern:** The `MapController` acts as a bridge between the main screen and the map widget, decoupling the map's internal logic from the UI that controls it.
