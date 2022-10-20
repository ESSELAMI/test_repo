

class CardModel{
  String cardId;
 String cardNumber;
 final String type;
 CardModel({required this.cardId , required this.cardNumber,required this.type});

 @override
  String toString() {
    String _card = cardId+'|my_kom|'+cardNumber+'|my_kom|'+type;
    return _card;
  }


 static CardModel fromString(String card){
  List<String>? split = card.split('|my_kom|');
    return CardModel(cardId: split[0], cardNumber: split[1],type: split[2]);
  }
}