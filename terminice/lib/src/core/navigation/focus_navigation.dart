import 'dart:math';

/// Manages focus navigation with optional per-item error tracking.
///
/// A simpler alternative to [ListNavigation] for cases where all items
/// are visible (no viewport scrolling needed). Commonly used in:
/// - Forms with focusable fields
/// - Multi-step wizards
/// - Survey/questionnaire widgets
/// - Any widget with selectable/focusable items
///
/// **Usage:**
/// ```dart
/// final focus = FocusNavigation(itemCount: fields.length);
///
/// // Navigate with wrapping
/// focus.moveBy(1);   // down/next (wraps at end)
/// focus.moveBy(-1);  // up/previous (wraps at start)
/// focus.jumpTo(3);   // specific index
///
/// // With error tracking
/// focus.setError(2, 'Field is required');
/// if (focus.hasAnyError) {
///   focus.focusFirstError();  // Focus jumps to first invalid item
/// }
///
/// // In render loop
/// for (var i = 0; i < items.length; i++) {
///   final isFocused = focus.isFocused(i);
///   final error = focus.getError(i);
///   // render item with focus indicator and error
/// }
/// ```
///
/// **Key features:**
/// - Wrapping navigation (going up from first goes to last)
/// - Per-item error tracking
/// - Focus-first-error helper for validation flows
/// - Dynamic item count updates
/// - Zero boilerplate in widgets
class FocusNavigation {
  /// Total number of focusable items.
  int _itemCount;

  /// Current focused index.
  int _focusedIndex;

  /// Per-item error messages (null = no error).
  final List<String?> _errors;

