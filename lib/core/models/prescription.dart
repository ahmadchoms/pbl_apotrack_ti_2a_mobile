import 'package:mobile/core/network/api_client.dart';

class CustomerPrescription {
  final String id;
  final String imageUrl;
  final String? doctorName;
  final String? patientName;
  final String? issuedDate;
  final String status;
  final String? rejectionNote;

  const CustomerPrescription({
    required this.id,
    required this.imageUrl,
    this.doctorName,
    this.patientName,
    this.issuedDate,
    required this.status,
    this.rejectionNote,
  });

  factory CustomerPrescription.fromJson(Map<String, dynamic> json) {
    return CustomerPrescription(
      id: json['id']?.toString() ?? '',
      imageUrl: resolveImageUrl(json['image_url']?.toString()),
      doctorName: json['doctor_name']?.toString(),
      patientName: json['patient_name']?.toString(),
      issuedDate: json['issued_date']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      rejectionNote: json['rejection_note']?.toString(),
    );
  }
}
