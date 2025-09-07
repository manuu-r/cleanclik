import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Waste disposal categories with their visual properties
enum WasteCategory {
  recycle('recycle', 'EcoGems', Color(0xFF4CAF50)),
  organic('organic', 'BioShards', Color(0xFF8BC34A)),
  ewaste('ewaste', 'TechCores', Color(0xFFFF9800)),
  hazardous('hazardous', 'ToxicVials', Color(0xFFE91E63));

  const WasteCategory(this.id, this.codeName, this.color);

  final String id;
  final String codeName;
  final Color color;

  /// Get category from ML Kit label with simplified mapping for FASHION_GOOD, HOME_GOOD, FOOD, PLANT
  /// Ignores PLACE objects and unknown categories completely
  static WasteCategory? fromMLKitLabel(String label, double confidence) {
    print('🗂️ [WASTE_CATEGORY] ===== PROCESSING ML KIT LABEL =====');
    print('🗂️ [WASTE_CATEGORY] Input Label: "$label"');
    print('🗂️ [WASTE_CATEGORY] Input Confidence: ${(confidence * 100).toStringAsFixed(2)}%');
    
    if (confidence < 0.3) {
      print('🗂️ [WASTE_CATEGORY] ❌ REJECTED: Confidence below 30% threshold');
      _logDetection(label, confidence, null, 'Below confidence threshold');
      return null;
    }

    // Check if this is a PLACE object or other ignored category
    if (_isIgnoredCategory(label)) {
      print('🗂️ [WASTE_CATEGORY] ❌ IGNORED: Category "$label" is not a waste item');
      _logDetection(label, confidence, null, 'Ignored category (PLACE or non-waste)');
      return null;
    }

    print('🗂️ [WASTE_CATEGORY] ✅ Confidence acceptable, proceeding with categorization...');
    final result = _categorizeWithSimplifiedMapping(label, confidence);
    
    if (result != null) {
      print('🗂️ [WASTE_CATEGORY] ✅ CATEGORIZATION SUCCESS:');
      print('🗂️ [WASTE_CATEGORY]   Category: ${result.category.id}');
      print('🗂️ [WASTE_CATEGORY]   Matched Keyword: "${result.matchedKeyword}"');
      print('🗂️ [WASTE_CATEGORY]   Match Type: ${result.matchType}');
      print('🗂️ [WASTE_CATEGORY]   Final Confidence: ${(result.confidence * 100).toStringAsFixed(2)}%');
    } else {
      print('🗂️ [WASTE_CATEGORY] ❌ CATEGORIZATION FAILED: Unknown ML Kit category');
      _logDetection(label, confidence, null, 'Unknown ML Kit category - skipped');
      return null;
    }
    
    _logDetection(label, confidence, result?.category, result?.matchedKeyword ?? 'No match');
    print('🗂️ [WASTE_CATEGORY] ===== END LABEL PROCESSING =====');
    
    return result?.category;
  }

  /// Process multiple labels and detect objects with multiple categories (FASHION_GOOD + HOME_GOOD = ewaste)
  static WasteCategory? fromMultipleLabels(List<Map<String, dynamic>> labels) {
    if (labels.isEmpty) return null;

    final validLabels = labels.where((label) => 
        label['confidence'] != null && 
        label['text'] != null && 
        label['confidence'] >= 0.3).toList();
    if (validLabels.isEmpty) return null;

    // Check for multiple category detection (FASHION_GOOD + HOME_GOOD = ewaste)
    final labelTexts = validLabels.map((label) => label['text'].toString().toUpperCase()).toSet();
    if (labelTexts.contains('FASHION_GOOD') && labelTexts.contains('HOME_GOOD')) {
      print('🗂️ [WASTE_CATEGORY] ✅ MULTI-CATEGORY DETECTION: FASHION_GOOD + HOME_GOOD → ewaste');
      _logDetection('FASHION_GOOD + HOME_GOOD', 0.9, WasteCategory.ewaste, 'Multi-category detection');
      return WasteCategory.ewaste;
    }

    // Sort by confidence and try each label
    validLabels.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    
    for (final label in validLabels) {
      final result = fromMLKitLabel(label['text'], label['confidence']);
      if (result != null) {
        _logDetection(label['text'], label['confidence'], result, 
                     'Multi-label match');
        return result;
      }
    }

    // No valid category found
    print('🗂️ [WASTE_CATEGORY] ❌ No valid categories found in multi-label detection');
    return null;
  }

