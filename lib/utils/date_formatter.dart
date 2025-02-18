import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String formatTimestamp(Timestamp timestamp) {
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp.toDate());
}
