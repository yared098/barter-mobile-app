# Barter Ethio — Mobile App

Flutter mobile client for **Barter Ethio** — a peer-to-peer barter exchange platform. Users list items they own, declare what they want in return, and the app surfaces ranked matches. When two users agree, they swap products directly.

**Stack:** Flutter 3.24 · Dart 3.5 · Riverpod 2.x · Firebase (FCM) · HTTP

**Design:** Green + white only. Jade green (`#00A86B`) accents on white surfaces. Dark green (`#0B3D2E`) body text. No blue, orange, or purple anywhere.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screens](#screens)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Push Notifications](#push-notifications)
- [Theming](#theming)
- [State Management](#state-management)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Common Issues](#common-issues)
- [Build & Release](#build--release)
- [Roadmap](#roadmap)

---

## Overview

Barter Ethio is a **mobile-first barter marketplace**. Instead of buying and selling, users trade items directly:

1. **Post a product** you own (iPhone 15 Pro)
2. **Declare what you want** (Sony headphones, Nike shoes, etc.)
3. **See matches** — other users' products that fit your wants
4. **Send an offer** — propose a specific trade
5. **Chat** — negotiate inside the offer
6. **Accept & swap** — ownership transfers atomically on the backend
7. **Meet in person** — exchange items
8. **Mark complete** — both sides confirm

The mobile app is a thin client — all business logic lives in the NestJS backend. This app is **state, UI, and push notifications**.

---

## Features

### Authentication
-  Email login (backend OTP-ready)
-  Password login (for testing with seeded users)
-  Session persistence via SharedPreferences
-  Auto-refresh of access tokens on 401
-  Auto-logout on token expiry

### Products
-  Post product with image (camera or gallery)
-  Category selection ("What is this?")
-  Multi-category wants ("What do you want?")
-  Condition, estimated value
-  List "my products" with delete

### Matches
-  Ranked match feed with score badge
-  Human-readable match reasons ("They also want what you have")
-  Empty state with helpful tips
-  Pull-to-refresh

### Offers
-  Send offer from any match
-  Incoming / Outgoing tabs
-  Chat inside offers
-  Accept, decline, cancel, complete actions
-  Real-time status updates

### Push Notifications
-  FCM integration (Android + iOS)
-  Notification for every business event (offer, accept, decline, message, swap complete)
-  Deep link to offer on tap
-  Local notification for foreground events
-  Custom logo icon + green accent color

### Design
-  Green/white theme only
-  Material 3 with custom design tokens
-  Consistent 14–16px border radius
-  Reusable widgets (InputField, PrimaryButton, CategoryChip, ScoreBadge)
-  Loading / error / empty states everywhere

---

## Screens

| Screen | Route | Purpose |
|---|---|---|
| **Splash** | `splash_screen.dart` | Auth check → routes to Login or Home |
| **Login** | `login_screen.dart` | Email + password (dev: pre-filled test accounts) |
| **OTP** | `otp_screen.dart` | 6-digit verification (ready for real OTP) |
| **Home** | `home_screen.dart` | Match feed — the main screen |
| **Post Product** | `post_product_screen.dart` | Create listing with images and wants |
| **Offers** | `offers_screen.dart` | Incoming / Outgoing offer list |
| **Offer Detail** | `offer_detail_screen.dart` | Product pair + chat + action buttons |

---

## Architecture