  /// Check if a category should be ignored (PLACE objects only)
  static bool _isIgnoredCategory(String label) {
    final normalizedLabel = label.toUpperCase();
    
    // Ignore PLACE objects as they are not waste items
    if (normalizedLabel == 'PLACE') {
      return true;
    }
    
    // Don't ignore other categories - let them be processed by the categorization system
    return false;
  }

  /// Simplified categorization mapping for ML Kit categories
  static _CategoryMatch? _categorizeWithSimplifiedMapping(String label, double confidence) {
    final normalizedLabel = label.toUpperCase();
    
    // Direct ML Kit category mapping
    switch (normalizedLabel) {
      case 'FASHION_GOOD':
        return _CategoryMatch(
          category: WasteCategory.recycle,
          confidence: confidence * 0.95,
          matchedKeyword: 'FASHION_GOOD',
          matchType: _MatchType.exact,
        );
      case 'HOME_GOOD':
        return _CategoryMatch(
          category: WasteCategory.recycle,
          confidence: confidence * 0.95,
          matchedKeyword: 'HOME_GOOD',
          matchType: _MatchType.exact,
        );
      case 'FOOD':
        return _CategoryMatch(
          category: WasteCategory.organic,
          confidence: confidence * 0.95,
          matchedKeyword: 'FOOD',
          matchType: _MatchType.exact,
        );
      case 'PLANT':
        return _CategoryMatch(
          category: WasteCategory.organic,
          confidence: confidence * 0.95,
          matchedKeyword: 'PLANT',
          matchType: _MatchType.exact,
        );
      default:
        // Fall back to the enhanced categorization for backward compatibility
        return _categorizeWithPriority(label, confidence);
    }
  }

  /// Enhanced categorization with priority system and fuzzy matching
  static _CategoryMatch? _categorizeWithPriority(String label, double confidence) {
    final normalizedLabel = _preprocessLabel(label);
    
    // Handle compound labels with special logic first
    if (normalizedLabel.contains(' ')) {
      // For hazardous compound labels, prioritize hazardous (highest priority)
      if (normalizedLabel.contains('hazardous') || normalizedLabel.contains('chemical') || normalizedLabel.contains('toxic')) {
        final hazardousKeywords = _categoryKeywords[WasteCategory.hazardous] ?? [];
        final hazardousMatch = _findBestKeywordMatch(normalizedLabel, hazardousKeywords, WasteCategory.hazardous, confidence);
        if (hazardousMatch != null) {
          return hazardousMatch;
        }
      }
      
      // For organic waste compound labels, prioritize organic if it's explicitly mentioned
      if (normalizedLabel.contains('organic') || normalizedLabel.contains('food waste') || normalizedLabel.contains('compost')) {
        final organicKeywords = _categoryKeywords[WasteCategory.organic] ?? [];
        final organicMatch = _findBestKeywordMatch(normalizedLabel, organicKeywords, WasteCategory.organic, confidence);
        if (organicMatch != null) {
          return organicMatch;
        }
      }
      
      // For electronic device compound labels, prioritize the electronic aspect
      if (normalizedLabel.contains('electronic') || normalizedLabel.contains('device')) {
        final ewasteKeywords = _categoryKeywords[WasteCategory.ewaste] ?? [];
        final ewasteMatch = _findBestKeywordMatch(normalizedLabel, ewasteKeywords, WasteCategory.ewaste, confidence);
        if (ewasteMatch != null) {
          return ewasteMatch;
        }
      }
      
      // For container-related compound labels, prioritize the container aspect (but not if hazardous/organic/electronic is mentioned)
      if ((normalizedLabel.contains('container') || normalizedLabel.contains('bottle') || normalizedLabel.contains('jar')) 
          && !normalizedLabel.contains('hazardous') && !normalizedLabel.contains('chemical') 
          && !normalizedLabel.contains('organic') && !normalizedLabel.contains('food waste')
          && !normalizedLabel.contains('electronic')) {
        // Check if it's a recyclable container first
        final recycleKeywords = _categoryKeywords[WasteCategory.recycle] ?? [];
        final recycleMatch = _findBestKeywordMatch(normalizedLabel, recycleKeywords, WasteCategory.recycle, confidence);
        if (recycleMatch != null) {
          return recycleMatch;
        }
      }
    }
    
    // Check direct mappings for exact matches only (not substring)
    for (final entry in _directMappings.entries) {
      if (normalizedLabel == entry.key) {
        return _CategoryMatch(
          category: entry.value,
          confidence: confidence * 0.95, // High confidence for direct matches
          matchedKeyword: entry.key,
          matchType: _MatchType.exact,
        );
      }
    }

    // Check category keywords with priority weighting
    final matches = <_CategoryMatch>[];
    
    for (final category in _categoryPriority) {
      final keywords = _categoryKeywords[category] ?? [];
      final match = _findBestKeywordMatch(normalizedLabel, keywords, category, confidence);
      if (match != null) {
        matches.add(match);
      }
    }

    if (matches.isEmpty) {
      // No matches found - return null instead of defaulting to landfill
      return null;
    }

    // Return highest priority match (first in _categoryPriority list)
    matches.sort((a, b) {
      final priorityA = _categoryPriority.indexOf(a.category);
      final priorityB = _categoryPriority.indexOf(b.category);
      if (priorityA != priorityB) return priorityA.compareTo(priorityB);
      return b.confidence.compareTo(a.confidence); // Then by confidence
    });

    return matches.first;
  }

