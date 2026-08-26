class DiagnosticResponse {
  const DiagnosticResponse(this.values);
  final Map<String, Object?> values;
  Map<String, Object?> toJson() => {'ok': true, ...values};
}
