// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Extension methods on common collection types.

import "dart:collection";
import "dart:math";

import "algorithms.dart";
import "algorithms.dart" as algorithms show shuffle; // Shadowed by declaration.
import "equality.dart";

extension ListExtensions<E> on List<E> {
  /// Takes an action for each element.
  ///
  /// Calls [action] for each element along with the index in the
  /// iteration order.
  void forEachIndexed(void action(int index, E element)) {
    for (var index = 0; index < length; index++) {
      action(index, this[index]);
    }
  }

  /// Maps each element and its index to a new value.
  Iterable<R> mapIndexed<R>(R convert(int index, E element)) sync* {
    for (var index = 0; index < length; index++) {
      yield convert(index, this[index]);
    }
  }

  /// Filters the elements on their value and index.
  Iterable<E> whereIndexed(bool test(int index, E element)) sync* {
    for (var index = 0; index < length; index++) {
      var element = this[index];
      if (test(index, element)) yield element;
    }
  }

  /// Expands each element and index to a number of elements in a new iterable.
  Iterable<R> expandIndexed<R>(Iterable<R> expend(int index, E element)) sync* {
    var index = 0;
    for (var element in this) {
      yield* expend(index++, element);
    }
  }


  /// Sort a range of elements by [compare].
  void sortRange(int start, int end, int compare(E a, E b)) {
    quickSort<E>(this, compare, start, end);
  }

  /// Sorts elements by the [compare] of their [keyOf] property.
  ///
  /// Sorts elements from [start] to [end], defaulting to the entire list.
  void sortBy<K>(K keyOf(E element), int compare(K a, K b),
      [int start = 0, int end]) {
    quickSortBy(this, keyOf, compare, start, end);
  }

  /// Shuffle a range of elements.
  void shuffleRange(int start, int end, [Random random]) {
    RangeError.checkValidRange(start, end, length);
    shuffle(this, start, end, random);
  }

  /// Reverses the elements in a range of the list.
  void reverseRange(int start, int end) {
    RangeError.checkValidRange(start, end, length);
    while (start < --end) {
      var tmp = this[start];
      this[start] = this[end];
      this[end] = tmp;
      start += 1;
    }
  }

  /// Swaps two elements of this list.
  void swap(int index1, int index2) {
    RangeError.checkValidIndex(index1, this, "index1");
    RangeError.checkValidIndex(index2, this, "index2");
    var tmp = this[index1];
    this[index1] = this[index2];
    this[index2] = tmp;
  }

  /// A fixed length view of a range of this list.
  ///
  /// The view is backed by this this list, which must not
  /// change its length while the view is being used.
  ///
  /// The view can be used to perform specific whole-list
  /// actions on a part of the list.
  /// For example, to see if a list contains more than one
  /// "marker" element, you can do:
  /// ```dart
  /// someList.slice(someList.indexOf(marker) + 1).contains(marker)
  /// ```
  ListSlice<E> slice(int start, [int /*?*/ end]) {
    end = RangeError.checkValidRange(start, end, length);
    var self = this;
    if (self is ListSlice) return self.slice(start, end);
    return ListSlice<E>(this, start, end);
  }

  /// Whether [other] has the same elements as this list.
  ///
  /// Returns true iff [other] has the same [length]
  /// as this list, and the elemets of this list and [other]
  /// at the same indices are equal (according to `==`).
  bool equals(List<E> other, [Equality<E> equality = const DefaultEquality()]) {
    if (length != other.length) return false;
    for (var i = 0; i < length; i++) {
      if (!equality.equals(this[i], other[i])) return false;
    }
    return true;
  }
}

extension ComparableListExtensions<E extends Comparable<E>> on List<E> {
  void sortRange(int start, int end, [int compare(E a, E b)]) {
    RangeError.checkValidRange(start, end, length);
    compare ??= (E a, E b) => a.compareTo(b);
    quickSort(this, compare, start, end);
  }
}

/// A list view of a range of another list.
///
/// Wraps the range of the [source] list from [start] to [end]
/// and acts like a fixed-length list view of that range.
/// The source list must not change length while a list slice is being used.
class ListSlice<E> extends ListBase<E> {
  /// Original length of [source].
  ///
  /// Used to detect modifications to [source] which may invalidate
  /// the slice.
  final int _initialSize;

  /// The original list backing this slice.
  final List<E> source;

  /// The start index of the slice.
  final int start;
  final int length;

  /// Creates a slice of [source] from [start] to [end].
  ListSlice(this.source, this.start, int end)
      : length = end - start,
        _initialSize = source.length {
    RangeError.checkValidRange(start, end, source.length);
  }

  ListSlice._(this._initialSize, this.source, this.start, this.length);

  /// The end index of the slice.
  int get end => start + length;

  E operator [](int index) {
    if (source.length != _initialSize) {
      throw ConcurrentModificationError(source);
    }
    RangeError.checkValidIndex(index, this, null, length);
    return source[start + index];
  }

  void operator []=(int index, E value) {
    if (source.length != _initialSize) {
      throw ConcurrentModificationError(source);
    }
    RangeError.checkValidIndex(index, this, null, length);
    source[start + index] = value;
  }

  void setRange(int start, int end, Iterable<E> source, [int from = 0]) {
    if (source.length != _initialSize) {
      throw ConcurrentModificationError(source);
    }
    RangeError.checkValidRange(start, end, length);
    this.source.setRange(start + start, start + end, source, from);
  }

  ListSlice<E> slice(int start, [int end]) {
    end = RangeError.checkValidRange(start, end, length);
    return ListSlice._(_initialSize, source, start + start, end - start);
  }

  void shuffle([Random random]) {
    if (source.length != _initialSize) {
      throw ConcurrentModificationError(source);
    }
    algorithms.shuffle(source, start, end, random);
  }

  void sort([int compare(E a, E b)]) {
    if (source.length != _initialSize) {
      throw ConcurrentModificationError(source);
    }
    quickSort(source, compare, start, start + length);
  }

  /// Sort a range of elements by [compare].
  void sortRange(int start, int end, int compare(E a, E b)) {
    if (source.length != _initialSize) {
      throw ConcurrentModificationError(source);
    }
    source.sortRange(start, end, compare);
  }

  /// Shuffles a range of elements.
  ///
  /// If [random] is omitted, a new instance of [Random] is used.
  void shuffleRange(int start, int end, [Random random]) {
    if (source.length != _initialSize) {
      throw ConcurrentModificationError(source);
    }
    RangeError.checkValidRange(start, end, length);
    algorithms.shuffle(source, this.start + start, this.start + end, random);
  }

  /// Reverses a range of elements.
  void reverseRange(int start, int end) {
    RangeError.checkValidRange(start, end, length);
    source.reverseRange(this.start + start, this.start + end);
  }

  // Act like a fixed-length list.

  set length(int newLength) {
    throw UnsupportedError("Cannot change the length of a fixed-length list");
  }

  void add(E value) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void insert(int index, E value) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void insertAll(int at, Iterable<E> iterable) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void addAll(Iterable<E> iterable) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  bool remove(Object element) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(E element)) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(E element)) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void clear() {
    throw UnsupportedError("Cannot clear a fixed-length list");
  }

  E removeAt(int index) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  E removeLast() {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeRange(int start, int end) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void replaceRange(int start, int end, Iterable<E> iterable) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }
}
