class ApiResponse {
  final bool success;
  final String? errorCode;
  final String? message;
  final dynamic data;

  ApiResponse({
    required this.success,
    this.errorCode,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      errorCode: json['errorCode'],
      message: json['message'],
      data: json['data'],
    );
  }
}