  /// Creates a new focus navigation state.
  ///
  /// [itemCount] is the total number of focusable items.
  /// [initialIndex] is the starting focus (defaults to 0).
  FocusNavigation({
    required int itemCount,
    int initialIndex = 0,
  })  : _itemCount = max(0, itemCount),
        _focusedIndex = 0,
        _errors = List<String?>.filled(max(0, itemCount), null, growable: true) {
    _focusedIndex = itemCount > 0 ? initialIndex.clamp(0, itemCount - 1) : 0;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Current focused index.
  int get focusedIndex => _focusedIndex;

  /// Total number of items.
  int get itemCount => _itemCount;

  /// Whether there are no items.
  bool get isEmpty => _itemCount == 0;

  /// Whether there are items.
  bool get isNotEmpty => _itemCount > 0;

  /// Whether the given index is currently focused.
  bool isFocused(int index) => index == _focusedIndex;

  // ──────────────────────────────────────────────────────────────────────────
  // NAVIGATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Moves focus by [delta] positions with wrapping.
  ///
  /// Positive delta moves forward, negative moves backward.
  /// Wraps around at list boundaries.
  void moveBy(int delta) {
    if (_itemCount == 0) return;
    _focusedIndex = (_focusedIndex + delta + _itemCount) % _itemCount;
  }

  /// Moves focus up by one (with wrapping).
  void moveUp() => moveBy(-1);

  /// Moves focus down by one (with wrapping).
  void moveDown() => moveBy(1);

  /// Moves focus to next item (alias for [moveDown]).
  void moveNext() => moveBy(1);

  /// Moves focus to previous item (alias for [moveUp]).
  void movePrevious() => moveBy(-1);

  /// Jumps focus to a specific index (clamped to valid range).
  void jumpTo(int index) {
    if (_itemCount == 0) return;
    _focusedIndex = index.clamp(0, _itemCount - 1);
  }

  /// Jumps focus to the first item.
  void jumpToFirst() => jumpTo(0);

  /// Jumps focus to the last item.
  void jumpToLast() => jumpTo(_itemCount - 1);

  /// Resets focus to initial state (first item, clears all errors).
  void reset({int initialIndex = 0, bool clearErrors = true}) {
    if (_itemCount == 0) {
      _focusedIndex = 0;
    } else {
      _focusedIndex = initialIndex.clamp(0, _itemCount - 1);
    }
    if (clearErrors) clearAllErrors();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ERROR TRACKING
  // ──────────────────────────────────────────────────────────────────────────

  /// Gets the error message for an item (null if no error).
  String? getError(int index) =>
      index >= 0 && index < _errors.length ? _errors[index] : null;

  /// Sets the error message for an item.
  ///
  /// Pass null or empty string to clear the error.
  void setError(int index, String? error) {
    if (index >= 0 && index < _errors.length) {
      _errors[index] = (error?.isEmpty ?? true) ? null : error;
    }
  }

  /// Clears the error for an item.
  void clearError(int index) => setError(index, null);

  /// Clears all errors.
  void clearAllErrors() {
    for (var i = 0; i < _errors.length; i++) {
      _errors[i] = null;
    }
  }

  /// Whether an item has an error.
  bool hasError(int index) {
    final error = getError(index);
    return error != null && error.isNotEmpty;
  }

  /// Whether the focused item has an error.
  bool get focusedHasError => hasError(_focusedIndex);

  /// Error message for the focused item (null if no error).
  String? get focusedError => getError(_focusedIndex);

  /// Whether any item has an error.
  bool get hasAnyError => _errors.any((e) => e != null && e.isNotEmpty);

  /// Whether all items are error-free.
  bool get hasNoErrors => !hasAnyError;

  /// Index of the first item with an error (null if none).
  int? get firstErrorIndex {
    for (var i = 0; i < _errors.length; i++) {
      if (_errors[i] != null && _errors[i]!.isNotEmpty) return i;
    }
    return null;
  }

  /// Number of items with errors.
  int get errorCount => _errors.where((e) => e != null && e.isNotEmpty).length;

  /// Focuses the first item with an error.
  ///
  /// Returns true if an error was found and focus moved, false otherwise.
  bool focusFirstError() {
    final idx = firstErrorIndex;
    if (idx != null) {
      _focusedIndex = idx;
      return true;
    }
    return false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ITEM COUNT UPDATES
  // ──────────────────────────────────────────────────────────────────────────

  /// Updates the total item count (e.g., when list changes).
  ///
  /// Automatically clamps focus to valid range and adjusts error list size.
  set itemCount(int value) {
    final newCount = max(0, value);
    if (newCount == _itemCount) return;

    if (newCount > _itemCount) {
      // Grow: add null errors for new items
      _errors.addAll(List<String?>.filled(newCount - _itemCount, null));
    } else {
      // Shrink: remove trailing errors
      _errors.removeRange(newCount, _itemCount);
    }

    _itemCount = newCount;
    if (_itemCount == 0) {
      _focusedIndex = 0;
    } else {
      _focusedIndex = _focusedIndex.clamp(0, _itemCount - 1);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VALIDATION HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Validates all items using the provided validator function.
  ///
  /// The validator receives the index and should return an error message
  /// (or null/empty for valid). Optionally focuses the first invalid item.
  ///
  /// Returns true if all items are valid, false otherwise.
  ///
  /// **Usage:**
  /// ```dart
  /// final allValid = focus.validateAll(
  ///   (index) {
  ///     final value = values[index].text;
  ///     if (value.isEmpty) return 'Required';
  ///     return null; // valid
  ///   },
  ///   focusFirstInvalid: true,
  /// );
  /// if (allValid) submit();
  /// ```
  bool validateAll(
    String? Function(int index) validator, {
    bool focusFirstInvalid = true,
  }) {
    int? firstInvalid;

    for (var i = 0; i < _itemCount; i++) {
      final error = validator(i);
      setError(i, error);
      if (error != null && error.isNotEmpty && firstInvalid == null) {
        firstInvalid = i;
      }
    }

    if (focusFirstInvalid && firstInvalid != null) {
      _focusedIndex = firstInvalid;
    }

    return firstInvalid == null;
  }

  /// Validates a single item using the provided validator function.
  ///
  /// Returns true if the item is valid, false otherwise.
  bool validateOne(int index, String? Function(int index) validator) {
    final error = validator(index);
    setError(index, error);
    return error == null || error.isEmpty;
  }

  /// Validates the focused item.
  ///
  /// Returns true if the focused item is valid, false otherwise.
  bool validateFocused(String? Function(int index) validator) {
    return validateOne(_focusedIndex, validator);
  }
}

