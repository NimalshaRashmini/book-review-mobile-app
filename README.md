# book_review_app

The Book Review App is a full-stack project designed to allow users to create, view, update, and delete book reviews. It features a backend API built with Python Flask and a frontend developed using Flutter.
Features
Backend:
REST API built with Flask.
SQLite database for storing review data.
CRUD operations for managing book reviews.
CORS support for Flutter integration.
Frontend:
Dynamic and interactive user interface using Flutter.
Modern design with Material 3.
Features like filtering by rating, sorting reviews, and calculating average ratings.

Tech Stack
Backend:Python,flask
Frontend: Flutter, Dart

#Setup and Installation

Backend Setup

Navigate to the backend directory:
cd book_review_app/backend

Create a virtual environment:
python3 -m venv venv

Activate the virtual environment:
On Linux/Mac: source venv/bin/activate
On Windows: venv\Scripts\activate

Install the required dependencies:
pip install -r requirements.txt

Run the Flask application: python app.py

Run the Flutter application: flutter run

API Endpoints:
GET /reviews: Fetch all book reviews.
POST /reviews: Add a new review.
PUT /reviews/: Update an existing review by its ID.
DELETE /reviews/: Delete a review by its ID.
