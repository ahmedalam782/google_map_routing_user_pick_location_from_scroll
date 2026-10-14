sealed class Result<T> {
  const Result();

  R? fold<R>({
    required R Function(Success<T> success) onSuccess,
    required R Function(Error<T> error) onError,
    R Function(Cancelled<T> cancelled)? onCancelled,
  }) {
    switch (this) {
      case Success<T> success:
        return onSuccess(success);
      case Error<T> error:
        return onError(error);
      case Cancelled<T> cancelled:
        return onCancelled?.call(cancelled);
    }
  }
}

class Success<T> extends Result<T> {
  final T? data;

  const Success({this.data});
}

class Error<T> extends Result<T> {
  final Exception? exception;

  const Error({this.exception});
}

class Cancelled<T> extends Result<T> {
  const Cancelled();
}
