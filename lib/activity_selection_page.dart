import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivitySelectionPage extends StatefulWidget {
  final String packageId;
  final int day;
  final String destination;

  ActivitySelectionPage({
    required this.packageId,
    required this.day,
    required this.destination,
  });

  @override
  _ActivitySelectionPageState createState() => _ActivitySelectionPageState();
}

class _ActivitySelectionPageState extends State<ActivitySelectionPage> {
  List<Map<String, dynamic>> availableActivities = [];
  Set<String> selectedActivityIds = {};
  double totalSelectedPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  /// Fetches the list of available activities from Firestore
  Future<void> _fetchActivities() async {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance
        .collection('activities')
        .where('destination', isEqualTo: widget.destination)
        .get();

    setState(() {
      availableActivities =
          snapshot.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Store document ID
            return data;
          }).toList();
    });
  }

  /// Handles selecting or deselecting an activity
  void _toggleActivitySelection(Map<String, dynamic> activity) {
    setState(() {
      if (selectedActivityIds.contains(activity['id'])) {
        selectedActivityIds.remove(activity['id']);
        totalSelectedPrice -= activity['price'];
      } else {
        selectedActivityIds.add(activity['id']);
        totalSelectedPrice += activity['price'];
      }
    });
  }

  /// Saves selected activities to Firestore and updates total price
  Future<void> _confirmSelection() async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    DocumentReference packageRef = FirebaseFirestore.instance
        .collection('travel_packages')
        .doc(widget.packageId);

    // Get current total price
    DocumentSnapshot packageSnapshot = await packageRef.get();
    double currentTotalPrice =
    packageSnapshot.exists
        ? (packageSnapshot['total_price'] ?? 0.0).toDouble()
        : 0.0;

    for (String activityId in selectedActivityIds) {
      Map<String, dynamic> activity = availableActivities.firstWhere(
            (a) => a['id'] == activityId,
      );

      DocumentReference activityRef = packageRef
          .collection('itinerary')
          .doc('day_${widget.day}')
          .collection('activities')
          .doc(activityId);

      batch.set(activityRef, {
        'title': activity['title'],
        'duration': activity['duration'],
        'price': activity['price'],
        'image': activity['image'],
        'id': activity['id'],
      });
    }

    // Update total package price
    batch.update(packageRef, {
      'total_price': currentTotalPrice + totalSelectedPrice,
    });

    await batch.commit();

    // Navigate back to ItineraryPage
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Activities for Day ${widget.day}")),
      body:
      availableActivities.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: availableActivities.length,
        itemBuilder: (context, index) {
          var activity = availableActivities[index];
          bool isSelected = selectedActivityIds.contains(
            activity['id'],
          );

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: Image.network(
                activity['image'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
              title: Text(activity['title']),
              subtitle: Text("Duration: ${activity['duration']} hours"),
              trailing: Checkbox(
                value: isSelected,
                onChanged:
                    (value) => _toggleActivitySelection(activity),
              ),
              onTap: () => _toggleActivitySelection(activity),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(10),
        child: ElevatedButton(
          onPressed: selectedActivityIds.isNotEmpty ? _confirmSelection : null,
          child: Text("CONFIRM"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            disabledBackgroundColor: Colors.grey,
            padding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}


