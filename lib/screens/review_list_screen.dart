import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReviewListScreen extends StatefulWidget {
  @override
  _ReviewListScreenState createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  List<dynamic> reviews = [];
  List<dynamic> filteredReviews = [];
  bool isLoading = false;
  bool isAscending = true; // For sorting by date (ascending/descending)
  String selectedRating = 'All Ratings'; // Default filter option
  double averageRating = 0.0;

  // Controllers for creating/editing reviews
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController reviewTextController = TextEditingController();
  double currentRating = 3.0; // Default rating value
  int? editingReviewId; // For tracking the review being edited

  @override
  void initState() {
    super.initState();
    fetchReviews(); // Fetch reviews when the screen is loaded
  }

  // Fetch reviews from the backend (Flask API)
  Future<void> fetchReviews() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:5000/reviews'));
      if (response.statusCode == 200) {
        setState(() {
          reviews = json.decode(response.body);
          filteredReviews = List.from(reviews);
          calculateAverageRating();
          applyFiltersAndSorting();
          isLoading = false;
        });
      } else {
        showErrorDialog('Failed to load reviews. Please try again later.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorDialog('Error fetching reviews: $e');
    }
  }

  // Calculate the average rating
  void calculateAverageRating() {
    if (reviews.isEmpty) {
      averageRating = 0.0;
    } else {
      double sum = 0.0;
      for (var review in reviews) {
        sum += review['rating'];
      }
      averageRating = sum / reviews.length;
    }
  }

  // Apply sorting and filtering
  void applyFiltersAndSorting() {
    setState(() {
      // Filter by selected rating
      if (selectedRating == 'All Ratings') {
        filteredReviews = List.from(reviews);
      } else {
        filteredReviews = reviews
            .where((review) => review['rating'].toString() == selectedRating)
            .toList();
      }

      // Sort by date added
      filteredReviews.sort((a, b) {
        DateTime dateA = DateTime.parse(a['date_added']);
        DateTime dateB = DateTime.parse(b['date_added']);
        return isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });
    });
  }

  // Show an error dialog
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Show full review in a dialog
  void showFullReview(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Rounded corners
            side:
                BorderSide(color: Colors.blue[800]!, width: 1.5), // Blue border
          ),
          child: Container(
            width: MediaQuery.of(context).size.width *
                0.9, // Take 90% of the screen width
            height: MediaQuery.of(context).size.height *
                0.8, // Take 80% of the screen height
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(
                  255, 184, 225, 255), // Light blue background
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.blue[800], // Blue title color
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Author: ${review['author']}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: review['rating'].toDouble(),
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 24.0,
                        direction: Axis.horizontal,
                      ),
                      SizedBox(width: 10),
                      Text(
                        '(${review['rating']} stars)',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Date Added: ${review['date_added']}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 20),
                  Text(
                    review['review_text'],
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.blue[800], // Blue button text
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Add a new review to the backend
  Future<void> addReview() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': titleController.text,
          'author': authorController.text,
          'rating': currentRating.toInt(),
          'review_text': reviewTextController.text,
        }),
      );

      if (response.statusCode == 201) {
        fetchReviews(); // Refresh the reviews list
        Navigator.of(context).pop(); // Close the modal
      } else {
        showErrorDialog('Failed to add review.');
      }
    } catch (e) {
      showErrorDialog('Error adding review: $e');
    }
  }

  // Update a review in the backend
  Future<void> updateReview() async {
    if (editingReviewId == null) return;

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:5000/reviews/$editingReviewId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': titleController.text,
          'author': authorController.text,
          'rating': currentRating.toInt(),
          'review_text': reviewTextController.text,
        }),
      );

      if (response.statusCode == 200) {
        fetchReviews(); // Refresh the reviews list
        Navigator.of(context).pop(); // Close the modal
      } else {
        showErrorDialog('Failed to update review.');
      }
    } catch (e) {
      showErrorDialog('Error updating review: $e');
    }
  }

  // Delete a review from the backend
  Future<void> deleteReview(int id) async {
    try {
      final response =
          await http.delete(Uri.parse('http://10.0.2.2:5000/reviews/$id'));
      if (response.statusCode == 200) {
        fetchReviews();
      } else {
        showErrorDialog('Failed to delete review.');
      }
    } catch (e) {
      showErrorDialog('Error deleting review: $e');
    }
  }

  // Build the widget to display reviews
  Widget buildReviewList() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Display the average rating
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Average Rating: ',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: averageRating,
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 20.0,
                          direction: Axis.horizontal,
                        ),
                        SizedBox(width: 8),
                        Text(averageRating.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),
              // Rating filter dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text('Filter by Rating: '),
                    DropdownButton<String>(
                      value: selectedRating,
                      onChanged: (value) {
                        setState(() {
                          selectedRating = value!;
                          applyFiltersAndSorting(); // Apply filter and sorting
                        });
                      },
                      items: <String>['All Ratings', '1', '2', '3', '4', '5']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredReviews.length,
                  itemBuilder: (context, index) {
                    var review = filteredReviews[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 153, 211, 246),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blue[800]!, // Blue border color
                          width: 1.5, // Border width
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2), // Shadow color
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review['title'],
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'by ${review['author']}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    RatingBarIndicator(
                                      rating: review['rating'].toDouble(),
                                      itemBuilder: (context, _) => Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      itemCount: 5,
                                      itemSize: 16.0,
                                      direction: Axis.horizontal,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '(${review['rating']} stars)',
                                      style: TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Date: ${review['date_added']}',
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.visibility,
                                    color: Colors.blue[800]),
                                onPressed: () {
                                  showFullReview(review);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue[800]),
                                onPressed: () {
                                  // Pre-fill the form with review details
                                  titleController.text = review['title'];
                                  authorController.text = review['author'];
                                  reviewTextController.text =
                                      review['review_text'];
                                  currentRating = review['rating'].toDouble();
                                  editingReviewId = review['id'];

                                  // Show the bottom sheet for editing
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (BuildContext context) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: MediaQuery.of(context)
                                              .viewInsets
                                              .bottom,
                                          left: 16.0,
                                          right: 16.0,
                                          top: 16.0,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: titleController,
                                              decoration: InputDecoration(
                                                  labelText: 'Title'),
                                            ),
                                            TextField(
                                              controller: authorController,
                                              decoration: InputDecoration(
                                                  labelText: 'Author'),
                                            ),
                                            RatingBar.builder(
                                              initialRating: currentRating,
                                              minRating: 1,
                                              direction: Axis.horizontal,
                                              allowHalfRating: false,
                                              itemCount: 5,
                                              itemBuilder: (context, _) => Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                              ),
                                              onRatingUpdate: (rating) {
                                                currentRating = rating;
                                              },
                                            ),
                                            TextField(
                                              controller: reviewTextController,
                                              decoration: InputDecoration(
                                                  labelText: 'Review Text'),
                                            ),
                                            SizedBox(height: 20),
                                            ElevatedButton(
                                              onPressed: updateReview,
                                              child: Text('Update Review'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color:
                                        const Color.fromARGB(255, 31, 14, 83)),
                                onPressed: () {
                                  deleteReview(review['id']);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }

  // Show a bottom sheet to create a new review
  void showCreateReviewForm() {
    titleController.clear();
    authorController.clear();
    reviewTextController.clear();
    currentRating = 3.0;
    editingReviewId = null; // Reset editing ID

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: authorController,
                decoration: InputDecoration(labelText: 'Author'),
              ),
              RatingBar.builder(
                initialRating: currentRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  currentRating = rating;
                },
              ),
              TextField(
                controller: reviewTextController,
                decoration: InputDecoration(labelText: 'Review Text'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: addReview,
                child: Text('Add Review'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Book Reviews'),
        actions: [
          IconButton(
            icon: Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () {
              setState(() {
                isAscending = !isAscending; // Toggle sorting order
                applyFiltersAndSorting(); // Apply sorting
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: buildReviewList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCreateReviewForm,
        child: Icon(Icons.add),
      ),
    );
  }
}
