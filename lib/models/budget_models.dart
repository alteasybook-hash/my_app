import 'package:flutter/material.dart';

class DepartmentBudget {
  String id;
  String name;
  double percentage; 
  double spent;
  Color color;
  double? customForecast; // Prévision manuelle par service

  DepartmentBudget({
    required this.id,
    required this.name,
    required this.percentage,
    this.spent = 0.0,
    this.color = Colors.blue,
    this.customForecast,
  });

  double getAllocatedAmount(double totalBudget) => totalBudget * (percentage / 100);
  double getRemaining(double totalBudget) => getAllocatedAmount(totalBudget) - spent;
  
  double getForecast(int daysInMonth, int daysElapsed) {
    if (customForecast != null) return customForecast!;
    if (daysElapsed == 0) return 0;
    return (spent / daysElapsed) * daysInMonth;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'percentage': percentage,
    'spent': spent,
    'color': color.value,
    'customForecast': customForecast,
  };

  factory DepartmentBudget.fromJson(Map<String, dynamic> json) => DepartmentBudget(
    id: json['id'],
    name: json['name'],
    percentage: json['percentage'].toDouble(),
    spent: json['spent'].toDouble(),
    color: Color(json['color']),
    customForecast: json['customForecast']?.toDouble(),
  );
}

class MonthlyExpense {
  final String month;
  final double amount;

  MonthlyExpense({required this.month, required this.amount});

  Map<String, dynamic> toJson() => {'month': month, 'amount': amount};
  factory MonthlyExpense.fromJson(Map<String, dynamic> json) => MonthlyExpense(
    month: json['month'],
    amount: json['amount'].toDouble(),
  );
}

class EntityBudget {
  final String entityId;
  double totalBudget;
  List<DepartmentBudget> departments;
  List<MonthlyExpense> monthlyExpenses;
  double? customGlobalForecast; // Surcharge manuelle de la provision totale

  EntityBudget({
    required this.entityId,
    required this.totalBudget,
    required this.departments,
    required this.monthlyExpenses,
    this.customGlobalForecast,
  });

  double getTotalSpent() => departments.fold(0, (sum, dept) => sum + dept.spent);
  double getTotalRemaining() => totalBudget - getTotalSpent();
  double getConsumptionPercentage() => totalBudget > 0 ? (getTotalSpent() / totalBudget) : 0;
  double getTotalPercentage() => departments.fold(0, (sum, dept) => sum + dept.percentage);

  Map<String, dynamic> toJson() => {
    'entityId': entityId,
    'totalBudget': totalBudget,
    'departments': departments.map((d) => d.toJson()).toList(),
    'monthlyExpenses': monthlyExpenses.map((m) => m.toJson()).toList(),
    'customGlobalForecast': customGlobalForecast,
  };

  factory EntityBudget.fromJson(Map<String, dynamic> json) => EntityBudget(
    entityId: json['entityId'],
    totalBudget: json['totalBudget'].toDouble(),
    departments: (json['departments'] as List).map((d) => DepartmentBudget.fromJson(d)).toList(),
    monthlyExpenses: (json['monthlyExpenses'] as List).map((m) => MonthlyExpense.fromJson(m)).toList(),
    customGlobalForecast: json['customGlobalForecast']?.toDouble(),
  );
}
