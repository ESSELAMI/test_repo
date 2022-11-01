import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_kom/module_company/models/company_model.dart';
import 'package:my_kom/module_company/models/product_model.dart';
import 'package:my_kom/module_company/response/company_store_detail_response.dart';
import 'package:my_kom/module_home/models/advertisement_model.dart';
import 'package:my_kom/module_persistence/sharedpref/shared_preferences_helper.dart';
import 'package:rxdart/rxdart.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final PublishSubject<Map<String , List<ProductModel>>?> recommendedProductsPublishSubject =
  new PublishSubject();

  final PublishSubject<List<CompanyModel>?> companyStoresPublishSubject =
  new PublishSubject();

  final PublishSubject<List<ProductModel>?> productCompanyStoresPublishSubject =
  new PublishSubject();


  final PublishSubject<List<AdvertisementModel>?> advertisementsCompanyStoresPublishSubject =
  new PublishSubject();

  final SharedPreferencesHelper _preferencesHelper =SharedPreferencesHelper();



 Future<String?> checkStore(String zone)async{
    try {
      String storeId = '';
      /// Get Store From Zone
      ///
      late  QuerySnapshot zone_response;
        zone_response = await _firestore.collection('zones').where('name',arrayContains: zone).get();

     if(zone_response.docs.isNotEmpty){
       Map<String ,dynamic> res =  zone_response.docs[0].data()as Map <String , dynamic> ;
       storeId = res['store_id'];
     }
      /// Default Store
      ///
      if(storeId == ''){
        return null;

      }else{

        /// Save Current Store For Check Address Delivery
        ///
        /// Save Store Information
        ///
         _preferencesHelper.setCurrentSubArea(zone);
       await _getStoreFromZone(storeId);
        return storeId;
      }
    }catch(e){
      return null;
    }
  }

  _getStoreFromZone(String storeId)async{
   await  _firestore.collection('stores').doc(storeId).get().then((value)async {
       Map<String , dynamic> map = value.data() as  Map<String , dynamic>;
       double minimumPurchase =(1.0) * map['minimum_purchase'] ;
       double _fee =(1.0) * map['fee'] ;
        bool vip =  map['vip'];
      await _preferencesHelper.setCurrentStore(storeId);
      await _preferencesHelper.setMinimumPurchaseStore(minimumPurchase);
      await _preferencesHelper.setFeeStore(_fee);
      await _preferencesHelper.setVipStore(vip);
     });
  }

  Future<void> getAllCompanies(String storeId) async {
    try {
      /// store detail
      await _firestore
          .collection('companies').where('store_id',isEqualTo: storeId)
          .snapshots()
          .forEach((element) {
        List<CompanyModel> companyList = [];
        element.docs.forEach((element) {
          Map<String, dynamic> map = element.data() as Map<String, dynamic>;
          map['id'] = element.id;
          CompanyStoreDetailResponse res = CompanyStoreDetailResponse.fromJsom(
              map);

          CompanyModel companyModel = CompanyModel(
              id: res.id, name: res.name, imageUrl: res.imageUrl,description:res.description ,

          );
          companyModel.name2 = res.name2;
          companyModel.isActive = res.isActive;
          companyModel.storeId = res.storeId;
          companyList.add(companyModel);
        });
        companyStoresPublishSubject.add(companyList);
      });
    }catch(e){
      companyStoresPublishSubject.add(null);
    }
  }

  Future<void> getCompanyProducts(String company_id) async {
    try {
      /// store detail
      await _firestore.collection('products').where('company_id',isEqualTo: company_id)
          .snapshots()
          .forEach((element) {
        List<ProductModel> productsList = [];
        element.docs.forEach((element) {

          Map<String, dynamic> map = element.data() as Map<String, dynamic>;
          print(map);
          map['id'] = element.id;
          ProductModel productModel = ProductModel.fromJson(map);
          productsList.add(productModel);
        });

        productCompanyStoresPublishSubject.add(productsList);
      });
    }catch(e){
      productCompanyStoresPublishSubject.add(null);

    }

  }

 Future<void> getRecommendedProducts(String storeId)async {
     try {

       await _firestore
           .collection('companies').where('store_id',isEqualTo: storeId)
           .snapshots()
           .forEach((element) async{
             //List<ProductModel> products=[];
             Map<String , List<ProductModel>> products  = {};
         List<String> companyList = [];
         element.docs.forEach((element) {
           companyList.add(element.id);
         });

             List<List<String>> subList = [];
             for (var i = 0; i < companyList.length; i += 9) {
               subList.add(
                   companyList.sublist(i, i + 9> companyList.length ? companyList.length : i + 9));
             }

             for(int j=0;j<subList.length;j++) {

               /// create listener
               products.addAll({'listener$j':[]});

               _firestore
                   .collection('products').where('company_id' , whereIn:subList[j] ).where('isRecommended',isEqualTo: true).snapshots().forEach((pro) {
                 List<ProductModel> _list = [];
                     pro.docs.forEach((p) {

                   // This condition is for non-repetition of elements
                  // if(!_checkIfExistItemInList(products , p.id))

                     Map<String, dynamic> map = p.data() as Map<String, dynamic>;
                     print(map);
                     map['id'] = p.id;
                     ProductModel productModel = ProductModel.fromJson(map);
                     _list.add(productModel);



                 });

                 /// add products to listener
                 products['listener$j'] = _list;


                 /// calculate products from listeners
                 if(products.isNotEmpty)
                 recommendedProductsPublishSubject.add(products);

                 else if(products.isEmpty && subList.length-1 == j)
                   recommendedProductsPublishSubject.add(products);


              });
             }



       });
     }catch(e){
       print(e.toString());
       recommendedProductsPublishSubject.add(null);

     }
  }


  /// This function is receive list and item and his to check if item exist in the list
  /// return bool (true if is exist)
  bool _checkIfExistItemInList(List<ProductModel> list , String itemId){
    bool result = false;
    list.forEach((element) {
      if(element.id == itemId){
        result = true;
      }
    });

    return result;
  }
  Future<void> getAdvertisements(String? storeId)async {
    try {
      if(storeId ==null ){
        throw Exception();
      }
      await _firestore
          .collection('advertisements').where('storeID',isEqualTo: storeId)
          .snapshots()
          .forEach((element) {
        List<AdvertisementModel> advertisements=[];
        element.docs.forEach((a) {

          Map<String, dynamic> map = a.data() as Map<String, dynamic>;
          print(map);
          map['id'] = a.id;
          AdvertisementModel advertisementModel = AdvertisementModel.fromJson(map);
          advertisements.add(advertisementModel);
        });
        advertisementsCompanyStoresPublishSubject.add(advertisements);
  });
    }catch(e){
      advertisementsCompanyStoresPublishSubject.add(null);
    }
    }

  Future<ProductModel?> getProductDetail(String productId) async{
   try{
     return  await _firestore.collection('products').doc(productId).get().then((value) {
       Map<String, dynamic> map = value.data() as Map<String, dynamic>;
       map['id'] = value.id;
       ProductModel productModel = ProductModel.fromJson(map);
       return productModel;
     });

   }catch(e){
     return null;
   }


  }
  
  
  /// Close Streams 
  void closeStreams(){
    recommendedProductsPublishSubject.close();
    companyStoresPublishSubject.close();
    productCompanyStoresPublishSubject.close();
    advertisementsCompanyStoresPublishSubject.close();
  }




}
