import 'package:bridge/08-thread/thread_model.dart';

class AdminReportedThread {
  final String reportId;
  final Thread thread;

  AdminReportedThread({
    required this.reportId,
    required this.thread,
  });

  factory AdminReportedThread.fromJson(Map<String, dynamic> json) {
    return AdminReportedThread(
      reportId: json['id'].toString(),        // report.id
      thread: Thread.fromJson(json),  
    );
  }
}
