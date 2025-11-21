import 'package:flutter/widgets.dart';
import 'package:rate_my_app/rate_my_app.dart';

class AppRating {
  rateApp(BuildContext context){
    RateMyApp rateMyApp = RateMyApp(
      preferencesPrefix: "rateMyApp_",
      minDays: 0,
      minLaunches: 2,
      remindDays: 0,
      remindLaunches: 1,
      googlePlayIdentifier: "com.example.app_review",
    );

    rateMyApp.init().then((_) {
      if (rateMyApp.shouldOpenDialog) {
        rateMyApp.showRateDialog(
          context,
          title: "Enjoying the App?",
          message: "If you like using this app, please take a moment to rate it. Thanks for your support!",
          rateButton: "RATE NOW",
          noButton: "NO THANKS",
          laterButton: "MAYBE LATER",
          listener: (button) {
            switch (button) {
              case RateMyAppDialogButton.rate:
              debugPrint("User chose to rate the app.");
              break;
              case RateMyAppDialogButton.later:
              debugPrint("User chose to be reminded later.");
              break;
              case RateMyAppDialogButton.no:
              debugPrint("User chose not to rate the app.");
              break;
            }
            return true;      
          },
          dialogStyle: const DialogStyle(
            titleAlign: TextAlign.center,
            messageAlign: TextAlign.center,
          ),
        );
      }
    });
  }
}