/// Shared collection extensions used across the project.
extension ListX<T> on List<T> {
  /// Maps each element together with its index.
  List<R> mapIndexed<R>(R Function(int index, T item) f) =>
      List.generate(length, (i) => f(i, this[i]));
}
