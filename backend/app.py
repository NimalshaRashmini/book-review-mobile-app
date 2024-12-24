from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS  # Enable CORS for Flutter
from datetime import datetime

# Initialize Flask app and the database
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///reviews.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Enable CORS for all domains
CORS(app)

# Create the database tables explicitly
def create_tables():
    with app.app_context():  # Ensure this is run within an app context
        db.create_all()

# Review model
class Review(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    author = db.Column(db.String(100), nullable=False)
    rating = db.Column(db.Integer, nullable=False)
    review_text = db.Column(db.String(500), nullable=False)
    date_added = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)  # Automatically set date_added

    def __repr__(self):
        return f'<Review {self.title}>'

# Define your routes here (GET, POST, PUT, DELETE for reviews)
@app.route('/reviews', methods=['GET'])
def get_reviews():
    reviews = Review.query.all()
    return jsonify([{
        'id': review.id,
        'title': review.title,
        'author': review.author,
        'rating': review.rating,
        'review_text': review.review_text,
        'date_added': review.date_added.strftime('%Y-%m-%d %H:%M:%S')  # Formatting date
    } for review in reviews])

@app.route('/reviews', methods=['POST'])
def add_review():
    data = request.get_json()
    new_review = Review(
        title=data['title'],
        author=data['author'],
        rating=data['rating'],
        review_text=data['review_text']
    )
    db.session.add(new_review)
    db.session.commit()
    return jsonify({'message': 'Review added successfully!'}), 201

@app.route('/reviews/<int:id>', methods=['PUT'])
def update_review(id):
    review = Review.query.get_or_404(id)
    data = request.get_json()
    review.title = data['title']
    review.author = data['author']
    review.rating = data['rating']
    review.review_text = data['review_text']
    db.session.commit()
    return jsonify({'message': 'Review updated successfully!'})

@app.route('/reviews/<int:id>', methods=['DELETE'])
def delete_review(id):
    review = Review.query.get_or_404(id)
    db.session.delete(review)
    db.session.commit()
    return jsonify({'message': 'Review deleted successfully!'})

# Start the server and create tables if not already created
if __name__ == '__main__':
    create_tables()  # Call the table creation explicitly
    app.run(debug=True)
