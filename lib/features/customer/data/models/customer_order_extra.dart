// Model tambahan khusus customer yang tidak ada di staff/data/models/order.dart

class CustomerPrescription {
  final String id;
  final String imageUrl;
  final String? doctorName;
  final String? patientName;
  final String status;
  final String? rejectionNote;

  const CustomerPrescription({
    required this.id,
    required this.imageUrl,
    this.doctorName,
    this.patientName,
    required this.status,
    this.rejectionNote,
  });

  factory CustomerPrescription.fromJson(Map<String, dynamic> json) {
    return CustomerPrescription(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString(),
      patientName: json['patient_name']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      rejectionNote: json['rejection_note']?.toString(),
    );
  }
}
