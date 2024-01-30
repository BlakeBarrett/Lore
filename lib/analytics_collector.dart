///  Purpose: Analytics collector class
///  This class is used to collect analytics data and send it to the analytics service.
///  It is a singleton class, so it can be accessed from anywhere in the app.
///  It uses the AnalyticsService class to send the data to the analytics service.
class AnalyticsCollector {
  final AnalyticsService _analyticsService;

  AnalyticsCollector(this._analyticsService);

  static get instance => AnalyticsCollector(AnalyticsService());

  void collect(String eventName, Map<String, dynamic> params) {
    _analyticsService.logEvent(eventName, params);
  }

  void flush() {
    _analyticsService.flush();
  }
}

class AnalyticsService {
  // final FirebaseAnalytics _analytics = FirebaseAnalytics();

  void logEvent(String eventName, Map<String, dynamic> params) {
    // _analytics.logEvent(name: eventName, parameters: params);
  }

  void flush() {
    // _analytics.flush();
  }
}
