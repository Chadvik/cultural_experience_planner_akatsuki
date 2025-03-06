import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'aac_talker.dart';
import 'package:travel_tour/chatbot_screen.dart';
import 'packages_page.dart';
import 'reels_page.dart';
import 'community_page.dart';
import 'post_screen.dart';
import 'guide_list_page.dart';
import 'translate_home_page.dart';
import 'travel_planner_model.dart';
import 'recommendation_page.dart';
import 'culture_page.dart';
import 'city_info_page.dart';
import 'restaurant_recommendation.dart';
import 'places_recommendation.dart';
import 'food_recommendation_screen.dart';
import 'etiquette_quiz_page.dart';
import 'monument_detector_page.dart';
import 'scan_page.dart';
import 'profile_page.dart';
import 'ar_home_page.dart';
import 'personalized_packages_screen.dart';
import 'custom_booking_history.dart';
import 'package:google_fonts/google_fonts.dart';
import 'video_player_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? startingFrom;
  String? travellingTo;
  DateTime? selectedDate;
  int adults = 1;
  int children = 0;
  RangeValues budgetRange = RangeValues(5000, 20000);
  List<String> cities = [
    "New Delhi",
    "Mumbai",
    "Bangalore",
    "Goa",
    "Chennai",
    "Kolkata",
    "Hyderabad",
  ];
  int _selectedIndex = 0;

  List<Widget>? _screens;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var userId = FirebaseAuth.instance.currentUser?.uid;
    _screens ??= [
      Container(),
      ReelsPage(),
      const SizedBox.shrink(),
      CommunityPage(),
      ProfilePage(userId: userId ?? ''),
    ];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _updateTravellers(bool isAdult, bool increment) {
    setState(() {
      if (isAdult) {
        if (increment) {
          adults++;
        } else if (adults > 1) {
          adults--;
        }
      } else {
        if (increment) {
          children++;
        } else if (children > 0) {
          children--;
        }
      }
    });
  }

  void searchPackages() async {
    if (startingFrom == null ||
        travellingTo == null ||
        selectedDate == null ||
        startingFrom == travellingTo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            startingFrom == travellingTo
                ? "From and To locations cannot be the same"
                : "Please fill all details",
          ),
        ),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentReference searchRef = await FirebaseFirestore.instance
        .collection("travel_searches")
        .add({
      'userId': user.uid,
      'startingFrom': startingFrom,
      'travellingTo': travellingTo,
      'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
      'adults': adults,
      'children': children,
      'budgetMin': budgetRange.start,
      'budgetMax': budgetRange.end,
      'timestamp': FieldValue.serverTimestamp(),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackagesPage(
          destination: travellingTo!,
          adults: adults,
          children: children,
          budgetMin: budgetRange.start.toInt(),
          budgetMax: budgetRange.end.toInt(),
        ),
      ),
    );
  }

  void _navigateToPage(Widget? page) {
    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Feature coming soon!")));
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == 2) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.forum, color: Colors.blueAccent),
              title: Text('Post in Community'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          PostScreen(collection: 'community_posts')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.video_call, color: Colors.blueAccent),
              title: Text('Post in Reels'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PostScreen(collection: 'reels')),
                );
              },
            ),
          ],
        ),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  Widget buildHomeContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.20,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://cdn.pixabay.com/photo/2019/08/10/03/15/bridge-4396131_1280.jpg',
                ),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Text(
                    "Discover Your Dream",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                            color: Colors.black38,
                            offset: Offset(1, 1),
                            blurRadius: 4)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            shadowColor: Colors.blueAccent.withOpacity(0.2),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Plan Your Trip",
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent),
                  ),
                  SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: "From",
                          value: startingFrom,
                          items:
                          cities.where((city) => city != travellingTo).toList(),
                          onChanged: (value) => setState(() => startingFrom = value),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.blueAccent, size: 12),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildInputField(
                          label: "To",
                          value: travellingTo,
                          items:
                          cities.where((city) => city != startingFrom).toList(),
                          onChanged: (value) => setState(() => travellingTo = value),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildDateField(),
                  SizedBox(height: 12),
                  _buildTravellersField(),
                  SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Budget Range (₹${budgetRange.start.toInt()} - ₹${budgetRange.end.toInt()})",
                        style:
                        GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 6),
                      RangeSlider(
                        values: budgetRange,
                        min: 1000,
                        max: 50000,
                        divisions: 490,
                        labels: RangeLabels("₹${budgetRange.start.toInt()}",
                            "₹${budgetRange.end.toInt()}"),
                        onChanged: (RangeValues values) =>
                            setState(() => budgetRange = values),
                        activeColor: Colors.blueAccent,
                        inactiveColor: Colors.grey.shade300,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: ElevatedButton(
                        onPressed: searchPackages,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "Search Packages",
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Explore More",
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: travelOptions.length,
            itemBuilder: (context, index) {
              final option = travelOptions[index];
              return GestureDetector(
                onTap: () => _navigateToPage(option['page']),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(option['icon'], size: 36, color: Colors.blueAccent),
                      SizedBox(height: 6),
                      Text(
                        option['title'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bharat Yatra",
          style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        titleSpacing: 24.0, // Increase space between title and actions
        actions: [
          IconButton(
            icon: Icon(Icons.translate, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TranslateHomePage()),
              );
            },
          ),
          SizedBox(width: 4.0), // Increase space between the two icons
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanPage()),
              );
            },
          ),
          SizedBox(width: 8.0), // Optional: Add small padding at the end for balance
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Welcome!",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? "",
                    style:
                    GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.card_travel, color: Colors.blueAccent),
              title:
              Text("Personalized Packages", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _navigateToPage(PersonalizedPackagesScreen(userId: userId));
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.blueAccent),
              title: Text("Booking History", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _navigateToPage(BookingHistoryScreen(userId: userId));
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.blueAccent),
              title: Text("Local Guide", style: GoogleFonts.poppins()),
              onTap: () => _navigateToPage(GuidesListPage(destination: "Chennai")),
            ),
            ListTile(
              leading: Icon(Icons.location_city, color: Colors.blueAccent),
              title: Text("City Info", style: GoogleFonts.poppins()),
              onTap: () => _navigateToPage(CityInfoPage()),
            ),
            ListTile(
              leading: Icon(Icons.rule_folder, color: Colors.blueAccent),
              title: Text("Etiquette Quiz", style: GoogleFonts.poppins()),
              onTap: () => _navigateToPage(EtiquetteQuizPage()),
            ),
            ListTile(
              leading: Icon(Icons.tour, color: Colors.blueAccent),
              title: Text("Tour Recommendations", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _navigateToPage(RecommendationScreen());
              },
            ),
            ListTile(
              leading: Icon(Icons.view_in_ar, color: Colors.blueAccent),
              title: Text("AR Viewer", style: GoogleFonts.poppins()),
              onTap: () => _navigateToPage(ArHomePage(title: 'Traverse AR')),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.blueAccent),
              title: Text("Logout", style: GoogleFonts.poppins()),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: _selectedIndex == 0 ? buildHomeContent() : _screens![_selectedIndex],
      floatingActionButton: WigglingPopupButton(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VideoPlayerPage()),
            );
            },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline), label: "Reels"),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.add, color: Colors.white, size: 20),
            ),
            label: "Post",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ClipRect(
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.grey), // Smaller label
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blueAccent)),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 4), // Minimized padding
        ),
        items: items
            .map((city) => DropdownMenuItem(
            value: city,
            child: Text(city,
                style: GoogleFonts.poppins(fontSize: 11),
                overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        style: GoogleFonts.poppins(fontSize: 11, color: Colors.black87),
        isDense: true,
        isExpanded: true, // Ensure dropdown uses full width of parent
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blueAccent, size: 16),
                SizedBox(width: 8),
                Text(
                  selectedDate == null
                      ? "Select Date"
                      : DateFormat('d MMM yyyy').format(selectedDate!),
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
            Icon(Icons.arrow_drop_down, color: Colors.blueAccent, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTravellersField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Travellers",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Adults",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
            Row(
              children: [
                IconButton(
                    icon: Icon(Icons.remove, size: 16, color: Colors.blueAccent),
                    onPressed: () => _updateTravellers(true, false)),
                Text("$adults", style: GoogleFonts.poppins(fontSize: 14)),
                IconButton(
                    icon: Icon(Icons.add, size: 16, color: Colors.blueAccent),
                    onPressed: () => _updateTravellers(true, true)),
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Children",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
            Row(
              children: [
                IconButton(
                    icon: Icon(Icons.remove, size: 16, color: Colors.blueAccent),
                    onPressed: () => _updateTravellers(false, false)),
                Text("$children", style: GoogleFonts.poppins(fontSize: 14)),
                IconButton(
                    icon: Icon(Icons.add, size: 16, color: Colors.blueAccent),
                    onPressed: () => _updateTravellers(false, true)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class WigglingPopupButton extends StatefulWidget {
  final VoidCallback onTap;

  const WigglingPopupButton({required this.onTap, Key? key}) : super(key: key);

  @override
  _WigglingPopupButtonState createState() => _WigglingPopupButtonState();
}

class _WigglingPopupButtonState extends State<WigglingPopupButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 5 * _controller.value),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 50,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  bottomLeft: Radius.circular(50),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.music_video_sharp,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

List<Map<String, dynamic>> travelOptions = [
  {'title': 'Cultures', 'icon': Icons.fireplace, 'page': CulturePage()},
  {'title': 'Personalized Travel', 'icon': Icons.travel_explore, 'page': TravelPlannerApp()},

  {'title': 'Monuments', 'icon': Icons.fort, 'page': MonumentClassifier()},
  {
    'title': 'Foodies',
    'icon': Icons.fastfood,
    'page': FoodRecommendationScreen()
  },
  {
    'title': 'Restaurant',
    'icon': Icons.restaurant,
    'page': RestaurantRecommendationScreen()
  },
  {
    'title': 'Getaways',
    'icon': Icons.location_on,
    'page': PlaceRecommendationScreen()
  },
  {
    'title': 'Learn Greetings',
    'icon': Icons.speaker_group,
    'page': AACTalkerScreen()
  },
  {
    'title': 'Etiquette',
    'icon': Icons.rule_folder,
    'page': EtiquetteQuizPage()
  },
  {'title': 'ChatBot', 'icon': Icons.perm_camera_mic, 'page': ChatbotScreen()},



];