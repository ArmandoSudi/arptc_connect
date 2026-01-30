enum ReservationStatus {
  onHold('ON_HOLD'),
  accepted('ACCEPTED'),
  rejected('REJECTED');

  final String value;
  const ReservationStatus(this.value);

  static ReservationStatus fromString(String status) {
    return ReservationStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => ReservationStatus.onHold,
    );
  }
}
