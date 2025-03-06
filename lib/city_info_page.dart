import 'package:flutter/material.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'history_page.dart';

class CityInfoPage extends StatefulWidget {
  @override
  _CityInfoPageState createState() => _CityInfoPageState();
}

class _CityInfoPageState extends State<CityInfoPage> {
  String? cityName;

  /// Fetch location & send notifications
  void fetchCityAndNotify() async {
    String? city = await LocationService.getCurrentCity();
    if (city != null) {
      setState(() {
        cityName = city;
      });

      /// Send city-based notifications
      if (city == "Indore") {
        NotificationService.showNotification(
          "Indore Special",
          "Did you eat Poha today? 🌞",
        );

        NotificationService.showNotification(
          "Explore Indore",
          "Did you visit Khajrana Temple?",
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
    fetchCityAndNotify();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("City Info")),
      body: Center(
        child: cityName == null
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "You are in $cityName!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(
                      historyText:
                      "Khajrana Ganesh Temple was built by Rani Ahilyabai Holkar in the 18th century. The temple is famous for its belief in wish fulfillment...",
                    ),
                  ),
                );
              },
              child: Text("Know the History 📜"),
            ),
          ],
        ),
      ),
    );
  }
}
