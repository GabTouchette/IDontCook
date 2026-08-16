// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module_payloads.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HeroSuggestionPayloadImpl _$$HeroSuggestionPayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$HeroSuggestionPayloadImpl(
      recipe: RecipeSummary.fromJson(json['recipe'] as Map<String, dynamic>),
      tagline: json['tagline'] as String? ?? '',
    );

Map<String, dynamic> _$$HeroSuggestionPayloadImplToJson(
        _$HeroSuggestionPayloadImpl instance) =>
    <String, dynamic>{
      'recipe': instance.recipe,
      'tagline': instance.tagline,
    };

_$CookAgainPayloadImpl _$$CookAgainPayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$CookAgainPayloadImpl(
      recipe: RecipeSummary.fromJson(json['recipe'] as Map<String, dynamic>),
      saved_at: json['saved_at'] == null
          ? null
          : DateTime.parse(json['saved_at'] as String),
    );

Map<String, dynamic> _$$CookAgainPayloadImplToJson(
        _$CookAgainPayloadImpl instance) =>
    <String, dynamic>{
      'recipe': instance.recipe,
      'saved_at': instance.saved_at?.toIso8601String(),
    };

_$PostAuthorImpl _$$PostAuthorImplFromJson(Map<String, dynamic> json) =>
    _$PostAuthorImpl(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      avatar_url: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$$PostAuthorImplToJson(_$PostAuthorImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'avatar_url': instance.avatar_url,
    };

_$FriendPostPayloadImpl _$$FriendPostPayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$FriendPostPayloadImpl(
      post_id: (json['post_id'] as num).toInt(),
      author: PostAuthor.fromJson(json['author'] as Map<String, dynamic>),
      recipe: json['recipe'] == null
          ? null
          : RecipeSummary.fromJson(json['recipe'] as Map<String, dynamic>),
      preview_text: json['preview_text'] as String? ?? '',
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$FriendPostPayloadImplToJson(
        _$FriendPostPayloadImpl instance) =>
    <String, dynamic>{
      'post_id': instance.post_id,
      'author': instance.author,
      'recipe': instance.recipe,
      'preview_text': instance.preview_text,
      'created_at': instance.created_at?.toIso8601String(),
    };

_$MealPlanNudgePayloadImpl _$$MealPlanNudgePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$MealPlanNudgePayloadImpl(
      week_start: json['week_start'] as String? ?? '',
      planned_days: (json['planned_days'] as num?)?.toInt() ?? 0,
      cta: json['cta'] as String? ?? '',
    );

Map<String, dynamic> _$$MealPlanNudgePayloadImplToJson(
        _$MealPlanNudgePayloadImpl instance) =>
    <String, dynamic>{
      'week_start': instance.week_start,
      'planned_days': instance.planned_days,
      'cta': instance.cta,
    };

_$GroceryShortcutPayloadImpl _$$GroceryShortcutPayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$GroceryShortcutPayloadImpl(
      item_count: (json['item_count'] as num?)?.toInt() ?? 0,
      cta: json['cta'] as String? ?? '',
    );

Map<String, dynamic> _$$GroceryShortcutPayloadImplToJson(
        _$GroceryShortcutPayloadImpl instance) =>
    <String, dynamic>{
      'item_count': instance.item_count,
      'cta': instance.cta,
    };

_$ChatPromptPayloadImpl _$$ChatPromptPayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatPromptPayloadImpl(
      prompt_text: json['prompt_text'] as String? ?? '',
    );

Map<String, dynamic> _$$ChatPromptPayloadImplToJson(
        _$ChatPromptPayloadImpl instance) =>
    <String, dynamic>{
      'prompt_text': instance.prompt_text,
    };

_$ExploreRailPayloadImpl _$$ExploreRailPayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$ExploreRailPayloadImpl(
      title: json['title'] as String? ?? '',
      recipes: (json['recipes'] as List<dynamic>?)
              ?.map((e) => RecipeSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <RecipeSummary>[],
    );

Map<String, dynamic> _$$ExploreRailPayloadImplToJson(
        _$ExploreRailPayloadImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'recipes': instance.recipes,
    };

_$EventCardPayloadImpl _$$EventCardPayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$EventCardPayloadImpl(
      event_slug: json['event_slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      image_url: json['image_url'] as String?,
      cta: json['cta'] as String?,
      recipes: (json['recipes'] as List<dynamic>?)
              ?.map((e) => RecipeSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <RecipeSummary>[],
    );

Map<String, dynamic> _$$EventCardPayloadImplToJson(
        _$EventCardPayloadImpl instance) =>
    <String, dynamic>{
      'event_slug': instance.event_slug,
      'title': instance.title,
      'body': instance.body,
      'image_url': instance.image_url,
      'cta': instance.cta,
      'recipes': instance.recipes,
    };

_$DealItemImpl _$$DealItemImplFromJson(Map<String, dynamic> json) =>
    _$DealItemImpl(
      name: json['name'] as String? ?? '',
      name_alt: json['name_alt'] as String?,
      brand: json['brand'] as String? ?? '',
      price: json['price'] as String?,
      price_value: json['price_value'] as num?,
      discount: (json['discount'] as num?)?.toInt(),
      image_url: json['image_url'] as String?,
      valid_to: json['valid_to'] as String?,
      merchant: json['merchant'] as String? ?? '',
      distance_m: (json['distance_m'] as num?)?.toInt(),
      savings: json['savings'] as num?,
    );

Map<String, dynamic> _$$DealItemImplToJson(_$DealItemImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'name_alt': instance.name_alt,
      'brand': instance.brand,
      'price': instance.price,
      'price_value': instance.price_value,
      'discount': instance.discount,
      'image_url': instance.image_url,
      'valid_to': instance.valid_to,
      'merchant': instance.merchant,
      'distance_m': instance.distance_m,
      'savings': instance.savings,
    };

_$DealStoreImpl _$$DealStoreImplFromJson(Map<String, dynamic> json) =>
    _$DealStoreImpl(
      merchant: json['merchant'] as String? ?? '',
      merchant_id: (json['merchant_id'] as num?)?.toInt() ?? 0,
      merchant_logo: json['merchant_logo'] as String?,
      distance_m: (json['distance_m'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$DealStoreImplToJson(_$DealStoreImpl instance) =>
    <String, dynamic>{
      'merchant': instance.merchant,
      'merchant_id': instance.merchant_id,
      'merchant_logo': instance.merchant_logo,
      'distance_m': instance.distance_m,
    };

_$DealsRailPayloadImpl _$$DealsRailPayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$DealsRailPayloadImpl(
      state: json['state'] as String? ?? 'ready',
      postal_code: json['postal_code'] as String?,
      stores: (json['stores'] as List<dynamic>?)
              ?.map((e) => DealStore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DealStore>[],
      total_count: (json['total_count'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => DealItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DealItem>[],
    );

Map<String, dynamic> _$$DealsRailPayloadImplToJson(
        _$DealsRailPayloadImpl instance) =>
    <String, dynamic>{
      'state': instance.state,
      'postal_code': instance.postal_code,
      'stores': instance.stores,
      'total_count': instance.total_count,
      'items': instance.items,
    };

_$MoodOptionImpl _$$MoodOptionImplFromJson(Map<String, dynamic> json) =>
    _$MoodOptionImpl(
      mood: json['mood'] as String? ?? '',
      label: json['label'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
    );

Map<String, dynamic> _$$MoodOptionImplToJson(_$MoodOptionImpl instance) =>
    <String, dynamic>{
      'mood': instance.mood,
      'label': instance.label,
      'emoji': instance.emoji,
    };

_$MoodQuestionPayloadImpl _$$MoodQuestionPayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$MoodQuestionPayloadImpl(
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => MoodOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MoodOption>[],
    );

Map<String, dynamic> _$$MoodQuestionPayloadImplToJson(
        _$MoodQuestionPayloadImpl instance) =>
    <String, dynamic>{
      'question': instance.question,
      'options': instance.options,
    };
