



















































































      DocumentSnapshot sellerSnapshot = await _firestore
          .collection('sellers')
          .doc(userId)
          .get();

     


      } else if (sellerSnapshot.exists) {
        Map<String, dynamic> sellerData =
            sellerSnapshot.data() as Map<String, dynamic>;
       






        
        } else {
          await _saveCredentials();
          _navigateTo(const SellerHomePage());
        } 
     