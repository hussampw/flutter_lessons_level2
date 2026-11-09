// GENERATED CODE - DO NOT MODIFY BY HAND

part of '02_freezed_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
  avatarUrl: json['avatar_url'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
  roles:
      (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'avatar_url': instance.avatarUrl,
  'isVerified': instance.isVerified,
  'roles': instance.roles,
};

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  price: (json['price'] as num).toDouble(),
  rating: (json['rating'] as num?)?.toDouble() ?? 0,
  category: json['category'] as String? ?? '',
  discount: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
  thumbnail: json['thumbnail'] as String?,
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'price': instance.price,
  'rating': instance.rating,
  'category': instance.category,
  'discountPercentage': instance.discount,
  'thumbnail': instance.thumbnail,
};

_ProductsPage _$ProductsPageFromJson(Map<String, dynamic> json) =>
    _ProductsPage(
      products: (json['products'] as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      skip: (json['skip'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$ProductsPageToJson(_ProductsPage instance) =>
    <String, dynamic>{
      'products': instance.products.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'skip': instance.skip,
      'limit': instance.limit,
    };
