void main() {
  List<Map<String, dynamic>> shoppingCart = [
    {
      'name': 'Ompreng MBG',
      'price': 125000,
      'quantity': 2,
    },
    {
      'name': 'Kapak Genggam',
      'price': 95000,
      'quantity': 1,
    },
    {
      'name': 'Kelapa Sawit',
      'price': 320000,
      'quantity': 1,
    },
    {
      'name': 'Keadilan Sosial',
      'price': 15000,
      'quantity': 3,
    }
  ];

  print('====================================================');
  print('             STRUK BELANJA / SHOPPING CART          ');
  print('====================================================');

  // 2. LOOP untuk Menampilkan Daftar Produk
  for (var item in shoppingCart) {
    String name = item['name'];
    int price = item['price'];
    int quantity = item['quantity'];
    int itemTotal = price * quantity; 

    print('- $name');
    print('  Harga: Rp $price x $quantity = Rp $itemTotal');
  }

  print('====================================================');

  // 3. FUNCTION untuk Mengolah Perhitungan Subtotal
  double subtotal = calculateSubtotal(shoppingCart);
  
  // 4. FUNCTION & IF/ELSE untuk Menentukan Diskon
  double discountPercentage = determineDiscountPercentage(subtotal);
  double discountAmount = subtotal * discountPercentage; // Operator Perkalian (*)
  
  // 5. Menghitung Total Pembayaran Akhir
  double totalPayment = subtotal - discountAmount;

  print('Subtotal Belanja    : Rp ${subtotal.toStringAsFixed(0)}');
  print('Diskon (${(discountPercentage * 100).toInt()}%)      : Rp ${discountAmount.toStringAsFixed(0)}');
  print('----------------------------------------------------');
  print('TOTAL PEMBAYARAN    : Rp ${totalPayment.toStringAsFixed(0)}');
  print('====================================================');
}

// Fungsi untuk menghitung total harga sebelum diskon (Subtotal)
double calculateSubtotal(List<Map<String, dynamic>> cart) {
  double tempSubtotal = 0;
  
  // Loop untuk mengambil dan menghitung setiap item dalam keranjang
  for (var item in cart) {
    int price = item['price'];
    int quantity = item['quantity'];
    tempSubtotal += (price * quantity); 
  }
  
  return tempSubtotal;
}

// Fungsi dengan IF/ELSE untuk menentukan persentase diskon belanja
// Ketentuan Diskon:
// - Belanja >= Rp 500.000 mendapatkan diskon 15% (0.15)
// - Belanja >= Rp 250.000 mendapatkan diskon 10% (0.10)
// - Belanja >= Rp 100.000 mendapatkan diskon 5% (0.05)
// - Belanja di bawah Rp 100.000 tidak mendapatkan diskon (0.0)
double determineDiscountPercentage(double subtotal) {
  if (subtotal >= 500000) {
    return 0.15; // Diskon 15%
  } else if (subtotal >= 250000) {
    return 0.10; // Diskon 10%
  } else if (subtotal >= 100000) {
    return 0.05; // Diskon 5%
  } else {
    return 0.0;  // Tidak ada diskon
  }
}