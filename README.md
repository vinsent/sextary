# Sextary - AI Chat Application

A modern AI chatbot application for iOS, built with SwiftUI and powered by the Kimi API.

## Features

- 🤖 **AI Chat** - Chat with Kimi AI using streaming responses
- 💬 **Message History** - Persistent conversation storage with SQLite
- 🗣️ **Voice Input** - Speech-to-text support for hands-free chatting
- 📋 **Multi-Conversation** - Manage multiple chat conversations
- 🎨 **Markdown Support** - Rich text rendering for AI responses
- 🔐 **Secure API Key Storage** - API key stored in Keychain

## Tech Stack

- **Framework**: SwiftUI 5
- **Language**: Swift 6
- **Database**: SQLite.swift
- **Networking**: Alamofire
- **Markdown**: MarkdownUI
- **Speech Recognition**: Apple Speech Framework

## Requirements

- iOS 17.0+
- Xcode 16.0+
- Kimi API Key (from Moonshot AI)

## Configure API Key

1. Open the project in Xcode
2. Run the app on a simulator or device
3. On first launch, you will be prompted to enter your Kimi API key
4. The API key will be securely stored in Keychain

## Demo

[![Watch the demo](https://img.youtube.com/vi/byEEW_usgLw/maxresdefault.jpg)](https://www.youtube.com/shorts/byEEW_usgLw)

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Model**: Data models and database entities
- **View**: SwiftUI views for UI presentation
- **ViewModel**: Business logic and data management
- **Store**: Repository pattern for database operations
- **Service**: API communication and key management