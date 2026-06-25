enum ReservationStatus {
  onHold('ON_HOLD'),
  accepted('ACCEPTED'),
  rejected('REJECTED'),
  cancelled('CANCELLED'),
  blocked('BLOCKED');

  final String value;
  const ReservationStatus(this.value);

  static ReservationStatus fromString(String status) {
    return ReservationStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => ReservationStatus.onHold,
    );
  }
}

extension ReservationStatusX on ReservationStatus {
  bool get isVisibleInAgenda =>
      this == ReservationStatus.onHold ||
      this == ReservationStatus.accepted ||
      this == ReservationStatus.blocked;

  bool get blocksAvailability =>
      this == ReservationStatus.accepted || this == ReservationStatus.blocked;
}