  /// Find the best keyword match for a category
  static _CategoryMatch? _findBestKeywordMatch(
    String label, 
    List<String> keywords, 
    WasteCategory category, 
    double confidence
  ) {
    // Exact matches first (highest priority)
    for (final keyword in keywords) {
      if (label == keyword) {
        return _CategoryMatch(
          category: category,
          confidence: confidence * 0.95,
          matchedKeyword: keyword,
          matchType: _MatchType.exact,
        );
      }
    }

    // Direct substring matches (high priority)
    for (final keyword in keywords) {
      if (label.contains(keyword) && keyword.length >= 3) {
        return _CategoryMatch(
          category: category,
          confidence: confidence * 0.85,
          matchedKeyword: keyword,
          matchType: _MatchType.fuzzy,
        );
      }
    }

    // Compound label processing - check if any word in the label matches exactly
    final labelParts = label.split(' ');
    if (labelParts.length > 1) {
      for (final part in labelParts) {
        if (part.length >= 3) { // Only check meaningful parts
          for (final keyword in keywords) {
            if (part == keyword || (keyword.contains(part) && part.length >= 4)) {
              return _CategoryMatch(
                category: category,
                confidence: confidence * 0.75,
                matchedKeyword: keyword,
                matchType: _MatchType.compound,
              );
            }
          }
        }
      }
    }

    // More conservative fuzzy matching (lowest priority)
    for (final keyword in keywords) {
      if (keyword.length >= 4 && _conservativeFuzzyMatch(label, keyword)) {
        return _CategoryMatch(
          category: category,
          confidence: confidence * 0.6,
          matchedKeyword: keyword,
          matchType: _MatchType.fuzzy,
        );
      }
    }

    return null;
  }

  /// Conservative fuzzy matching for label variations (only for very similar words)
  static bool _conservativeFuzzyMatch(String label, String keyword) {
    // Only match if words are very similar (for typos)
    if (label.length < 4 || keyword.length < 4) return false;
    if ((label.length - keyword.length).abs() > 2) return false; // Length difference too big
    
    // Check for common typos and variations
    final commonVariations = {
      'aluminium': 'aluminum',
      'bottel': 'bottle',
      'mobil': 'mobile',
    };
    
    if (commonVariations[label] == keyword || commonVariations[keyword] == label) {
      return true;
    }
    
    // Avoid false matches like "grass" -> "glass"
    final problematicPairs = {
      'grass': ['glass'],
      'glass': ['grass'],
    };
    
    if (problematicPairs[label]?.contains(keyword) == true) {
      return false;
    }
    
    // Check character similarity for very close matches only
    int matches = 0;
    final minLength = label.length < keyword.length ? label.length : keyword.length;
    
    for (int i = 0; i < minLength; i++) {
      if (i < label.length && i < keyword.length && label[i] == keyword[i]) {
        matches++;
      }
    }
    
    // Require 85% character match for fuzzy matching (more strict)
    return matches >= (minLength * 0.85);
  }

