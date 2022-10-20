class CardIcons{
  static String? getIcon({required String brand}){
    String? icon_url = null;
    switch (brand.toLowerCase()){
      case 'visa':
        icon_url = 'assets/icons/visa_icon.png';
    }
    return icon_url;
  }
}