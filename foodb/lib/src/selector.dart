//for _index and _find func
import 'package:collection/collection.dart';
import 'package:foodb/src/exception.dart';

abstract class Operator {
  late String operator;
  bool evaluate(Map<String, dynamic> values);
  Map<String, dynamic> toJson();
  List<String> keys();
}

abstract class ConditionOperator extends Operator {
  dynamic expected;
  String key;
  String operator;

  ConditionOperator(
      {required this.key, required this.expected, required this.operator});

  dynamic getValue(Map<String, dynamic> values) {
    List<String> keys = key.split(".");
    dynamic value = values;
    try {
      for (String key in keys) {
        value = value[key];
      }
      return value;
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      key: {operator: expected}
    };
  }

  @override
  List<String> keys() {
    return [key];
  }
}

class EqualOperator extends ConditionOperator {
  EqualOperator({required String key, required dynamic expected})
      : super(expected: expected, key: key, operator: "\$eq");

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);
    try {
      if (value is List || value is Map) {
        return DeepCollectionEquality().equals(value, expected);
      }
      return value == expected;
    } catch (e) {
      return false;
    }
  }
}

class NotEqualOperator extends ConditionOperator {
  NotEqualOperator({required String key, required dynamic expected})
      : super(expected: expected, key: key, operator: "\$ne");

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);
    try {
      if (value is List || value is Map) {
        return !DeepCollectionEquality().equals(value, expected);
      }
      return value != expected;
    } catch (e) {
      return true;
    }
  }
}

class GreaterThanOperator extends ConditionOperator {
  GreaterThanOperator({required String key, required dynamic expected})
      : super(key: key, operator: "\$gt", expected: expected);

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);

    if (value is String && expected is String) {
      return value.compareTo(expected) > 0;
    } else if (value is num && expected is num) {
      return value.compareTo(expected) > 0;
    } else if (value is String && expected is num) {
      return true;
    } else if (value is num && expected is String) {
      return false;
    }
    return false;
  }
}

class GreaterThanOrEqualOperator extends ConditionOperator {
  GreaterThanOrEqualOperator({required String key, required dynamic expected})
      : super(key: key, operator: "\$gte", expected: expected);

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);

    if (value is String && expected is String) {
      return value.compareTo(expected) >= 0;
    } else if (value is num && expected is num) {
      return value.compareTo(expected) >= 0;
    } else if (value is String && expected is num) {
      return true;
    } else if (value is num && expected is String) {
      return false;
    }
    return false;
  }
}

class LessThanOperator extends ConditionOperator {
  LessThanOperator({required String key, required dynamic expected})
      : super(expected: expected, key: key, operator: "\$lt");

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);
    if (value is String && expected is String) {
      return value.compareTo(expected) < 0;
    } else if (value is num && expected is num) {
      return value.compareTo(expected) < 0;
    } else if (value is String && expected is num) {
      return false;
    } else if (value is num && expected is String) {
      return true;
    }
    return false;
  }
}

class LessThanOrEqualOperator extends ConditionOperator {
  LessThanOrEqualOperator({required String key, required dynamic expected})
      : super(key: key, operator: "\$lte", expected: expected);

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);

    if (value is String && expected is String) {
      return value.compareTo(expected) <= 0;
    } else if (value is num && expected is num) {
      return value.compareTo(expected) <= 0;
    } else if (value is String && expected is num) {
      return false;
    } else if (value is num && expected is String) {
      return true;
    }
    return false;
  }
}

class ExistsOperator extends ConditionOperator {
  ExistsOperator({required String key, required dynamic expected})
      : super(expected: expected, key: key, operator: "\$exists");

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);
    if (expected is bool) {
      return (value != null) == expected;
    }
    throw AdapterException(
        error: "bad_arg",
        reason: "Bad argument for operator \$exists: $expected");
  }
}

class TypeOperator extends ConditionOperator {
  TypeOperator({required String key, required dynamic expected})
      : super(expected: expected, key: key, operator: "\$type");

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);
    if (value is String) {
      return expected == "string";
    } else if (value is num) {
      return expected == "number";
    } else if (value is bool) {
      return expected == "boolean";
    } else if (value is List) {
      return expected == "array";
    } else if (value is Map) {
      return expected == "object";
    } else if (value == null) {
      return expected == "null";
    }
    return false;
  }
}

class InOperator extends ConditionOperator {
  InOperator({required String key, required dynamic expected})
      : super(expected: expected, key: key, operator: "\$in");

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);
    if (expected is List) {
      if (value is Map || value is List) {
        for (var object in expected) {
          if (DeepCollectionEquality().equals(object, value)) {
            return true;
          }
        }
        return false;
      }
      return expected.contains(value);
    }
    throw AdapterException(
        error: "bad_arg", reason: "Bad argument for operator \$in: $expected");
  }
}

class NotInOperator extends ConditionOperator {
  NotInOperator({required String key, required dynamic expected})
      : super(key: key, expected: expected, operator: "\$nin");

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);
    if (expected is List) {
      if (value is Map || value is List) {
        for (var object in expected) {
          if (DeepCollectionEquality().equals(object, value)) {
            return false;
          }
        }
        return true;
      }
      return !expected.contains(value);
    }
    throw AdapterException(
        error: "bad_arg", reason: "Bad argument for operator \$nin: $expected");
  }
}

class SizeOperator extends ConditionOperator {
  SizeOperator({required String key, required dynamic expected})
      : super(expected: expected, key: key, operator: "\$size");

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);
    if (expected is int) {
      if (value is List) {
        return value.length == expected;
      }
      return false;
    }
    throw AdapterException(
        error: "bad_arg",
        reason: "Bad argument for operator \$size: $expected");
  }
}