  /// Preprocess label for better matching
  static String _preprocessLabel(String label) {
    return label
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Log detection results for debugging and improvement
  static void _logDetection(String label, double confidence, WasteCategory? result, String details) {
    if (kDebugMode) {
      final categoryName = result?.id ?? 'null';
      debugPrint('🗂️ [WasteCategory] "$label" (${(confidence * 100).toStringAsFixed(1)}%) → $categoryName ($details)');
    }
  }

  // Category priority system (hazardous > ewaste > recycle > organic)
  static const List<WasteCategory> _categoryPriority = [
    WasteCategory.hazardous,
    WasteCategory.ewaste,
    WasteCategory.recycle,
    WasteCategory.organic,
  ];

  // Direct label mappings for high-confidence matches
  static const Map<String, WasteCategory> _directMappings = {
    // Recyclable items - direct mappings
    'bottle': WasteCategory.recycle,
    'plastic bottle': WasteCategory.recycle,
    'water bottle': WasteCategory.recycle,
    'soda bottle': WasteCategory.recycle,
    'can': WasteCategory.recycle,
    'aluminum can': WasteCategory.recycle,
    'soda can': WasteCategory.recycle,
    'beer can': WasteCategory.recycle,
    'cardboard': WasteCategory.recycle,
    'cardboard box': WasteCategory.recycle,
    'paper': WasteCategory.recycle,
    'newspaper': WasteCategory.recycle,
    'glass': WasteCategory.recycle,
    'glass bottle': WasteCategory.recycle,

    // Organic waste - direct mappings
    'food': WasteCategory.organic,
    'fruit': WasteCategory.organic,
    'apple': WasteCategory.organic,
    'banana': WasteCategory.organic,
    'orange': WasteCategory.organic,
    'vegetable': WasteCategory.organic,
    'bread': WasteCategory.organic,
    'sandwich': WasteCategory.organic,
    'pizza': WasteCategory.organic,

    // Electronic waste - direct mappings
    'phone': WasteCategory.ewaste,
    'smartphone': WasteCategory.ewaste,
    'computer': WasteCategory.ewaste,
    'laptop': WasteCategory.ewaste,
    'tablet': WasteCategory.ewaste,
    'camera': WasteCategory.ewaste,
    'television': WasteCategory.ewaste,
    'tv': WasteCategory.ewaste,

    // Hazardous waste - direct mappings
    'battery': WasteCategory.hazardous,
    'car battery': WasteCategory.hazardous,
    'lithium battery': WasteCategory.hazardous,
    'paint': WasteCategory.hazardous,
    'chemical': WasteCategory.hazardous,
    'medicine': WasteCategory.hazardous,
    'motor oil': WasteCategory.hazardous,
  };

  // Comprehensive keyword mappings for each category
  static const Map<WasteCategory, List<String>> _categoryKeywords = {
    WasteCategory.recycle: [
      // Plastic containers and bottles
      'bottle', 'plastic bottle', 'water bottle', 'soda bottle', 'beverage bottle',
      'sports bottle', 'squeeze bottle', 'shampoo bottle', 'detergent bottle',
      'container', 'plastic container', 'food container', 'storage container',
      'tupperware', 'lunch box', 'bento box', 'meal prep container',
      'cup', 'plastic cup', 'disposable cup', 'coffee cup', 'drinking cup',
      'jar', 'plastic jar', 'glass jar', 'mason jar', 'pickle jar', 'jam jar',

      // Cans and metal items
      'can', 'aluminum can', 'soda can', 'beer can', 'tin can', 'metal can',
      'energy drink can', 'soup can', 'cat food can', 'dog food can',
      'tin', 'aluminum', 'metal', 'steel', 'iron', 'copper',
      'foil', 'aluminum foil', 'tin foil', 'metal sheet',
      'lid', 'cap', 'metal lid', 'bottle cap', 'can lid',

      // Paper products and cardboard
      'paper', 'newspaper', 'magazine', 'book', 'notebook', 'journal',
      'cardboard', 'box', 'shipping box', 'amazon box', 'delivery box',
      'carton', 'milk carton', 'juice carton', 'cereal box', 'pizza box',
      'egg carton', 'shoe box', 'gift box', 'moving box',
      'envelope', 'letter', 'document', 'receipt', 'invoice', 'bill',
      'flyer', 'brochure', 'catalog', 'manual', 'instruction',
      'tissue box', 'paper bag', 'shopping bag', 'lunch bag',

      // Glass items
      'glass', 'glass bottle', 'wine bottle', 'beer bottle', 'liquor bottle',
      'glass container', 'glass jar', 'drinking glass', 'wine glass',
      'beer glass', 'tumbler', 'mug', 'glass mug',

      // Textiles and fashion
      'clothing', 'shirt', 't-shirt', 'polo shirt', 'dress shirt', 'blouse',
      'pants', 'jeans', 'trousers', 'shorts', 'skirt', 'dress',
      'jacket', 'coat', 'hoodie', 'sweater', 'cardigan', 'blazer',
      'shoe', 'sneaker', 'boot', 'sandal', 'flip-flop', 'heel', 'loafer',
      'bag', 'handbag', 'backpack', 'purse', 'tote bag', 'messenger bag',
      'hat', 'cap', 'baseball cap', 'beanie', 'scarf', 'tie', 'belt',
    ],

    WasteCategory.organic: [
      // Fruits (fresh and processed)
      'fruit', 'apple', 'banana', 'orange', 'grape', 'strawberry',
      'pear', 'peach', 'plum', 'cherry', 'berry', 'blueberry', 'raspberry',
      'melon', 'watermelon', 'cantaloupe', 'honeydew',
      'pineapple', 'mango', 'kiwi', 'papaya', 'avocado',
      'lemon', 'lime', 'grapefruit', 'coconut', 'date', 'fig',
      'fruit peel', 'banana peel', 'orange peel', 'apple core',

      // Vegetables (fresh and cooked)
      'vegetable', 'carrot', 'potato', 'sweet potato', 'yam',
      'tomato', 'onion', 'garlic', 'ginger', 'pepper', 'bell pepper',
      'broccoli', 'cauliflower', 'lettuce', 'spinach', 'kale', 'arugula',
      'cucumber', 'zucchini', 'squash', 'pumpkin', 'eggplant',
      'corn', 'corn cob', 'corn husk', 'cabbage', 'brussels sprouts',
      'celery', 'radish', 'beet', 'turnip', 'parsnip',
      'mushroom', 'asparagus', 'artichoke', 'leek', 'scallion',

      // Prepared foods and leftovers
      'food', 'leftover', 'meal', 'dinner', 'lunch', 'breakfast',
      'bread', 'toast', 'bagel', 'muffin', 'croissant', 'roll',
      'sandwich', 'burger', 'hot dog', 'wrap', 'burrito', 'taco',
      'pizza', 'pizza crust', 'pasta', 'noodle', 'spaghetti', 'rice',
      'salad', 'soup', 'stew', 'curry', 'casserole',

      // Proteins
      'meat', 'chicken', 'turkey', 'duck', 'beef', 'pork', 'lamb',
      'fish', 'salmon', 'tuna', 'shrimp', 'crab', 'lobster', 'seafood',
      'egg', 'eggshell', 'omelet', 'scrambled egg',

      // Dairy and alternatives
      'cheese', 'milk', 'yogurt', 'butter', 'cream', 'sour cream',
      'ice cream', 'frozen yogurt', 'cottage cheese',

      // Baked goods and sweets
      'cake', 'cupcake', 'cookie', 'brownie', 'pastry', 'pie',
      'donut', 'danish', 'scone', 'biscuit', 'cracker',
      'chocolate', 'candy', 'gummy', 'marshmallow',

      // Plant matter and yard waste
      'plant', 'leaf', 'leaves', 'flower', 'petal', 'stem',
      'grass', 'grass clipping', 'weed', 'moss', 'algae',
      'wood', 'stick', 'branch', 'twig', 'bark', 'sawdust',
      'pine cone', 'acorn', 'nut shell', 'seed', 'pit',
      'organic', 'compost', 'biodegradable', 'natural',
    ],

    WasteCategory.ewaste: [
      // Mobile devices and accessories
      'phone', 'smartphone', 'mobile phone', 'cell phone', 'iphone', 'android',
      'samsung phone', 'google phone', 'pixel phone', 'galaxy phone',
      'tablet', 'ipad', 'android tablet', 'surface tablet',
      'kindle', 'e-reader', 'nook', 'kobo',
      'phone case', 'screen protector', 'phone charger', 'phone cable',
      'earphone', 'earbud', 'airpods', 'bluetooth earphone',

      // Computers and peripherals
      'computer', 'laptop', 'laptop notebook', 'macbook', 'chromebook',
      'desktop', 'pc', 'tower', 'cpu', 'computer case',
      'monitor', 'screen', 'display', 'lcd monitor', 'led monitor',
      'keyboard', 'wireless keyboard', 'mechanical keyboard',
      'mouse', 'wireless mouse', 'gaming mouse', 'trackpad',
      'webcam', 'web camera', 'usb camera',
      'printer', 'inkjet printer', 'laser printer', '3d printer',
      'scanner', 'copier', 'fax machine', 'all-in-one printer',

      // Audio/Video equipment
      'headphone', 'headset', 'gaming headset', 'noise canceling headphone',
      'speaker', 'bluetooth speaker', 'portable speaker', 'soundbar',
      'microphone', 'usb microphone', 'wireless microphone',
      'camera', 'digital camera', 'dslr camera', 'mirrorless camera',
      'video camera', 'camcorder', 'action camera', 'gopro',
      'lens', 'camera lens', 'telephoto lens', 'wide angle lens',
      'television', 'tv', 'smart tv', 'led tv', 'oled tv', 'plasma tv',
      'radio', 'fm radio', 'am radio', 'internet radio',
      'stereo', 'boom box', 'cd player', 'mp3 player', 'ipod',

      // Gaming and entertainment devices
      'game console', 'playstation', 'xbox', 'nintendo switch', 'wii',
      'controller', 'game controller', 'joystick', 'gamepad',
      'gaming device', 'handheld console', 'psp', 'nintendo ds',
      'cd', 'dvd', 'blu-ray', 'disc', 'game disc', 'software disc',
      'vr headset', 'oculus', 'virtual reality', 'ar glasses',

      // Electronic components and accessories
      'rechargeable battery', 'aa battery', 'aaa battery',
      'charger', 'phone charger', 'laptop charger', 'wireless charger',
      'cable', 'usb cable', 'hdmi cable', 'ethernet cable', 'power cable',
      'wire', 'extension cord', 'power strip', 'surge protector',
      'adapter', 'power adapter', 'usb adapter', 'hdmi adapter',
      'circuit board', 'motherboard', 'graphics card', 'ram',
      'chip', 'processor', 'cpu', 'gpu', 'microchip',
      'memory card', 'sd card', 'micro sd', 'cf card',
      'usb drive', 'flash drive', 'thumb drive', 'memory stick',
      'hard drive', 'hdd', 'ssd', 'external drive', 'backup drive',

      // Small appliances and gadgets
      'electronic', 'device', 'gadget', 'appliance', 'smart device',
      'clock', 'digital clock', 'alarm clock', 'smart clock',
      'watch', 'smartwatch', 'fitness tracker', 'apple watch',
      'calculator', 'scientific calculator', 'graphing calculator',
      'remote control', 'tv remote', 'universal remote',
      'router', 'modem', 'wifi router', 'network device',
      'smart home device', 'alexa', 'google home', 'smart speaker',
      'drone', 'quadcopter', 'rc helicopter', 'remote control car',
    ],

    WasteCategory.hazardous: [
      // Chemicals and paints
      'chemical', 'paint', 'solvent', 'adhesive', 'glue',
      'bleach', 'detergent', 'cleaner', 'disinfectant',
      'pesticide', 'insecticide', 'herbicide', 'fertilizer',

      // Batteries and power sources (hazardous types)
      'car battery', 'lead acid battery', 'lithium ion battery',
      'nickel cadmium battery', 'mercury battery',

      // Medical and pharmaceutical
      'medicine', 'medication', 'pill', 'syringe', 'needle',
      'thermometer', 'medical device', 'pharmaceutical',

      // Automotive fluids
      'motor oil', 'engine oil', 'antifreeze', 'brake fluid',
      'transmission fluid', 'gasoline', 'diesel',

      // Other hazardous items
      'toxic', 'hazard', 'dangerous', 'flammable', 'corrosive',
      'aerosol', 'spray can', 'propane', 'lighter fluid',
      'fluorescent bulb', 'cfl bulb', 'mercury bulb',
    ],


  };

  /// Get all categories as a list
  static List<WasteCategory> get all => WasteCategory.values;

  /// Get category by ID
  static WasteCategory? fromId(String id) {
    try {
      return WasteCategory.values.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get category by codeName (EcoGems, BioShards, etc.)
  static WasteCategory? fromCodeName(String codeName) {
    try {
      return WasteCategory.values.firstWhere((category) => category.codeName == codeName);
    } catch (e) {
      return null;
    }
  }

  /// Get category by either ID or codeName (flexible parsing)
  static WasteCategory? fromString(String value) {
    // Try ID first (recycle, organic, etc.)
    final byId = fromId(value);
    if (byId != null) return byId;
    
    // Try codeName (EcoGems, BioShards, etc.)
    final byCodeName = fromCodeName(value);
    if (byCodeName != null) return byCodeName;
    
    return null;
  }

  /// Calculate category confidence based on keyword match strength
  static double calculateCategoryConfidence(String label, WasteCategory category) {
    final keywords = _categoryKeywords[category] ?? [];
    final normalizedLabel = _preprocessLabel(label);
    
    // Check for exact matches
    for (final keyword in keywords) {
      if (normalizedLabel == keyword) return 0.95;
      if (normalizedLabel.contains(keyword)) return 0.85;
    }
    
    // Check direct mappings
    if (_directMappings.containsKey(normalizedLabel) && 
        _directMappings[normalizedLabel] == category) {
      return 0.90;
    }
    
    return 0.0;
  }

  /// Find the best category match for a given label
  static WasteCategory? findBestCategoryMatch(String label) {
    final result = _categorizeWithPriority(label, 1.0);
    return result?.category;
  }

  /// Check if a label matches keywords for a category using fuzzy matching
  static bool matchesKeywords(String label, List<String> keywords) {
    final normalizedLabel = _preprocessLabel(label);
    
    for (final keyword in keywords) {
      if (normalizedLabel.contains(keyword) || _conservativeFuzzyMatch(normalizedLabel, keyword)) {
        return true;
      }
    }
    
    return false;
  }

  /// Preprocess a label into component parts for better matching
  static List<String> preprocessLabel(String label) {
    final normalized = _preprocessLabel(label);
    final parts = normalized.split(' ');
    
    // Include the full label and individual parts
    final result = <String>[normalized];
    result.addAll(parts.where((part) => part.length > 2));
    
    return result;
  }
}

/// Internal class for category matching results
class _CategoryMatch {
  final WasteCategory category;
  final double confidence;
  final String matchedKeyword;
  final _MatchType matchType;

  const _CategoryMatch({
    required this.category,
    required this.confidence,
    required this.matchedKeyword,
    required this.matchType,
  });
}

/// Types of keyword matches
enum _MatchType {
  exact,      // Direct keyword match
  fuzzy,      // Substring or fuzzy match
  compound,   // Multi-word match
  fallback    // Default categorization
}