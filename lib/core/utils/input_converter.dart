// lib/core/utils/input_converter.dart

import 'package:dartz/dartz.dart';
import 'package:swap_app/core/error/failurs.dart';

class InputConverter {
  Either<Failure, int> stringToUnsignedInteger(String str) {
    try {
      final integer = int.parse(str);
      if (integer < 0) throw const FormatException();
      return Right(integer);
    } on FormatException {
      return Left(InvalidInputFailure());
    }
  }
}

class InvalidInputFailure extends Failure {
  @override
  // ignore: overridden_fields
  final String message;

  const InvalidInputFailure({
    this.message = 'Invalid input. Please enter a positive integer.',
  }) : super(message: '');
}