class ModOperator extends ConditionOperator {
  ModOperator({required String key, required dynamic expected})
      : super(expected: expected, key: key, operator: "\$mod");

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);
    if (expected is List<int> && expected.length == 2) {
      if (value is int) {
        return value % expected[0] == expected[1];
      }
      return false;
    }
    throw AdapterException(
        error: "bad_arg", reason: "Bad argument for operator \$mod: $expected");
  }
}

class RegexOperator extends ConditionOperator {
  RegexOperator({required String key, dynamic expected})
      : super(expected: expected, key: key, operator: "\$regex");

  @override
  bool evaluate(Map<String, dynamic> values) {
    final value = getValue(values);

    if (expected is String) {
      if (value is String) {
        return RegExp(expected).hasMatch(value);
      }
      return false;
    }
    throw AdapterException(
        error: "invalid_operator", reason: "Invalid operator: \$regex");
  }
}

abstract class CombinationOperator extends Operator {
  List<Operator> operators = [];
  String operator = "";
  CombinationOperator({required this.operator, required this.operators});

  bool combine(bool a, bool b);

  @override
  List<String> keys() {
    List<String> list = [];
    operators.forEach((o) {
      list.addAll(o.keys());
    });
    return list;
  }

  @override
  bool evaluate(Map<String, dynamic> value) {
    var result = true;
    operators.forEach((o) {
      // if (o is ConditionOperator) {
      //   result = combine(result, o.evaluate(value[o.key]));
      // } else {
      result = combine(result, o.evaluate(value));
      // }
    });
    return result;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      operator: operators.map<Map<String, dynamic>>((e) => e.toJson()).toList()
    };
  }
}

class AndOperator extends CombinationOperator {
  AndOperator({List<Operator>? operators})
      : super(operator: "\$and", operators: operators ?? []);

  @override
  bool combine(bool a, bool b) {
    return a && b;
  }
}

class OrOperator extends CombinationOperator {
  OrOperator({List<Operator>? operators})
      : super(operator: "\$or", operators: operators ?? []);
  @override
  bool combine(bool a, bool b) {
    return a || b;
  }
}

Operator? getOperator(keyword, {key, expected}) {
  switch (keyword) {
    case "\$or":
      return OrOperator();
    case "\$and":
      return AndOperator();
    case "\$eq":
      return EqualOperator(key: key, expected: expected);
    case "\$ne":
      return NotEqualOperator(key: key, expected: expected);
    case "\$gt":
      return GreaterThanOperator(key: key, expected: expected);
    case "\$gte":
      return GreaterThanOrEqualOperator(key: key, expected: expected);
    case "\$lt":
      return LessThanOperator(key: key, expected: expected);
    case "\$lte":
      return LessThanOrEqualOperator(key: key, expected: expected);
    case "\$exists":
      return ExistsOperator(key: key, expected: expected);
    case "\$type":
      return TypeOperator(key: key, expected: expected);
    case "\$in":
      return InOperator(key: key, expected: expected);
    case "\$nin":
      return NotInOperator(key: key, expected: expected);
    case "\$size":
      return SizeOperator(key: key, expected: expected);
    case "\$mod":
      return ModOperator(key: key, expected: expected);
    case "\$regex":
      return RegexOperator(key: key, expected: expected);
    default:
      return null;
  }
}

class SelectorBuilder {
  var value;
  SelectorBuilder();

  Operator fromJson(Map<String, dynamic> json) {
    List<Operator> subList = [];
    json.entries.forEach((element) {
      subList.add(DFS(json: Map.fromEntries([element])));
    });
    if (subList.length > 1) {
      this.value = AndOperator(operators: subList);
    } else {
      this.value = subList.first;
    }

    return this.value;
  }

  Operator DFS({String? key, required Map<String, dynamic> json}) {
    for (MapEntry<String, dynamic> entry in json.entries) {
      final operator = getOperator(entry.key);
      if (operator is CombinationOperator) {
        List<Operator> subList = [];
        entry.value.forEach((e) {
          subList.add(DFS(key: key, json: e));
        });
        operator.operators = subList;
        return operator;
      } else if (operator == null) {
        List<Operator> subList = [];
        entry.value.forEach((operatorStr, arg) {
          final subOperator =
              getOperator(operatorStr, key: entry.key, expected: arg);
          if (subOperator is ConditionOperator) {
            subList.add(subOperator);
          } else if (subOperator is CombinationOperator) {
            subList.add(DFS(key: entry.key, json: {operatorStr: arg}));
          } else if (subOperator == null) {
            if (arg is Map<String, dynamic>) {
              subList.add(_nestedOperator(
                  "${key != null ? "$key." : ""}${entry.key}.${operatorStr}",
                  arg));
            } else {
              throw AdapterException(error: 'Invalid Selector Format');
            }
          }
        });
        if (subList.length > 1) {
          return AndOperator(operators: subList);
        } else {
          return subList.first;
        }
      } else {
        throw AdapterException(error: "Invalid Format of Selector");
      }
    }

    return this.value;
  }

  _nestedOperator(String nestedKey, Map<String, dynamic> value) {
    List<Operator> operators = [];
    value.forEach((key, value) {
      final operator = getOperator(key, key: nestedKey, expected: value);
      if (operator is Operator) {
        operators.add(DFS(json: {
          nestedKey: {key: value}
        }));
      } else {
        operators.add(_nestedOperator("$nestedKey.$key", value));
      }
    });

    if (operators.length > 1) {
      return AndOperator(operators: operators);
    }
    return operators.first;
  }
}
