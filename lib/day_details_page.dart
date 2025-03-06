import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DayDetailsPage extends StatefulWidget {
  final String packageId;
  final int day;
  final Map<int, List<Map<String, dynamic>>> selectedActivities;
  final Map<int, String> selectedTransportation;
  final Function(double) onPriceUpdate;

  const DayDetailsPage({
    super.key,
    required this.packageId,
    required this.day,
    required this.selectedActivities,
    required this.selectedTransportation,
    required this.onPriceUpdate,
  });

  @override
  State<DayDetailsPage> createState() => _DayDetailsPageState();
}

class _DayDetailsPageState extends State<DayDetailsPage> {
  double totalDayCost = 0.0;
  late Map<int, List<Map<String, dynamic>>> localActivities;

  @override
  void initState() {
    super.initState();
    localActivities = Map.from(widget.selectedActivities);
    _loadDayData();
  }

  Future<void> _loadDayData() async {
    try {
      DocumentSnapshot daySnapshot =
      await FirebaseFirestore.instance
          .collection('travel_package')
          .doc(widget.packageId)
          .collection('itinerary')
          .doc('day_${widget.day}')
          .get();

      setState(() {
        if (daySnapshot.exists) {
          var rawData = daySnapshot.data();
          if (rawData != null) {
            Map<String, dynamic> data = rawData as Map<String, dynamic>;
            if (data['activities'] != null && data['activities'] is List) {
              List<dynamic> firestoreActivitiesDynamic = data['activities'];
              List<Map<String, dynamic>> firestoreActivities =
              firestoreActivitiesDynamic
                  .map((item) => Map<String, dynamic>.from(item as Map))
                  .toList();

              // Ensure day list exists
              if (!localActivities.containsKey(widget.day)) {
                localActivities[widget.day] = [];
              }

              // Merge Firestore activities, avoiding duplicates
              for (var activity in firestoreActivities) {
                if (!(localActivities[widget.day]!.any(
                      (a) => a['title'] == activity['title'],
                ))) {
                  localActivities[widget.day]!.add(activity);
                }
              }
            }
            if (data['transportation'] != null &&
                data['transportation'] is String) {
              widget.selectedTransportation[widget.day] =
              data['transportation'] as String;
            }
          }
        }
        _calculateDayCost();
        print("Loaded from Firestore: ${localActivities[widget.day]}");
        print("Total cost after load: $totalDayCost");
      });
    } catch (e) {
      print("Error loading Firestore data: $e");
      setState(() {
        _calculateDayCost();
        print(
          "Using passed activities due to error: ${localActivities[widget.day]}",
        );
      });
    }
  }

  void _calculateDayCost() {
    double activityCost =
        localActivities[widget.day]?.fold(
          0.0,
              (sum, activity) => sum! + (activity['price'] as num? ?? 0).toDouble(),
        ) ??
            0.0;
    double transportCost = _getTransportPrice(
      widget.selectedTransportation[widget.day] ?? '',
    );
    totalDayCost = activityCost + transportCost;
  }

