class FoodImageProvider {
  // Returns Unsplash image URL for recipes
  static String getRecipeImage(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.contains('menemen')) {
      return 'https://images.unsplash.com/photo-1590412200988-a436bb705300?w=600&auto=format&fit=crop&q=80';
    }
    if (lower.contains('krep') || lower.contains('akıtma')) {
      return 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600&auto=format&fit=crop&q=80';
    }
    if (lower.contains('kuymak') || lower.contains('mıhlama')) {
      return 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=600&auto=format&fit=crop&q=80';
    }
    if (lower.contains('mercimek çorbası')) {
      return 'https://images.unsplash.com/photo-1547592165-e1d17fed6006?w=600&auto=format&fit=crop&q=80';
    }
    if (lower.contains('mevsim salatası')) {
      return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&auto=format&fit=crop&q=80';
    }
    if (lower.contains('karnıyarık')) {
      return 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600&auto=format&fit=crop&q=80';
    }
    if (lower.contains('tavuk sote')) {
      return 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=600&auto=format&fit=crop&q=80';
    }
    if (lower.contains('pirinç pilavı')) {
      return 'https://images.unsplash.com/photo-1536304997881-a372c179924b?w=600&auto=format&fit=crop&q=80';
    }
    if (lower.contains('makarna')) {
      return 'https://images.unsplash.com/photo-1546549032-9571cd6b27df?w=600&auto=format&fit=crop&q=80';
    }
    
    // Default fallback food image
    return 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600&auto=format&fit=crop&q=80';
  }

  // Returns Unsplash image URL for ingredients
  static String getIngredientImage(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.contains('kıyma')) {
      return 'https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('yumurta')) {
      return 'https://images.unsplash.com/photo-1506976785307-8732e854ad03?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('domates')) {
      return 'https://images.unsplash.com/photo-1595855759920-86582396756a?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('yeşil biber') || lower.contains('biber')) {
      return 'https://images.unsplash.com/photo-1589135287754-058df8a21ad6?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('soğan')) {
      return 'https://images.unsplash.com/photo-1618519764620-7403abdbfda9?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('sarımsak')) {
      return 'https://images.unsplash.com/photo-1540148426945-6cf22a6b2383?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('patlıcan')) {
      return 'https://images.unsplash.com/photo-1528137871318-0fcc2559f24c?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('tavuk')) {
      return 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('pirinç')) {
      return 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('makarna')) {
      return 'https://images.unsplash.com/photo-1621961404018-8199342ec4ca?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('tereyağı')) {
      return 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('zeytinyağı') || lower.contains('yağ')) {
      return 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('salça')) {
      return 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('un')) {
      return 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('süt')) {
      return 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('mercimek')) {
      return 'https://images.unsplash.com/photo-1515942622995-2d77a1ae030d?w=200&auto=format&fit=crop&q=80';
    }
    
    // Default fallback ingredient image (raw spices/herbs)
    return 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=200&auto=format&fit=crop&q=80';
  }
}
