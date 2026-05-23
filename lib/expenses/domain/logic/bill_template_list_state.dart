import 'package:equatable/equatable.dart';

import '../../data/models/bill_template_model.dart';

class BillTemplateListState extends Equatable {
  final bool isLoading;
  final List<BillTemplateModel> templates;
  final String? errorMessage;

  const BillTemplateListState({
    this.isLoading = false,
    this.templates = const [],
    this.errorMessage,
  });

  factory BillTemplateListState.initial() => const BillTemplateListState(isLoading: true);

  BillTemplateListState copyWith({
    bool? isLoading,
    List<BillTemplateModel>? templates,
    String? errorMessage,
    bool resetError = false,
  }) {
    return BillTemplateListState(
      isLoading: isLoading ?? this.isLoading,
      templates: templates ?? this.templates,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, templates, errorMessage];
}
