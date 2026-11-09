// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '09_pagination.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductsFeed {

 List<Product> get items; int get total; bool get isLoadingMore; AppFailure? get loadMoreError;
/// Create a copy of ProductsFeed
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductsFeedCopyWith<ProductsFeed> get copyWith => _$ProductsFeedCopyWithImpl<ProductsFeed>(this as ProductsFeed, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProductsFeed;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductsFeed&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.isLoadingMore, _this.isLoadingMore) || other.isLoadingMore == _this.isLoadingMore)&&(identical(other.loadMoreError, _this.loadMoreError) || other.loadMoreError == _this.loadMoreError));
}


@override
int get hashCode {
  final _this = this as ProductsFeed;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.total,_this.isLoadingMore,_this.loadMoreError);
}

@override
String toString() {
  final _this = this as ProductsFeed;
  return 'ProductsFeed(items: ${_this.items}, total: ${_this.total}, isLoadingMore: ${_this.isLoadingMore}, loadMoreError: ${_this.loadMoreError})';
}


}

/// @nodoc
abstract mixin class $ProductsFeedCopyWith<$Res>  {
  factory $ProductsFeedCopyWith(ProductsFeed value, $Res Function(ProductsFeed) _then) = _$ProductsFeedCopyWithImpl;
@useResult
$Res call({
 List<Product> items, int total, bool isLoadingMore, AppFailure? loadMoreError
});




}
/// @nodoc
class _$ProductsFeedCopyWithImpl<$Res>
    implements $ProductsFeedCopyWith<$Res> {
  _$ProductsFeedCopyWithImpl(this._self, this._then);

  final ProductsFeed _self;
  final $Res Function(ProductsFeed) _then;

/// Create a copy of ProductsFeed
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? total = null,Object? isLoadingMore = null,Object? loadMoreError = freezed,}) {
  return _then(ProductsFeed(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Product>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductsFeed].
extension ProductsFeedPatterns on ProductsFeed {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductsFeed value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductsFeed() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductsFeed value)  $default,){
final _that = this;
switch (_that) {
case _ProductsFeed():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductsFeed value)?  $default,){
final _that = this;
switch (_that) {
case _ProductsFeed() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Product> items,  int total,  bool isLoadingMore,  AppFailure? loadMoreError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductsFeed() when $default != null:
return $default(_that.items,_that.total,_that.isLoadingMore,_that.loadMoreError);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Product> items,  int total,  bool isLoadingMore,  AppFailure? loadMoreError)  $default,) {final _that = this;
switch (_that) {
case _ProductsFeed():
return $default(_that.items,_that.total,_that.isLoadingMore,_that.loadMoreError);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Product> items,  int total,  bool isLoadingMore,  AppFailure? loadMoreError)?  $default,) {final _that = this;
switch (_that) {
case _ProductsFeed() when $default != null:
return $default(_that.items,_that.total,_that.isLoadingMore,_that.loadMoreError);case _:
  return null;

}
}

}

/// @nodoc


class _ProductsFeed extends ProductsFeed {
  const _ProductsFeed({ List<Product> items = const <Product>[], this.total = 0, this.isLoadingMore = false, this.loadMoreError}): _items = items,super._();
  

 final  List<Product> _items;
@override@JsonKey() List<Product> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  int total;
@override@JsonKey() final  bool isLoadingMore;
@override final  AppFailure? loadMoreError;

/// Create a copy of ProductsFeed
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductsFeedCopyWith<_ProductsFeed> get copyWith => __$ProductsFeedCopyWithImpl<_ProductsFeed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductsFeed&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.total, total) || other.total == total)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.loadMoreError, loadMoreError) || other.loadMoreError == loadMoreError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),total,isLoadingMore,loadMoreError);
}

@override
String toString() {
    return 'ProductsFeed(items: $items, total: $total, isLoadingMore: $isLoadingMore, loadMoreError: $loadMoreError)';
}


}

/// @nodoc
abstract mixin class _$ProductsFeedCopyWith<$Res> implements $ProductsFeedCopyWith<$Res> {
  factory _$ProductsFeedCopyWith(_ProductsFeed value, $Res Function(_ProductsFeed) _then) = __$ProductsFeedCopyWithImpl;
@override @useResult
$Res call({
 List<Product> items, int total, bool isLoadingMore, AppFailure? loadMoreError
});




}
/// @nodoc
class __$ProductsFeedCopyWithImpl<$Res>
    implements _$ProductsFeedCopyWith<$Res> {
  __$ProductsFeedCopyWithImpl(this._self, this._then);

  final _ProductsFeed _self;
  final $Res Function(_ProductsFeed) _then;

/// Create a copy of ProductsFeed
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? total = null,Object? isLoadingMore = null,Object? loadMoreError = freezed,}) {
  return _then(_ProductsFeed(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Product>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError // ignore: cast_nullable_to_non_nullable
as AppFailure?,
  ));
}


}

// dart format on
