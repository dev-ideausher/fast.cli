class ValidationNotification {
  final String property;
  final String message;

  ValidationNotification(this.property, this.message);
}

class Contract<T> {
  final T? value;
  final String property;
  final List<ValidationNotification> notifications = [];

  Contract(this.value, this.property);

  bool get invalid => notifications.isNotEmpty;
  bool get valid => !invalid;

  Contract<T> isNotNull([String? message]) {
    final isEmptyString = value is String && (value as String).trim().isEmpty;

    if (value == null || isEmptyString) {
      notifications.add(
        ValidationNotification(property, message ?? 'This field is required.'),
      );
    }

    return this;
  }
}

