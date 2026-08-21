class BusinessDayService {
  static const int closingHour = 5;

  const BusinessDayService();

  DateTime businessDate(DateTime dateTime) {
    if (dateTime.hour < closingHour) {
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day - 1,
      );
    }

    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );
  }
}