  Future<void> _selectActivities() async {
    FocusScope.of(context).unfocus();
    QuerySnapshot activitySnapshot =
    await FirebaseFirestore.instance
        .collection('travel_package')
        .doc(widget.packageId)
        .collection('available_activities')
        .get();

    List<Map<String, dynamic>> availableActivities =
    activitySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    if (availableActivities.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No activities available")));
      return;
    }

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: Text(
          "Add Activities for Day ${widget.day}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableActivities.length,
            itemBuilder: (context, index) {
              final activity = availableActivities[index];
              final isSelected =
                  localActivities[widget.day]?.any(
                        (a) => a['title'] == activity['title'],
                  ) ??
                      false;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: CheckboxListTile(
                  activeColor: Colors.teal,
                  title: Text(
                    activity['title'] ?? 'Unknown Activity',
                    style: const TextStyle(fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "₹${activity['price'] ?? 0} • ${activity['duration'] ?? 0} mins",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (activity['description'] != null)
                        Text(
                          activity['description'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        if (!localActivities.containsKey(widget.day)) {
                          localActivities[widget.day] = [];
                        }
                        localActivities[widget.day]!.add(activity);
                        widget.onPriceUpdate(
                          (activity['price'] as num? ?? 0).toDouble(),
                        );
                      } else {
                        localActivities[widget.day]!.removeWhere(
                              (a) => a['title'] == activity['title'],
                        );
                        widget.onPriceUpdate(
                          -(activity['price'] as num? ?? 0).toDouble(),
                        );
                        if (localActivities[widget.day]!.isEmpty) {
                          localActivities.remove(widget.day);
                        }
                      }
                      _calculateDayCost();
                    });
                    Navigator.pop(context);
                    _selectActivities();
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Done", style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTransportation() async {
    FocusScope.of(context).unfocus();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
        title: Text(
          "Transportation for Day ${widget.day}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTransportOption(
              "Private Car",
              "₹500",
              Icons.directions_car,
            ),
            _buildTransportOption(
              "Public Transport",
              "₹100",
              Icons.directions_bus,
            ),
            _buildTransportOption("Walking", "Free", Icons.directions_walk),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        double priceChange = 0;
        if (widget.selectedTransportation[widget.day] != null) {
          priceChange -= _getTransportPrice(
            widget.selectedTransportation[widget.day]!,
          );
        }
        widget.selectedTransportation[widget.day] = result;
        priceChange += _getTransportPrice(result);
        widget.onPriceUpdate(priceChange);
        _calculateDayCost();
      });
    }
  }

  Widget _buildTransportOption(String title, String price, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: Text(price, style: const TextStyle(color: Colors.grey)),
        onTap: () => Navigator.pop(context, title),
      ),
    );
  }

  double _getTransportPrice(String option) {
    switch (option) {
      case "Private Car":
        return 500.0;
      case "Public Transport":
        return 100.0;
      case "Walking":
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Day ${widget.day} Itinerary",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                  title: const Text("Day Info"),
                  content: const Text(
                    "Plan your day with activities and transportation. Costs are updated in real-time.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "OK",
                        style: TextStyle(color: Colors.teal),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Cost for Day ${widget.day}",
                      style: const TextStyle(fontSize: 16, color: Colors.teal),
                    ),
                    Text(
                      "₹${totalDayCost.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _selectActivities,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Activity"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.directions, color: Colors.teal),
                title: const Text(
                  "Transportation",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  widget.selectedTransportation[widget.day] ??
                      "No transport selected",
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.teal),
                  onPressed: _selectTransportation,
                ),
              ),
            ),
          ),
          Expanded(
            child:
            localActivities[widget.day] != null &&
                localActivities[widget.day]!.isNotEmpty
                ? ListView.builder(
              itemCount: localActivities[widget.day]!.length,
              itemBuilder: (context, index) {
                final activity = localActivities[widget.day]![index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        activity['image'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                          Icons.error,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    title: Text(
                      activity['title'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "₹${activity['price'] ?? 0} • ${activity['duration'] ?? 0} mins",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          localActivities[widget.day]!.removeAt(index);
                          widget.onPriceUpdate(
                            -(activity['price'] as num? ?? 0)
                                .toDouble(),
                          );
                          if (localActivities[widget.day]!.isEmpty) {
                            localActivities.remove(widget.day);
                          }
                          _calculateDayCost();
                        });
                      },
                    ),
                  ),
                );
              },
            )
                : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "No activities selected yet",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Travel Tips",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "• Plan activities based on duration to avoid overbooking.\n"
                          "• Check weather forecasts before selecting outdoor activities.\n"
                          "• Private Car is ideal for flexibility, Walking saves money.",
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await FirebaseFirestore.instance
                .collection('travel_package')
                .doc(widget.packageId)
                .collection('itinerary')
                .doc('day_${widget.day}')
                .set({
              'activities': localActivities[widget.day] ?? [],
              'transportation':
              widget.selectedTransportation[widget.day] ?? '',
              'totalCost': totalDayCost,
            }, SetOptions(merge: true));
            print("Saved to Firestore: ${localActivities[widget.day]}");
          } catch (e) {
            print("Error saving to Firestore: $e");
          }
          Navigator.pop(context);
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.check),
      ),
    );
  }
}