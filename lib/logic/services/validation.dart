class Validation {
  /// Class for [Validation] of user input
  /// Ensures each field is not empty and is a number

  /// Mortgage Calculator Validation
  String? validatePurchasePrice(String value) {
    if (value.isEmpty) {
      return 'Purchase Price is required';
    } else if (double.tryParse(value) == null) {
      return 'Purchase Price must be a number';
    }
    return null;
  }

  String? validateInitialDeposit(String value) {
    if (value.isEmpty) {
      return 'Initial Deposit is required';
    } else if (double.tryParse(value) == null) {
      return 'Initial Deposit must be a number';
    }
    return null;
  }

  String? validateInterestRate(String value) {
    if (value.isEmpty) {
      return 'Interest Rate is required';
    } else if (double.tryParse(value) == null) {
      return 'Interest Rate must be a number';
    }
    return null;
  }

  String? validateLoanTerm(String value) {
    if (value.isEmpty) {
      return 'Loan Term is required';
    } else if (double.tryParse(value) == null) {
      return 'Loan Term must be a number';
    }
    return null;
  }

  /// Compound Interest Calculator Validation
  String? validateInitialInvestment(String value) {
    if (value.isEmpty) {
      return 'Initial Investment is required';
    } else if (double.tryParse(value) == null) {
      return 'Initial Investment must be a number';
    }
    return null;
  }

  String? validateRecurringInvestment(String value) {
    if (value.isEmpty) {
      return 'Recurring Investment is required';
    } else if (double.tryParse(value) == null) {
      return 'Recurring Investment must be a number';
    }
    return null;
  }

  String? validateDurationYears(String value) {
    if (value.isEmpty) {
      return 'Duration is required';
    } else if (int.tryParse(value) == null) {
      return 'Duration must be a number';
    }
    return null;
  }

  String? validateAnnualInterestRate(String value) {
    if (value.isEmpty) {
      return 'Annual Interest Rate is required';
    } else if (double.tryParse(value) == null) {
      return 'Annual Interest Rate must be a number';
    }
    return null;
  }
}
